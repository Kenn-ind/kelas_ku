import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';

class HomePage extends ConsumerWidget {
  const HomePage({
    super.key,
    required this.readOnly,
  });

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final user = ref.watch(authControllerProvider).currentUser;
    final now = DateTime.now();
    final currentPhase = app.getCurrentPhase(now);
    final currentEntry = app.getCurrentTeachingEntry(now);
    final upcoming = app.upcomingDeadlines();
    final progress = _dayProgress(app, now);
    final currentTeacherStatus = currentEntry == null ? null : app.statusOfTeacher(currentEntry.teacherEmail);

    return ScreenContainer(
      child: ListView(
        children: [
          SectionHeader(
            title: 'Beranda ${readOnly ? 'Siswa' : 'Guru'}',
            subtitle: '${app.settings.schoolName} · ${app.settings.className}',
            trailing: user == null
                ? null
                : StatusBadge(
                    label: readOnly ? 'Read only' : user.displayTeacherName,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 16),
          ResponsiveMetricGrid(
            children: [
              MetricCard(
                title: 'Progress jam sekolah',
                value: '${(progress * 100).toStringAsFixed(0)}%',
                subtitle: currentPhase == null ? 'Di luar jam sekolah' : currentPhase.label,
                icon: Icons.schedule_rounded,
              ),
              MetricCard(
                title: 'Jumlah tugas',
                value: '${app.tasks.length}',
                subtitle: '${app.tasks.where((e) => !e.isCompleted).length} belum selesai',
                icon: Icons.assignment_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timeline sekolah hari ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(999)),
                  const SizedBox(height: 16),
                  ...app.settings.phases.map((phase) {
                    final active = currentPhase?.id == phase.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(active ? Icons.play_circle_fill_rounded : Icons.radio_button_unchecked),
                      title: Text(phase.label),
                      subtitle: Text('${phase.start} - ${phase.end}'),
                      trailing: active
                          ? StatusBadge(label: 'Aktif', color: Theme.of(context).colorScheme.primary)
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deadline 1-2 hari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    const Text('Tidak ada tugas dengan deadline dekat.')
                  else
                    ...upcoming.map((task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(task.title),
                          subtitle: Text('${task.subject} · Deadline ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}'),
                          trailing: StatusBadge(
                            label: task.isCompleted ? 'Selesai' : 'Belum',
                            color: task.isCompleted ? Colors.green : Colors.orange,
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mapel aktif & guru saat ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (currentEntry == null)
                    const Text('Saat ini tidak ada mapel aktif.')
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(currentEntry.teacherName.characters.first),
                      ),
                      title: Text(currentEntry.subject),
                      subtitle: Text(currentEntry.teacherName),
                      trailing: StatusBadge(
                        label: _attendanceLabel(currentTeacherStatus),
                        color: _attendanceColor(currentTeacherStatus),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _dayProgress(app, DateTime now) {
    final start = 8 * 60;
    final end = 15 * 60;
    final current = now.hour * 60 + now.minute;
    if (current <= start) return 0;
    if (current >= end) return 1;
    return (current - start) / (end - start);
  }

  String _attendanceLabel(status) {
    switch (status) {
      case null:
        return 'Belum ada';
      case dynamic s when s.toString().contains('present'):
        return 'Hadir';
      case dynamic s when s.toString().contains('absent'):
        return 'Tidak hadir';
      default:
        return 'Belum dicek';
    }
  }

  Color _attendanceColor(status) {
    switch (_attendanceLabel(status)) {
      case 'Hadir':
        return Colors.green;
      case 'Tidak hadir':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
