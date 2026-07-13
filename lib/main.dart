import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/routes.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MozhiMuthalApp(),
    ),
  );
}

class MozhiMuthalApp extends ConsumerWidget {
  const MozhiMuthalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MozhiMuthal',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
    );
  }
}
