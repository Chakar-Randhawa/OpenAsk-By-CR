import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Product analytics strictly using Firebase Analytics (Spark compatible).
/// Never collects sensitive PII or private anonymous author mappings.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logSignup(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignup error: $e');
    }
  }

  static Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  static Future<void> logQuestionCreated({
    required String categoryId,
    required bool isAnonymous,
    required int tagCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'question_created',
        parameters: {
          'category_id': categoryId,
          'is_anonymous': isAnonymous ? 1 : 0,
          'tag_count': tagCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logQuestionViewed(String questionId) async {
    try {
      await _analytics.logEvent(
        name: 'question_viewed',
        parameters: {'question_id': questionId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logAnswerCreated({
    required String questionId,
    required bool isAnonymous,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'answer_created',
        parameters: {
          'question_id': questionId,
          'is_anonymous': isAnonymous ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logAnswerHelpful(String questionId) async {
    try {
      await _analytics.logEvent(
        name: 'answer_helpful',
        parameters: {'question_id': questionId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logQuestionSaved(String questionId, bool saved) async {
    try {
      await _analytics.logEvent(
        name: saved ? 'question_saved' : 'question_unsaved',
        parameters: {'question_id': questionId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logQuestionShared(String questionId) async {
    try {
      await _analytics.logShare(
        contentType: 'question',
        itemId: questionId,
        method: 'system_share',
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logCategoryFollowed(String categoryId, bool followed) async {
    try {
      await _analytics.logEvent(
        name: followed ? 'category_followed' : 'category_unfollowed',
        parameters: {'category_id': categoryId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logSearchPerformed(String query) async {
    try {
      await _analytics.logSearch(searchTerm: query);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logReportCreated(String targetType) async {
    try {
      await _analytics.logEvent(
        name: 'report_created',
        parameters: {'target_type': targetType},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
