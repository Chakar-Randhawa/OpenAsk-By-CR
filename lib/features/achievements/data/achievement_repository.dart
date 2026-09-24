import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/utils/reputation_calculator.dart';

class ContributionStats {
  final int totalQuestions;
  final int totalAnswers;
  final int helpfulAnswers;
  final double helpfulPercentage;
  final int calculatedReputation;
  final List<String> badges;

  ContributionStats({
    required this.totalQuestions,
    required this.totalAnswers,
    required this.helpfulAnswers,
    required this.helpfulPercentage,
    required this.calculatedReputation,
    required this.badges,
  });
}

abstract class AchievementRepository {
  Future<ContributionStats> getContributionStats(String uid);
  Future<List<AchievementModel>> getAchievements(String uid);
}

class FirestoreAchievementRepository implements AchievementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ContributionStats> getContributionStats(String uid) async {
    try {
      final qSnap = await _firestore
          .collection('questions')
          .where('authorUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      final aSnap = await _firestore
          .collection('answers')
          .where('authorUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      final hSnap = await _firestore
          .collection('answers')
          .where('authorUid', isEqualTo: uid)
          .where('isHelpful', isEqualTo: true)
          .count()
          .get();

      final qCount = qSnap.count ?? 0;
      final aCount = aSnap.count ?? 0;
      final hCount = hSnap.count ?? 0;

      final rep = ReputationCalculator.calculate(
        helpfulAnswersCount: hCount,
        totalAnswersCount: aCount,
        totalQuestionsCount: qCount,
      );

      final badges = ReputationCalculator.determineBadges(
        reputation: rep,
        helpfulAnswersCount: hCount,
        totalAnswersCount: aCount,
        totalQuestionsCount: qCount,
      );

      final helpfulPct = aCount > 0 ? (hCount / aCount) * 100 : 0.0;

      return ContributionStats(
        totalQuestions: qCount,
        totalAnswers: aCount,
        helpfulAnswers: hCount,
        helpfulPercentage: helpfulPct,
        calculatedReputation: rep,
        badges: badges,
      );
    } catch (_) {
      return ContributionStats(
        totalQuestions: 0,
        totalAnswers: 0,
        helpfulAnswers: 0,
        helpfulPercentage: 0.0,
        calculatedReputation: 0,
        badges: [],
      );
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements(String uid) async {
    final stats = await getContributionStats(uid);

    return [
      AchievementModel(
        id: 'first_question',
        name: 'First Inquiry',
        description: 'Asked your first question on OpenAsk',
        icon: '❓',
        category: 'contribution',
        requiredThreshold: 1,
        isUnlocked: stats.totalQuestions >= 1,
      ),
      AchievementModel(
        id: 'curious_mind',
        name: 'Curious Mind',
        description: 'Asked 10 thought-provoking questions',
        icon: '💡',
        category: 'contribution',
        requiredThreshold: 10,
        isUnlocked: stats.totalQuestions >= 10,
      ),
      AchievementModel(
        id: 'first_answer',
        name: 'First Knowledge Share',
        description: 'Provided your first answer to help a peer',
        icon: '✍️',
        category: 'helpful',
        requiredThreshold: 1,
        isUnlocked: stats.totalAnswers >= 1,
      ),
      AchievementModel(
        id: 'problem_solver',
        name: 'Problem Solver',
        description: 'Received your first accepted helpful solution',
        icon: '✅',
        category: 'helpful',
        requiredThreshold: 1,
        isUnlocked: stats.helpfulAnswers >= 1,
      ),
      AchievementModel(
        id: 'guide_star',
        name: 'Guide Star',
        description: '10 of your answers marked as helpful solutions',
        icon: '⭐',
        category: 'helpful',
        requiredThreshold: 10,
        isUnlocked: stats.helpfulAnswers >= 10,
      ),
      AchievementModel(
        id: 'rising_star',
        name: 'Rising Star',
        description: 'Earned 100+ reputation points across discussions',
        icon: '🚀',
        category: 'reputation',
        requiredThreshold: 100,
        isUnlocked: stats.calculatedReputation >= 100,
      ),
      AchievementModel(
        id: 'distinguished_scholar',
        name: 'Distinguished Member',
        description: 'Earned 500+ verified reputation points',
        icon: '🎓',
        category: 'reputation',
        requiredThreshold: 500,
        isUnlocked: stats.calculatedReputation >= 500,
      ),
    ];
  }
}
