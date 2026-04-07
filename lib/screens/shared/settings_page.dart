import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../providers/app_state.dart';
import '../../widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    super.key,
    required this.canEdit,
  });

  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final settings = app.settings;

    return ScreenContainer(
      fab: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showPhaseDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah jam'),
            )
          : null,
      child: ListView(
        children: [
          SectionHeader(
            title: 'Pengaturan',
            subtitle: canEdit ? 'Admin dapat mengubah identitas sekolah dan jam sekolah.' : 'Informasi sekolah hanya dapat diubah oleh admin.',
            trailing: StatusBadge(
              label: canEdit ? 'Admin edit' : 'Read only',
              color: canEdit ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi umum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nama sekolah'),
                    subtitle: Text(settings.schoolName),
                    trailing: canEdit
                        ? IconButton(
                            onPressed: () => _showIdentityDialog(context, ref),
                            icon: const Icon(Icons.edit_outlined),
                          )
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kelas'),
                    subtitle: Text(settings.className),
                  ),
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
                  const Text('Jam sekolah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...settings.phases.map((phase) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(phase.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('${phase.start} - ${phase.end}'),
                                  ],
                                ),
                              ),
                              if (canEdit) ...[
                                IconButton(
                                  onPressed: () => _showPhaseDialog(context, ref, phase: phase),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => ref.read(appStateProvider).deletePhase(phase.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showIdentityDialog(BuildContext context, WidgetRef ref) async {
    final app = ref.read(appStateProvider);
    final schoolController = TextEditingController(text: app.settings.schoolName);
    final classController = TextEditingController(text: app.settings.className);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah identitas sekolah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: schoolController, decoration: const InputDecoration(labelText: 'Nama sekolah')),
            const SizedBox(height: 12),
            TextField(controller: classController, decoration: const InputDecoration(labelText: 'Kelas')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              app.updateSchoolIdentity(
                schoolName: schoolController.text,
                className: classController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhaseDialog(BuildContext context, WidgetRef ref, {SchoolPhase? phase}) async {
    final app = ref.read(appStateProvider);
    final labelController = TextEditingController(text: phase?.label ?? '');
    final startController = TextEditingController(text: phase?.start ?? '08:00');
    final endController = TextEditingController(text: phase?.end ?? '08:30');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(phase == null ? 'Tambah jam sekolah' : 'Edit jam sekolah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label')),
            const SizedBox(height: 12),
            TextField(controller: startController, decoration: const InputDecoration(labelText: 'Mulai (HH:MM)')),
            const SizedBox(height: 12),
            TextField(controller: endController, decoration: const InputDecoration(labelText: 'Selesai (HH:MM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (phase == null) {
                app.addPhase(
                  label: labelController.text,
                  start: startController.text,
                  end: endController.text,
                );
              } else {
                app.updatePhase(
                  id: phase.id,
                  label: labelController.text,
                  start: startController.text,
                  end: endController.text,
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
