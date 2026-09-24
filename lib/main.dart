import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: OpenAskApp(),
    ),
  );
}

class OpenAskApp extends ConsumerWidget {
  const OpenAskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OpenAsk',
      debugShowCheckedModeBanner: false,
      theme: OpenAskTheme.lightTheme,
      darkTheme: OpenAskTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
