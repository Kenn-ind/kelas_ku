import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== ATTENDANCE =====
  Future<void> addAttendance(Map<String, dynamic> data) async {
    await _db.collection('attendance').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAttendance(String studentId) {
    return _db.collection('attendance')
      .where('studentId', isEqualTo: studentId)
      .orderBy('date', descending: true)
      .snapshots();
  }

  // ===== TASKS =====
  Stream<QuerySnapshot> getTasks(String userId) {
    return _db.collection('tasks')
      .where('assignedTo', isEqualTo: userId)
      .snapshots();
  }

  // ===== SCHEDULE =====
  Stream<QuerySnapshot> getSchedules() {
    return _db.collection('schedules')
      .orderBy('time')
      .snapshots();
  }
}