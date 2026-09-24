/// Verifiable reputation and badge calculation.
/// Under Firebase Spark architecture, reputation is calculated from
/// authoritative immutable records rather than trusting client-written scores.
class ReputationCalculator {
  ReputationCalculator._();

  static const int pointsPerHelpfulAnswer = 15;
  static const int pointsPerAnswer = 5;
  static const int pointsPerQuestion = 2;
  static const int pointsPerUpvote = 10;
  static const int penaltyPerDownvote = 2;

  /// Calculate total reputation score deterministically.
  static int calculate({
    required int helpfulAnswersCount,
    required int totalAnswersCount,
    required int totalQuestionsCount,
    int upvotesReceived = 0,
    int downvotesReceived = 0,
  }) {
    final base = (helpfulAnswersCount * pointsPerHelpfulAnswer) +
        (totalAnswersCount * pointsPerAnswer) +
        (totalQuestionsCount * pointsPerQuestion) +
        (upvotesReceived * pointsPerUpvote) -
        (downvotesReceived * penaltyPerDownvote);

    return base < 0 ? 0 : base;
  }

  /// Derive user badges based on real contribution metrics.
  static List<String> determineBadges({
    required int reputation,
    required int helpfulAnswersCount,
    required int totalAnswersCount,
    required int totalQuestionsCount,
  }) {
    final badges = <String>[];

    if (totalQuestionsCount >= 1) badges.add('Curious Mind');
    if (totalQuestionsCount >= 10) badges.add('Inquisitive');
    if (totalAnswersCount >= 1) badges.add('First Answer');
    if (totalAnswersCount >= 25) badges.add('Active Contributor');
    if (totalAnswersCount >= 100) badges.add('Knowledge Pillar');
    if (helpfulAnswersCount >= 1) badges.add('Problem Solver');
    if (helpfulAnswersCount >= 10) badges.add('Top Guide');
    if (helpfulAnswersCount >= 50) badges.add('Master Solver');
    if (reputation >= 100) badges.add('Rising Star');
    if (reputation >= 500) badges.add('Distinguished Member');
    if (reputation >= 2000) badges.add('Eminent Scholar');

    return badges;
  }
}
