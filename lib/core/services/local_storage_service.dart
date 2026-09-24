import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local device persistence strictly for drafts, UI preferences, and search history.
/// Never stores passwords or auth tokens.
class LocalStorageService {
  static const String _keyDraftQuestion = 'openask_draft_question';
  static const String _keyRecentSearches = 'openask_recent_searches';
  static const String _keyThemeMode = 'openask_theme_mode';
  static const String _keyLocale = 'openask_locale';

  // Drafts
  static Future<void> saveQuestionDraft({
    required String title,
    required String body,
    required String? categoryId,
    required List<String> tags,
    required bool isAnonymous,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'title': title,
      'body': body,
      'categoryId': categoryId,
      'tags': tags,
      'isAnonymous': isAnonymous,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_keyDraftQuestion, data);
  }

  static Future<Map<String, dynamic>?> getQuestionDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyDraftQuestion);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearQuestionDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftQuestion);
  }

  // Recent Searches
  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentSearches) ?? [];
  }

  static Future<void> addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_keyRecentSearches) ?? [];
    searches.remove(clean);
    searches.insert(0, clean);
    if (searches.length > 10) searches.removeLast();
    await prefs.setStringList(_keyRecentSearches, searches);
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentSearches);
  }

  // Preferences
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, languageCode);
  }

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? 'en';
  }
}
