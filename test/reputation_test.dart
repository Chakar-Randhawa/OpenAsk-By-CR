import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/utils/reputation_calculator.dart';

void main() {
  group('ReputationCalculator Test Suite', () {
    test('calculate returns 0 for empty profile', () {
      final rep = ReputationCalculator.calculate(
        helpfulAnswersCount: 0,
        totalAnswersCount: 0,
        totalQuestionsCount: 0,
      );
      expect(rep, equals(0));
    });

    test('calculate scores correct weights deterministically', () {
      // 2 helpful answers * 15 = 30
      // 5 total answers * 5 = 25
      // 3 questions * 2 = 6
      // 10 upvotes * 10 = 100
      // 1 downvote * 2 = 2
      // Total = 30 + 25 + 6 + 100 - 2 = 159
      final rep = ReputationCalculator.calculate(
        helpfulAnswersCount: 2,
        totalAnswersCount: 5,
        totalQuestionsCount: 3,
        upvotesReceived: 10,
        downvotesReceived: 1,
      );
      expect(rep, equals(159));
    });

    test('calculate prevents negative reputation score', () {
      final rep = ReputationCalculator.calculate(
        helpfulAnswersCount: 0,
        totalAnswersCount: 0,
        totalQuestionsCount: 0,
        upvotesReceived: 0,
        downvotesReceived: 10,
      );
      expect(rep, equals(0));
    });

    test('determineBadges assigns milestones accurately', () {
      final badges = ReputationCalculator.determineBadges(
        reputation: 600,
        helpfulAnswersCount: 12,
        totalAnswersCount: 30,
        totalQuestionsCount: 15,
      );

      expect(badges, contains('Curious Mind'));
      expect(badges, contains('Inquisitive'));
      expect(badges, contains('First Answer'));
      expect(badges, contains('Active Contributor'));
      expect(badges, contains('Problem Solver'));
      expect(badges, contains('Top Guide'));
      expect(badges, contains('Rising Star'));
      expect(badges, contains('Distinguished Member'));
      expect(badges, isNot(contains('Master Solver'))); // Needs 50 helpful
    });
  });
}
