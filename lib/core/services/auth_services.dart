import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register
  Future<UserCredential> register(String email, String password, String name, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password
    );
    
    // Simpan ke Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'status': 'pending', // Butuh approval admin
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return cred;
  }

  // Login
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email, password: password
    );
  }

  // Get current user data
  Stream<DocumentSnapshot> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
  
  // Logout
  Future<void> logout() async => await _auth.signOut();
}