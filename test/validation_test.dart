import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/utils/validators.dart';

void main() {
  group('Validators Test Suite', () {
    test('required validator', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('Valid text'), isNull);
    });

    test('email validator', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('john.doe@sub.domain.org'), isNull);
    });

    test('password validator', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('12345'), isNotNull); // < 6 chars
      expect(Validators.password('123456'), isNull); // 6 chars
      expect(Validators.password('securePassword123!'), isNull);
    });

    test('username validator', () {
      expect(Validators.username(null), isNotNull);
      expect(Validators.username('ab'), isNotNull); // < 3 chars
      expect(Validators.username('a' * 31), isNotNull); // > 30 chars
      expect(Validators.username('user with spaces'), isNotNull);
      expect(Validators.username('user@name'), isNotNull);
      expect(Validators.username('valid_user_123'), isNull);
    });

    test('question title validator', () {
      expect(Validators.questionTitle(null), isNotNull);
      expect(Validators.questionTitle('Short?'), isNotNull); // < 8 chars
      expect(Validators.questionTitle('Valid question title about Flutter architecture?'), isNull);
    });

    test('question body validator', () {
      expect(Validators.questionBody(null), isNotNull);
      expect(Validators.questionBody('Too brief.'), isNotNull); // < 15 chars
      expect(
        Validators.questionBody('This is a sufficiently long question description providing needed context.'),
        isNull,
      );
    });

    test('answer body validator', () {
      expect(Validators.answerBody(null), isNotNull);
      expect(Validators.answerBody('No'), isNotNull); // < 5 chars
      expect(Validators.answerBody('This answer explains the concept clearly.'), isNull);
    });
  });
}
