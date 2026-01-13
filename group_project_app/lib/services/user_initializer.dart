import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInitializer {
  static Future<void> ensureUserExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? 'User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'water': 1000,
        'sets': 5,
        'bmi': null,
        'bmiCategory': null,
        'gender': null,
        'friends': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 🔹 SADECE metadata güncelle
      await ref.update({'lastActiveAt': FieldValue.serverTimestamp()});
    }
  }
}
