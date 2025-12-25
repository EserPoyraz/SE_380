import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInitializer {
  static Future<void> ensureUserExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    await ref.set({
      'name': user.displayName ?? 'User',
      'email': user.email,
      'photoUrl': user.photoURL,
      'water': 1000,
      'sets': 5,
      'bmi': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
