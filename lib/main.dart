import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_root.dart';
import 'core/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KelasKuApp()));
}

class KelasKuApp extends StatelessWidget {
  const KelasKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KelasKu',
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}
