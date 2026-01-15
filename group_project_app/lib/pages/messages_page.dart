import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  bool _editMode = false;

  String? _deletingPeerUid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _chatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  Future<void> _deleteMessagesOnly(String myUid, String peerUid) async {
    final chatId = _chatIdFor(myUid, peerUid);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    while (true) {
      final snap = await chatRef.collection('messages').limit(300).get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _showEditActionsSheet({
    required String myUid,
    required String peerUid,
  }) async {
    if (_deletingPeerUid != null) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1B2238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Delete messages',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'messages'),
                ),

                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white70),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Messages will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingPeerUid = peerUid);
    try {
      if (choice == 'messages') {
        await _deleteMessagesOnly(myUid, peerUid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
      }
    } finally {
      if (mounted) setState(() => _deletingPeerUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B0E1A),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(
              _editMode ? 'Done' : 'Edit',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1B2238),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(myUid)
                  .collection('inbox')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Inbox cant be read:\n${snap.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? const [];

                if (docs.isEmpty) {
                  return _FriendsFallbackList(
                    myUid: myUid,
                    queryLower: _q,
                    editMode: _editMode,
                    deletingPeerUid: _deletingPeerUid,
                    onEditAction: (peerUid) =>
                        _showEditActionsSheet(myUid: myUid, peerUid: peerUid),
                  );
                }

                final filtered = docs.where((d) {
                  final data = d.data();
                  final name = (data['peerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  if (_q.isEmpty) return true;
                  return name.contains(_q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data();

                    final peerUid = (data['peerUid'] ?? doc.id).toString();
                    final peerName = (data['peerName'] ?? peerUid).toString();
                    final lastText = (data['lastText'] ?? 'Tap to chat')
                        .toString();

                    final isDeleting = _deletingPeerUid == peerUid;

                    return ListTile(
                      textColor: Colors.white,
                      title: Text(
                        peerName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        lastText,
                        style: const TextStyle(color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _editMode
                          ? IconButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => _showEditActionsSheet(
                                      myUid: myUid,
                                      peerUid: peerUid,
                                    ),
                              icon: isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                      onTap: () {
                        if (_editMode) {
                          _showEditActionsSheet(myUid: myUid, peerUid: peerUid);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(friendUid: peerUid),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsFallbackList extends StatelessWidget {
  final String myUid;
  final String queryLower;
  final bool editMode;
  final String? deletingPeerUid;
  final void Function(String peerUid) onEditAction;

  const _FriendsFallbackList({
    required this.myUid,
    required this.queryLower,
    required this.editMode,
    required this.deletingPeerUid,
    required this.onEditAction,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Friends cannot be read:\n${snap.error}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        final data = snap.data?.data() ?? {};
        final friends =
            (data['friends'] as List?)?.cast<String>() ?? const <String>[];

        if (friends.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, i) {
            final friendUid = friends[i];
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendUid)
                  .snapshots(),
              builder: (context, us) {
                final u = us.data?.data() ?? {};
                final name = (u['name'] ?? friendUid).toString();

                if (queryLower.isNotEmpty &&
                    !name.toLowerCase().contains(queryLower)) {
                  return const SizedBox.shrink();
                }

                final isDeleting = deletingPeerUid == friendUid;

                return ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tap to chat',
                    style: TextStyle(color: Colors.white54),
                  ),
                  trailing: editMode
                      ? IconButton(
                          onPressed: isDeleting
                              ? null
                              : () => onEditAction(friendUid),
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete, color: Colors.white),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () {
                    if (editMode) {
                      onEditAction(friendUid);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(friendUid: friendUid),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
