import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/user_profile_model.dart';
import '../core/models/question_model.dart';
import '../core/models/category_model.dart';
import '../core/models/notification_model.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/questions/data/question_repository.dart';
import '../features/answers/data/answer_repository.dart';
import '../features/categories/data/category_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/moderation/data/moderation_repository.dart';

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

// Feed Provider
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
