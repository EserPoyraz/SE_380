import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final userDocStream =
        FirebaseFirestore.instance.collection('users').doc(me.uid).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E1A),
        title: const Text("Friends"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _AddFriendSheet(),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text("Error loading friends",
                  style: TextStyle(color: Colors.white)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() ?? {};
          final friends = (data['friends'] as List?)?.cast<String>() ?? [];
          final incoming =
              (data['incomingRequests'] as List?)?.cast<String>() ?? [];

          if (friends.isEmpty && incoming.isEmpty) {
            return Center(
              child: Text(
                "No friends yet.\nTap + to add.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (incoming.isNotEmpty) ...[
                Text(
                  "Friend Requests",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _RequestsList(incomingUids: incoming),
                const SizedBox(height: 18),
              ],
              Text(
                "Friends",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (friends.isEmpty)
                Text(
                  "No friends yet.",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                )
              else
                _FriendsList(friendUids: friends),
            ],
          );
        },
      ),
    );
  }
}

// ===================== REQUESTS LIST =====================

class _RequestsList extends StatefulWidget {
  const _RequestsList({required this.incomingUids});
  final List<String> incomingUids;

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  Future<void> _accept(String fromUid) async {
    // ✅ messenger'ı async öncesi yakala (context defunct hatasını keser)
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      await me.getIdToken(true);

      final db = FirebaseFirestore.instance;
      final myRef = db.collection('users').doc(me.uid);
      final fromRef = db.collection('users').doc(fromUid);

      final batch = db.batch();

      batch.update(myRef, {
        'incomingRequests': FieldValue.arrayRemove([fromUid]),
        'friends': FieldValue.arrayUnion([fromUid]),
      });

      batch.update(fromRef, {
        'outgoingRequests': FieldValue.arrayRemove([me.uid]),
        'friends': FieldValue.arrayUnion([me.uid]),
      });

      await batch.commit();

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text("Request accepted")),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text("Accept failed: $e")),
      );
    }
  }

  Future<void> _decline(String fromUid) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      await me.getIdToken(true);

      final db = FirebaseFirestore.instance;
      final myRef = db.collection('users').doc(me.uid);
      final fromRef = db.collection('users').doc(fromUid);

      final batch = db.batch();
      batch.update(myRef, {
        'incomingRequests': FieldValue.arrayRemove([fromUid]),
      });
      batch.update(fromRef, {
        'outgoingRequests': FieldValue.arrayRemove([me.uid]),
      });

      await batch.commit();

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text("Request declined")),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text("Decline failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.incomingUids.length > 10
        ? widget.incomingUids.take(10).toList()
        : widget.incomingUids;

    final q = FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text(
            "Error loading requests",
            style: TextStyle(color: Colors.white),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] as String?) ?? "User";
            final photoUrl = (data['photoUrl'] as String?) ?? "";

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: _UserInfoCard(
                name: name,
                photoUrl: photoUrl,
                // ✅ request ekranında info yok
                showStats: false,
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _decline(doc.id),
                          child: const Text(
                            "Decline",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _accept(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Accept"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ===================== FRIENDS LIST =====================

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.friendUids});
  final List<String> friendUids;

  Future<void> _removeFriend(BuildContext context, String targetUid) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      await me.getIdToken(true);

      final db = FirebaseFirestore.instance;
      final myRef = db.collection('users').doc(me.uid);
      final targetRef = db.collection('users').doc(targetUid);

      final batch = db.batch();
      batch.update(myRef, {'friends': FieldValue.arrayRemove([targetUid])});
      batch.update(targetRef, {'friends': FieldValue.arrayRemove([me.uid])});
      await batch.commit();

      messenger?.showSnackBar(
        const SnackBar(content: Text("Friend removed")),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text("Remove failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids =
        friendUids.length > 10 ? friendUids.take(10).toList() : friendUids;

    final q = FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text("Error loading friends",
              style: TextStyle(color: Colors.white));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        return Column(
          children: docs.map((doc) {
            final d = doc.data();
            final name = (d['name'] as String?) ?? "User";
            final photoUrl = (d['photoUrl'] as String?) ?? "";

            final programTitle = _readProgramTitle(d);
            final sets = (d['sets'] as num?)?.toInt() ?? 0;
            final waterMl = (d['water'] as num?)?.toInt() ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: _UserInfoCard(
                name: name,
                photoUrl: photoUrl,
                showStats: true,
                programTitle: programTitle,
                sets: sets,
                waterMl: waterMl,
                trailing: TextButton(
                  onPressed: () => _removeFriend(context, doc.id),
                  child: const Text(
                    "Remove",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static String _readProgramTitle(Map<String, dynamic> userData) {
    final cp = userData['currentProgram'];
    if (cp is Map) {
      final t = cp['title'];
      if (t is String && t.trim().isNotEmpty) return t.trim();
    }
    return "No active program";
  }
}

// ===================== ADD FRIEND SHEET =====================

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _controller = TextEditingController();
  String _q = "";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest(String targetUid) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      await me.getIdToken(true);

      final db = FirebaseFirestore.instance;
      final myRef = db.collection('users').doc(me.uid);
      final targetRef = db.collection('users').doc(targetUid);

      final batch = db.batch();
      batch.update(myRef, {
        'outgoingRequests': FieldValue.arrayUnion([targetUid]),
      });
      batch.update(targetRef, {
        'incomingRequests': FieldValue.arrayUnion([me.uid]),
      });

      await batch.commit();

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text("Request sent")),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text("Request failed: $e")),
      );
    }
  }

  Future<void> _cancelFriendRequest(String targetUid) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      await me.getIdToken(true);

      final db = FirebaseFirestore.instance;
      final myRef = db.collection('users').doc(me.uid);
      final targetRef = db.collection('users').doc(targetUid);

      final batch = db.batch();
      batch.update(myRef, {
        'outgoingRequests': FieldValue.arrayRemove([targetUid]),
      });
      batch.update(targetRef, {
        'incomingRequests': FieldValue.arrayRemove([me.uid]),
      });

      await batch.commit();

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text("Request cancelled")),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text("Cancel failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final myDocStream =
        FirebaseFirestore.instance.collection('users').doc(me.uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: myDocStream,
      builder: (context, mySnap) {
        if (mySnap.hasError) {
          return const Center(
            child: Text("Error loading profile",
                style: TextStyle(color: Colors.white)),
          );
        }
        if (!mySnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final myData = mySnap.data!.data() ?? {};
        final myFriends = (myData['friends'] as List?)?.cast<String>() ?? [];
        final incoming =
            (myData['incomingRequests'] as List?)?.cast<String>() ?? [];
        final outgoing =
            (myData['outgoingRequests'] as List?)?.cast<String>() ?? [];

        Query<Map<String, dynamic>> base =
            FirebaseFirestore.instance.collection('users').orderBy('name');

        Query<Map<String, dynamic>> query = base;
        final s = _q.trim();
        if (s.isNotEmpty) {
          query = base.startAt([s]).endAt(['$s\uf8ff']);
        } else {
          query = base.limit(20);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E1A),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: Colors.white12),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _q = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search users by name...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 380,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: query.snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(
                            child: Text("Search error",
                                style: TextStyle(color: Colors.white)),
                          );
                        }
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs =
                            snap.data!.docs.where((d) => d.id != me.uid).toList();

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No users found",
                              style:
                                  TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final data = doc.data();
                            final name = (data['name'] as String?) ?? "User";
                            final photoUrl = (data['photoUrl'] as String?) ?? "";

                            final isFriend = myFriends.contains(doc.id);
                            final isOutgoing = outgoing.contains(doc.id);
                            final isIncoming = incoming.contains(doc.id);

                            Widget trailing;
                            if (isFriend) {
                              trailing = _pillDisabled("Friend");
                            } else if (isIncoming) {
                              trailing = _pillDisabled("Requested you");
                            } else if (isOutgoing) {
                              trailing = Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _pillDisabled("Requested"),
                                  TextButton(
                                    onPressed: () => _cancelFriendRequest(doc.id),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              trailing = ElevatedButton(
                                onPressed: () => _sendFriendRequest(doc.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text("Request"),
                              );
                            }

                            return _UserInfoCard(
                              name: name,
                              photoUrl: photoUrl,
                              // ✅ arkadaş değilken bilgi gösterme
                              showStats: false,
                              trailing: trailing,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pillDisabled(String text) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white24,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    );
  }
}

// ===================== SHARED USER CARD =====================

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    required this.name,
    required this.photoUrl,
    required this.trailing,
    required this.showStats,
    this.programTitle = "No active program",
    this.sets = 0,
    this.waterMl = 0,
  });

  final String name;
  final String photoUrl;
  final Widget trailing;

  final bool showStats;
  final String programTitle;
  final int sets;
  final int waterMl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            backgroundImage:
                photoUrl.trim().isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.trim().isEmpty
                ? Text(
                    name.isNotEmpty ? name[0] : "U",
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                if (showStats) ...[
                  const SizedBox(height: 6),
                  // ✅ 1) program uzun -> 2 satır
                  Text(
                    programTitle,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _miniStat(Icons.fitness_center, "$sets"),
                      _miniStat(Icons.water_drop, "${waterMl}ml"),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ✅ 3) overflow azaltmak için trailing sınırı
         ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _readProgramTitle(Map<String, dynamic> userData) {
  final cp = userData['currentProgram'];
  if (cp is Map) {
    final t = cp['title'];
    if (t is String && t.trim().isNotEmpty) return t.trim();
  }
  return "No active program";
}
