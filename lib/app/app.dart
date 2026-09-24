import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/deep_link_service.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

/// Root application widget for OpenAsk.
class OpenAskApp extends ConsumerStatefulWidget {
  const OpenAskApp({super.key});

  @override
  ConsumerState<OpenAskApp> createState() => _OpenAskAppState();
}

class _OpenAskAppState extends ConsumerState<OpenAskApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForDeepLinks() async {
    final router = ref.read(routerProvider);

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        DeepLinkService.handleIncomingUri(initialUri, router);
      }
    } catch (_) {
      // Ignore failed deep-link hydration and continue with normal app startup.
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      DeepLinkService.handleIncomingUri(uri, router);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'OpenAsk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
      ],
      routerConfig: router,
    );
  }
}
