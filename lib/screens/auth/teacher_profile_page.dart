import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state.dart';
import '../../providers/auth_controller.dart';

class TeacherProfilePage extends ConsumerStatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  ConsumerState<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends ConsumerState<TeacherProfilePage> {
  final subjectController = TextEditingController();
  final nicknameController = TextEditingController();

  @override
  void dispose() {
    subjectController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil Guru')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sebelum masuk dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan isi mapel yang diampu dan panggilan guru terlebih dahulu.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Guru mapel apa?'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: 'Panggilan guru'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: user == null
                          ? null
                          : () {
                              if (subjectController.text.isEmpty || nicknameController.text.isEmpty) return;
                              ref.read(appStateProvider).saveTeacherProfile(
                                    userId: user.id,
                                    subject: subjectController.text,
                                    nickname: nicknameController.text,
                                  );
                              ref.read(authControllerProvider).refreshCurrentUser();
                            },
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      child: const Text('Simpan profil guru'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
