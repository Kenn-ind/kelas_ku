import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';
import '../shared/settings_page.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _AdminOverviewPage(),
      const _ApprovalPage(),
      const SettingsPage(canEdit: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined), label: 'Approval'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

class _AdminOverviewPage extends ConsumerWidget {
  const _AdminOverviewPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);

    return ScreenContainer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SectionHeader(
            title: 'Ringkasan kelas',
            subtitle: '${app.settings.schoolName} · ${app.settings.className}',
          ),
          const SizedBox(height: 16),
          ResponsiveMetricGrid(
            children: [
              MetricCard(
                title: 'Guru aktif',
                value: '${app.teachers.length}',
                subtitle: 'Semua guru dalam kelas',
                icon: Icons.person_outline_rounded,
              ),
              MetricCard(
                title: 'Siswa aktif',
                value: '${app.students.length}',
                subtitle: 'Terhubung ke satu kelas',
                icon: Icons.groups_2_outlined,
              ),
              MetricCard(
                title: 'Tugas aktif',
                value: '${app.tasks.where((e) => !e.isCompleted).length}',
                subtitle: 'Belum selesai',
                icon: Icons.assignment_outlined,
              ),
              MetricCard(
                title: 'Menunggu approval',
                value: '${app.pendingUsers.length}',
                subtitle: 'Perlu persetujuan admin',
                icon: Icons.hourglass_bottom_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalPage extends ConsumerWidget {
  const _ApprovalPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final pending = app.pendingUsers;

    return ScreenContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Persetujuan user',
            subtitle: 'Pilih apakah akun baru akan menjadi siswa atau guru.',
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardSize = constraints.maxWidth < 420
                        ? constraints.maxWidth * 0.82
                        : 320.0;
                    return SizedBox.square(
                      dimension: cardSize.clamp(220.0, 320.0),
                      child: const EmptyStateCard(
                        title: 'Tidak ada antrean approval',
                        subtitle: 'Semua user baru sudah diproses.',
                        icon: Icons.verified_user_outlined,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = pending[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('${user.username} · ${user.email}'),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () => ref
                                    .read(appStateProvider)
                                    .approveUserAsStudent(user.id),
                                icon: const Icon(Icons.school_outlined),
                                label: const Text('Approve sebagai siswa'),
                              ),
                              FilledButton.icon(
                                onPressed: () => ref
                                    .read(appStateProvider)
                                    .approveUserAsTeacher(user.id),
                                icon: const Icon(Icons.badge_outlined),
                                label: const Text('Approve sebagai guru'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(appStateProvider)
                                    .rejectUser(user.id),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Tolak'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
