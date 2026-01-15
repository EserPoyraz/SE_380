import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String friendUid;
  const ChatPage({super.key, required this.friendUid});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  String? _friendName;

  // build stable chat id
  String _chatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  // init state setup
  @override
  void initState() {
    super.initState();
    _loadFriendName();
  }

  // fetch friend name once
  Future<void> _loadFriendName() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendUid)
          .get();
      final data = snap.data();
      final name = (data?['name'] ?? '').toString().trim();
      if (mounted) {
        setState(() => _friendName = name.isNotEmpty ? name : widget.friendUid);
      }
    } catch (_) {
      if (mounted) setState(() => _friendName = widget.friendUid);
    }
  }

  // dispose controllers safely
  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  // fetch user display name
  Future<String> _getUserName(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data();
    final name = (data?['name'] ?? '').toString().trim();
    return name.isNotEmpty ? name : uid;
  }

  // send message and update inbox
  Future<void> _send() async {
    if (_sending) return;

    final me = FirebaseAuth.instance.currentUser!.uid;
    final other = widget.friendUid;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    final db = FirebaseFirestore.instance;
    final chatId = _chatIdFor(me, other);
    final chatRef = db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    try {
      final myName = await _getUserName(me);
      final otherName = _friendName ?? await _getUserName(other);

      await chatRef.set({
        'participants': [me, other],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await msgRef.set({
        'senderId': me,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final now = FieldValue.serverTimestamp();

      await db.collection('users').doc(me).collection('inbox').doc(other).set({
        'peerUid': other,
        'peerName': otherName,
        'lastText': text,
        'updatedAt': now,
        'chatId': chatId,
      }, SetOptions(merge: true));

      await db.collection('users').doc(other).collection('inbox').doc(me).set({
        'peerUid': me,
        'peerName': myName,
        'lastText': text,
        'updatedAt': now,
        'chatId': chatId,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // chat ui and stream
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _chatIdFor(me, widget.friendUid);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        title: Text(
          _friendName ?? widget.friendUid,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B0E1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatRef
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final senderId = (m['senderId'] ?? '').toString();
                    final text = (m['text'] ?? '').toString();
                    final isMe = senderId == me;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : const Color(0xFF1B2238),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1B2238),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
