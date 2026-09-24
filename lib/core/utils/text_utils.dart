/// Text processing utilities: hashtags, mentions, reading time, excerpt.
class TextUtils {
  TextUtils._();

  /// Extract @mentions from text.
  static List<String> extractMentions(String text) {
    final matches = RegExp(r'@([a-zA-Z0-9_]{3,30})').allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }

  /// Extract #hashtags from text.
  static List<String> extractHashtags(String text) {
    final matches = RegExp(r'#([a-zA-Z0-9_]{2,30})').allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }

  /// Truncate text to a given length cleanly with ellipsis.
  static String excerpt(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}...';
  }

  /// Calculate reading time in minutes.
  static int estimateReadingTimeMinutes(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    final mins = (words / 200).ceil();
    return mins < 1 ? 1 : mins;
  }
}
