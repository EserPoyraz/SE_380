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

          if (friends.isEmpty) {
            return Center(
              child: Text(
                "No friends yet.\nTap + to add.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            );
          }

          // friends UID listesine göre users dokümanlarını çek
          final friendsQuery = FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friends);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: friendsQuery.snapshots(),
            builder: (context, qsnap) {
              if (qsnap.hasError) {
                return const Center(
                  child: Text("Error loading users",
                      style: TextStyle(color: Colors.white)),
                );
              }
              if (!qsnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = qsnap.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final name = (d['name'] as String?) ?? "User";

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
                          child: Text(
                            name.isNotEmpty ? name[0] : "U",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

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

Future<void> _addFriendBothWays(String targetUid) async {
  final me = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  final myRef = db.collection('users').doc(me.uid);
  final targetRef = db.collection('users').doc(targetUid);

  final batch = db.batch();
  batch.update(myRef, {'friends': FieldValue.arrayUnion([targetUid])});
  batch.update(targetRef, {'friends': FieldValue.arrayUnion([me.uid])});
  await batch.commit();

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Friend added")),
  );
}

Future<void> _removeFriendBothWays(String targetUid) async {
  final me = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  final myRef = db.collection('users').doc(me.uid);
  final targetRef = db.collection('users').doc(targetUid);

  final batch = db.batch();
  batch.update(myRef, {'friends': FieldValue.arrayRemove([targetUid])});
  batch.update(targetRef, {'friends': FieldValue.arrayRemove([me.uid])});
  await batch.commit();

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Friend removed")),
  );
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

      // 🔽 burada eski UI'ını aynen kullanıyoruz
      Query<Map<String, dynamic>> base =
          FirebaseFirestore.instance.collection('users').orderBy('name');

      Query<Map<String, dynamic>> query = base;
      if (_q.trim().isNotEmpty) {
        final s = _q.trim();
        query = base.startAt([s]).endAt(['$s\uf8ff']);
      } else {
        query = base.limit(20);
      }

      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                      hintStyle: TextStyle(color: Colors.white54),
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snap.data!.docs
                          .where((d) => d.id != me.uid) // kendini çıkar
                          .toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7)),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data();
                          final name = (data['name'] as String?) ?? "User";

                          final isFriend = myFriends.contains(doc.id);

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
                                  child: Text(
                                    name.isNotEmpty ? name[0] : "U",
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // ✅ ADIM 3: Butonları burada değiştiriyoruz
                                if (!isFriend)
                                  ElevatedButton(
                                    onPressed: () => _addFriendBothWays(doc.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text("Add"),
                                  )
                                else
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.white24,
                                          disabledForegroundColor:
                                              Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text("Added"),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () =>
                                            _removeFriendBothWays(doc.id),
                                        child: const Text(
                                          "Remove",
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
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

}
