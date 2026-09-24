import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/utils/text_utils.dart';

void main() {
  group('TextUtils Test Suite', () {
    test('extractMentions extracts unique valid handles', () {
      const text = 'Hello @alice and @bob_123, also pinging @alice again!';
      final mentions = TextUtils.extractMentions(text);
      expect(mentions, containsAll(['alice', 'bob_123']));
      expect(mentions.length, equals(2));
    });

    test('extractHashtags extracts unique hashtags', () {
      const text = 'Exploring #flutter and #firebase with #flutter tags!';
      final tags = TextUtils.extractHashtags(text);
      expect(tags, containsAll(['flutter', 'firebase']));
      expect(tags.length, equals(2));
    });

    test('excerpt truncates cleanly', () {
      const longText = 'This is a long sentence that should be excerpted after twenty characters.';
      final short = TextUtils.excerpt(longText, 20);
      expect(short.endsWith('...'), isTrue);
      expect(short.length, lessThanOrEqualTo(23));
    });

    test('estimateReadingTimeMinutes computes proper minutes', () {
      final shortText = 'One two three four five';
      expect(TextUtils.estimateReadingTimeMinutes(shortText), equals(1));

      final longText = List.generate(450, (i) => 'word').join(' ');
      expect(TextUtils.estimateReadingTimeMinutes(longText), equals(3));
    });
  });
}
