import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({
    super.key,
    required this.readOnly,
  });

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final user = ref.watch(authControllerProvider).currentUser;
    app.ensureDailyAttendanceReset();
    final teachers = app.teachers;
    final presentCount = app.presentTeacherCount();

    return ScreenContainer(
      child: ListView(
        children: [
          SectionHeader(
            title: 'Kehadiran Hari Ini',
            subtitle: '$presentCount hadir dari ${teachers.length} guru',
          ),
          const SizedBox(height: 16),
          AttendanceDonutCard(
            present: presentCount,
            total: teachers.length,
          ),
          const SizedBox(height: 16),
          ...teachers.map((teacher) {
            final status = app.statusOfTeacher(teacher.email);
            final isSelf = user?.email == teacher.email;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text(teacher.displayTeacherName.characters.first)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.displayTeacherName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(teacher.subject ?? '-'),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: _label(status),
                            color: _color(status),
                          ),
                        ],
                      ),
                      if (!readOnly && isSelf) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Hadir'),
                              selected: status == AttendanceStatus.present,
                              onSelected: (_) => ref.read(appStateProvider).updateOwnAttendance(
                                    email: teacher.email,
                                    status: AttendanceStatus.present,
                                  ),
                            ),
                            ChoiceChip(
                              label: const Text('Tidak Hadir'),
                              selected: status == AttendanceStatus.absent,
                              onSelected: (_) => ref.read(appStateProvider).updateOwnAttendance(
                                    email: teacher.email,
                                    status: AttendanceStatus.absent,
                                  ),
                            ),
                            ChoiceChip(
                              label: const Text('Belum Dicek'),
                              selected: status == AttendanceStatus.unchecked,
                              onSelected: (_) => ref.read(appStateProvider).updateOwnAttendance(
                                    email: teacher.email,
                                    status: AttendanceStatus.unchecked,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _label(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Hadir';
      case AttendanceStatus.absent:
        return 'Tidak hadir';
      case AttendanceStatus.unchecked:
        return 'Belum dicek';
    }
  }

  Color _color(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.unchecked:
        return Colors.orange;
    }
  }
}