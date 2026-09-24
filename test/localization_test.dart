import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openask/l10n/app_localizations.dart';

void main() {
  group('Localization Test Suite (Phase 22)', () {
    test('supports all 7 required languages', () {
      final supportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
      expect(supportedCodes, containsAll(['en', 'ur', 'ar', 'hi', 'es', 'fr', 'pt']));
    });

    test('correctly identifies RTL for Arabic and Urdu', () {
      expect(AppLocalizations.isRtl(const Locale('ar')), isTrue);
      expect(AppLocalizations.isRtl(const Locale('ur')), isTrue);
      expect(AppLocalizations.isRtl(const Locale('en')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('es')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('fr')), isFalse);
    });

    test('translates key terms across languages', () {
      final en = AppLocalizations(const Locale('en'));
      final ur = AppLocalizations(const Locale('ur'));
      final ar = AppLocalizations(const Locale('ar'));
      final es = AppLocalizations(const Locale('es'));

      expect(en.translate('app_title'), equals('OpenAsk'));
      expect(ur.translate('app_title'), equals('اوپن آسک'));
      expect(ar.translate('app_title'), equals('أوبن آسك'));
      expect(es.translate('ask_question'), equals('Hacer una pregunta'));
    });
  });
}
