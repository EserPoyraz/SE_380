import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgramRepository {
  // TO SAVE THE PROGRAMS GENERATED INTO FIRESBASE
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProgramRepository({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userProgramsRef() {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('programs');
  }

  Future<void> saveProgram({
    required String title,
    required String location,
    required String split,
    required String goal,
    required double heightCm,
    required double weightKg,
    required Map<String, dynamic>
    daysJson, // { "Push": [ {name,sets,reps,note}, ... ], ... }
  }) async {
    await _userProgramsRef().add({
      'title': title,
      'location': location,
      'split': split,
      'goal': goal,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'days': daysJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPrograms() {
    return _userProgramsRef()
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteProgram(String docId) async {
    await _userProgramsRef().doc(docId).delete();
  }
}
