import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({
    super.key,
    required this.readOnly,
  });

  final bool readOnly;

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);

    return ScreenContainer(
      fab: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddScheduleDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah mapel'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Jadwal Mingguan',
            subtitle: widget.readOnly
                ? 'Mode siswa hanya dapat melihat jadwal.'
                : 'Tap tambah mapel untuk mengisi jadwal.',
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _days.map((d) => Tab(text: d)).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final slots = app.schedule[day] ?? [];
                final phases = app.settings.phases;

                if (phases.isEmpty) {
                  return const Center(
                    child: EmptyStateCard(
                      title: 'Belum ada slot pelajaran',
                      subtitle: 'Admin perlu membuat slot pelajaran terlebih dahulu di menu Pengaturan.',
                      icon: Icons.schedule_outlined,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    final slot = slots.firstWhere(
                      (s) => s.start == phase.start && s.end == phase.end,
                      orElse: () => ScheduleSlot(
                        start: phase.start,
                        end: phase.end,
                        entries: const [],
                      ),
                    );
                    final hasEntry = slot.entries.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Nomor pelajaran
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: hasEntry
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: hasEntry
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info slot
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          phase.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${phase.start} - ${phase.end}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (hasEntry) ...[
                                      Text(
                                        slot.entries.first.subject,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        slot.entries.first.teacherName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ] else
                                      const Text(
                                        'Belum ada mapel',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Tombol edit (hanya guru)
                              if (!widget.readOnly)
                                IconButton(
                                  onPressed: () => _showAddScheduleDialog(
                                    context,
                                    ref,
                                    selectedDay: day,
                                    selectedPhaseId: phase.id,
                                    existingEntry: hasEntry
                                        ? slot.entries.first
                                        : null,
                                  ),
                                  icon: Icon(
                                    hasEntry
                                        ? Icons.edit_outlined
                                        : Icons.add_circle_outline,
                                    color: hasEntry
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddScheduleDialog(
    BuildContext context,
    WidgetRef ref, {
    String? selectedDay,
    String? selectedPhaseId,
    ScheduleEntry? existingEntry,
  }) async {
    final app = ref.read(appStateProvider);
    final user = ref.read(authControllerProvider).currentUser;
    final phases = app.settings.phases;

    if (phases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin belum membuat slot pelajaran.')),
      );
      return;
    }

    final subjectController = TextEditingController(
      text: existingEntry?.subject ?? '',
    );
    String currentDay = selectedDay ?? _days[_tabController.index];
    String? currentPhaseId = selectedPhaseId ?? phases.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            existingEntry == null ? 'Tambah mapel' : 'Edit mapel',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pilih hari
                DropdownButtonFormField<String>(
                  value: currentDay,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Hari',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: _days
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setModalState(() => currentDay = v!),
                ),
                const SizedBox(height: 16),

                // Label pilih slot
                const Text(
                  'Pilih slot pelajaran',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),

                // Grid pelajaran
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    final isSelected = currentPhaseId == phase.id;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => currentPhaseId = phase.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'P${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${phase.start}-${phase.end}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Nama mapel
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Nama mapel',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (subjectController.text.trim().isEmpty ||
                    currentPhaseId == null ||
                    user == null) return;

                await ref.read(appStateProvider).addOrUpdateScheduleSlot(
                      day: currentDay,
                      phaseId: currentPhaseId!,
                      subject: subjectController.text.trim(),
                      teacherName: user.displayTeacherName,
                      teacherEmail: user.email,
                    );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}