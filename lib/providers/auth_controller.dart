import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? errorMessage;

  // Login dengan email & password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final doc = await _db
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        errorMessage = 'Data pengguna tidak ditemukan.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = AppUser.fromFirestore(
        doc.data()!,
        credential.user!.uid,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register akun baru → status pending
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = AppUser(
        id: credential.user!.uid,
        name: name,
        username: username,
        email: email.trim(),
        role: UserRole.pending,
        classId: 'kelas-10a',
      );

      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toJson());

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    final doc = await _db.collection('users').doc(_currentUser!.id).get();
    if (doc.exists) {
      _currentUser = AppUser.fromFirestore(doc.data()!, doc.id);
      notifyListeners();
    }
  }

  // Cek session saat app dibuka
  Future<void> checkSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _currentUser = AppUser.fromFirestore(doc.data()!, doc.id);
      notifyListeners();
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah digunakan.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      case 'invalid-email':
        return 'Format email tidak valid.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}