import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/user_profile_model.dart';
import '../core/models/question_model.dart';
import '../core/models/category_model.dart';
import '../core/models/notification_model.dart';
import '../core/models/comment_model.dart';
import '../core/models/achievement_model.dart';
import '../core/models/bookmark_model.dart';
import '../core/services/local_storage_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/questions/data/question_repository.dart';
import '../features/answers/data/answer_repository.dart';
import '../features/categories/data/category_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/moderation/data/moderation_repository.dart';
import '../features/comments/data/comment_repository.dart';
import '../features/bookmarks/data/bookmark_repository.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/achievements/data/achievement_repository.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return FirestoreQuestionRepository();
});

final answerRepositoryProvider = Provider<AnswerRepository>((ref) {
  return FirestoreAnswerRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirestoreCategoryRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return FirestoreModerationRepository();
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return FirestoreCommentRepository();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return FirestoreBookmarkRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return FirestoreAchievementRepository();
});

// Auth State Providers
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  return ref.watch(authRepositoryProvider).getUserProfile(authUser.uid);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final followedCategoryIdsProvider = FutureProvider<Set<String>>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return {};
  return ref.watch(categoryRepositoryProvider).getFollowedCategoryIds(authUser.uid);
});

// Feed Provider with Deterministic Filtering
final feedQuestionsProvider = FutureProvider.family<List<QuestionModel>, String>((ref, feedType) async {
  final repo = ref.watch(questionRepositoryProvider);
  final authUser = ref.watch(authStateProvider).value;
  Set<String> followedIds = {};
  if (authUser != null && feedType == 'following') {
    followedIds = await ref.watch(categoryRepositoryProvider).getFollowedCategoryIds(authUser.uid);
  }
  return repo.fetchQuestions(
    feedType: feedType,
    followedCategoryIds: followedIds.toList(),
  );
});

// Comments Stream Provider
final commentsStreamProvider = StreamProvider.family<List<CommentModel>, String>((ref, targetId) {
  return ref.watch(commentRepositoryProvider).streamComments(targetId);
});

// Bookmarks / Collections
final bookmarkCollectionsProvider = FutureProvider.family<List<BookmarkCollectionModel>, String>((ref, uid) async {
  return ref.watch(bookmarkRepositoryProvider).getCollections(uid);
});

final savedQuestionsProvider = FutureProvider.family<List<QuestionModel>, String>((ref, uid) async {
  return ref.watch(bookmarkRepositoryProvider).getSavedQuestions(uid);
});

// Achievements and Stats
final userAchievementsProvider = FutureProvider.family<List<AchievementModel>, String>((ref, uid) async {
  return ref.watch(achievementRepositoryProvider).getAchievements(uid);
});

final userContributionStatsProvider = FutureProvider.family<ContributionStats, String>((ref, uid) async {
  return ref.watch(achievementRepositoryProvider).getContributionStats(uid);
});

// Notifications Provider
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).streamNotifications(authUser.uid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsStreamProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

// Theme Mode State Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await LocalStorageService.getThemeMode();
    if (mode == 'light') state = ThemeMode.light;
    else if (mode == 'dark') state = ThemeMode.dark;
    else state = ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final str = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
    await LocalStorageService.setThemeMode(str);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Locale State Notifier
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = await LocalStorageService.getLocale();
    state = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await LocalStorageService.setLocale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
