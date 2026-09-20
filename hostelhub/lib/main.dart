import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Surface runtime build errors instead of a blank white screen, so we can
  // see the real exception when a page fails to build.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF12121F),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Something went wrong on this screen',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                        color: Color(0xFFFF8A80), fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please screenshot this and send it, so we can fix it.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  runApp(const ProviderScope(child: HostelHubApp()));
}

class HostelHubApp extends ConsumerWidget {
  const HostelHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HostelHub',
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
