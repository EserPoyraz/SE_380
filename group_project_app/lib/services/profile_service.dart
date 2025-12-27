import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  ProfileService._();

  static User get me => FirebaseAuth.instance.currentUser!;

  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileDocStream() {
    return FirebaseFirestore.instance.collection('users').doc(me.uid).snapshots();
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> addFriend(String uid) async {
    // ileride lazım olabilir, şimdilik burada dursun
    await FirebaseFirestore.instance.collection('users').doc(me.uid).update({
      'friends': FieldValue.arrayUnion([uid]),
    });
  }
  static Future<void> updateBodyMetrics({
  required int heightCm,
  required int weightKg,
  required String gender,
}) async {
  final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
  final category = _bmiCategory(bmi);

  await FirebaseFirestore.instance.collection('users').doc(me.uid).update({
    'heightCm': heightCm,
    'weightKg': weightKg,
    'gender': gender,
    'bmi': double.parse(bmi.toStringAsFixed(1)),
    'bmiCategory': category,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

static String _bmiCategory(double bmi) {
  if (bmi < 18.5) return "Underweight";
  if (bmi < 25) return "Normal";
  if (bmi < 30) return "Overweight";
  return "Obese";
}
}
