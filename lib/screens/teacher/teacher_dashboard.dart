import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../shared/attendance_page.dart';
import '../shared/home_page.dart';
import '../shared/schedule_page.dart';
import '../shared/settings_page.dart';
import '../shared/tasks_page.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomePage(readOnly: false),
      SchedulePage(readOnly: false),
      TasksPage(readOnly: false),
      AttendancePage(readOnly: false),
      SettingsPage(canEdit: false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.calendar_view_week_outlined), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tugas'),
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Kehadiran'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Info'),
        ],
      ),
    );
  }
}
