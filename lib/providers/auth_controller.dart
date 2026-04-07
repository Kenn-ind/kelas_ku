import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import 'app_state.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController extends ChangeNotifier {
  AuthController(this.ref);

  final Ref ref;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  String? errorMessage;

  bool login(String email) {
    final user = ref.read(appStateProvider).findUserByEmail(email.trim());
    if (user == null) {
      errorMessage = 'Akun tidak ditemukan. Silakan register terlebih dahulu.';
      notifyListeners();
      return false;
    }
    _currentUser = user;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    errorMessage = null;
    notifyListeners();
  }

  void refreshCurrentUser() {
    if (_currentUser == null) return;
    final refreshed = ref.read(appStateProvider).findUserByEmail(_currentUser!.email);
    _currentUser = refreshed;
    notifyListeners();
  }
}
