import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_models.dart';
import 'providers/app_state.dart';
import 'providers/auth_controller.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/pending_page.dart';
import 'screens/auth/teacher_profile_page.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final appState = ref.watch(appStateProvider);
    final user = auth.currentUser;

    if (user == null) return const LoginPage();

    // Tampilkan loading saat data Firestore belum siap
    if (appState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.role == UserRole.pending) return const PendingPage();

    if (user.role == UserRole.teacher && user.needsTeacherProfile) {
      return const TeacherProfilePage();
    }

    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.pending:
        return const PendingPage();
    }
  }
}