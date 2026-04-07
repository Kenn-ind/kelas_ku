import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_state.dart';
import '../../widgets/common.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({
    super.key,
    required this.readOnly,
  });

  final bool readOnly;

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

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
              onPressed: () => _showTaskDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tugas',
            subtitle: widget.readOnly
                ? 'Siswa hanya dapat melihat daftar tugas.'
                : 'Guru dapat menambah, menandai selesai, dan menghapus tugas.',
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Belum'),
              Tab(text: 'Selesai'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _taskList(app.filteredTasks(TaskFilter.all)),
                _taskList(app.filteredTasks(TaskFilter.pending)),
                _taskList(app.filteredTasks(TaskFilter.completed)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(List<TaskItem> tasks) {
    if (tasks.isEmpty) {
      return const EmptyStateCard(
        title: 'Belum ada tugas',
        subtitle: 'Tambahkan tugas baru agar siswa dapat melihatnya di dashboard.',
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final dueSoon = !task.isCompleted && task.deadline.difference(DateTime.now()).inDays <= 2;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.readOnly)
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => ref.read(appStateProvider).toggleTask(task.id),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text('${task.subject} · Deadline ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}'),
                      if (task.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(task.note!),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(
                            label: task.isCompleted ? 'Selesai' : 'Belum',
                            color: task.isCompleted ? Colors.green : Colors.orange,
                          ),
                          if (dueSoon) const StatusBadge(label: 'Deadline dekat', color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!widget.readOnly)
                  IconButton(
                    onPressed: () => ref.read(appStateProvider).deleteTask(task.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Tambah tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nama tugas'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Mapel'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.grey.shade50,
                  title: const Text('Deadline'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.date_range_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (titleController.text.isEmpty || subjectController.text.isEmpty) return;
                ref.read(appStateProvider).addTask(
                      title: titleController.text,
                      subject: subjectController.text,
                      note: noteController.text.isEmpty ? null : noteController.text,
                      deadline: selectedDate,
                    );
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
