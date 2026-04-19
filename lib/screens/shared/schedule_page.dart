import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_state.dart';
import '../../widgets/common.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({
    super.key,
    required this.readOnly,
  });

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);

    return ScreenContainer(
      child: ListView(
        children: [
          SectionHeader(
            title: 'Jadwal Mingguan',
            subtitle: readOnly
                ? 'Mode siswa hanya dapat melihat jadwal.'
                : 'Tap slot untuk tambah mapel/guru. Tahan chip untuk hapus.',
          ),
          const SizedBox(height: 16),
          ...app.weekdays.map((day) {
            final slots = app.schedule[day] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(day,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${slots.length} slot'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    ...List.generate(slots.length, (index) {
                      final slot = slots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: readOnly || slot.isBreak
                              ? null
                              : () =>
                                  _showAddEntryDialog(context, ref, day, index),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: slot.isBreak
                                  ? Colors.orange.withValues(alpha: 0.08)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: slot.isBreak
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(slot.isBreak
                                        ? Icons.free_breakfast_outlined
                                        : Icons.add_box_outlined),
                                    const SizedBox(width: 10),
                                    Text('${slot.start} - ${slot.end}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    if (slot.isBreak)
                                      const StatusBadge(
                                          label: 'Istirahat',
                                          color: Colors.orange)
                                    else if (!readOnly)
                                      const Icon(Icons.add_circle_outline),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (slot.entries.isEmpty)
                                  Text(
                                    slot.isBreak
                                        ? 'Waktu istirahat'
                                        : 'Belum ada mapel',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(slot.entries.length,
                                        (entryIndex) {
                                      final entry = slot.entries[entryIndex];
                                      return GestureDetector(
                                        onLongPress: readOnly
                                            ? null
                                            : () => ref
                                                .read(appStateProvider)
                                                .deleteScheduleEntry(
                                                  day: day,
                                                  slotIndex: index,
                                                  entryIndex: entryIndex,
                                                ),
                                        child: Chip(
                                          label: Text(
                                              '${entry.subject} · ${entry.teacherName}'),
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showAddEntryDialog(
      BuildContext context, WidgetRef ref, String day, int slotIndex) async {
    final app = ref.read(appStateProvider);
    final currentEntries =
        app.schedule[day]?[slotIndex].entries ?? const <ScheduleEntry>[];
    final currentEntry =
        currentEntries.isNotEmpty ? currentEntries.first : null;
    final subjectController =
        TextEditingController(text: currentEntry?.subject ?? '');
    String? teacherEmail = currentEntry?.teacherEmail ??
        (app.teachers.isNotEmpty ? app.teachers.first.email : null);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah / ganti mapel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Nama mapel'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: teacherEmail,
              items: app.teachers
                  .map(
                    (teacher) => DropdownMenuItem(
                      value: teacher.email,
                      child: Text(
                        '${teacher.displayTeacherName} · ${teacher.subject ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => teacherEmail = value,
              decoration: const InputDecoration(labelText: 'Guru mengajar'),
              selectedItemBuilder: (context) => app.teachers
                  .map(
                    (teacher) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${teacher.displayTeacherName} · ${teacher.subject ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (subjectController.text.trim().isEmpty || teacherEmail == null) {
                return;
              }
              final teacher = app.findUserByEmail(teacherEmail!);
              if (teacher == null) return;

              final entry = ScheduleEntry(
                subject: subjectController.text.trim(),
                teacherName: teacher.displayTeacherName,
                teacherEmail: teacher.email,
              );

              if (currentEntry == null) {
                app.addScheduleEntry(
                  day: day,
                  slotIndex: slotIndex,
                  entry: entry,
                );
              } else {
                app.updateScheduleEntry(
                  day: day,
                  slotIndex: slotIndex,
                  entryIndex: 0,
                  entry: entry,
                );
              }

              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
