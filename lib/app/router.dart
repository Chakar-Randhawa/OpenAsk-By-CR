import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/feed/presentation/feed_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/questions/presentation/ask_question_screen.dart';
import '../features/questions/presentation/question_detail_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/categories/presentation/category_detail_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/achievements/presentation/achievements_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final unreadCount = ref.watch(unreadNotificationsCountProvider);

          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(state.uri.toString()),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/discover');
                    break;
                  case 2:
                    context.push('/ask');
                    break;
                  case 3:
                    context.go('/notifications');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Discover',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: 'Ask',
                ),
                NavigationDestination(
                  icon: unreadCount > 0
                      ? Badge(label: Text('$unreadCount'), child: const Icon(Icons.notifications_outlined))
                      : const Icon(Icons.notifications_outlined),
                  selectedIcon: unreadCount > 0
                      ? Badge(label: Text('$unreadCount'), child: const Icon(Icons.notifications))
                      : const Icon(Icons.notifications),
                  label: 'Alerts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/question/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return QuestionDetailScreen(questionId: id);
        },
      ),
      GoRoute(
        path: '/category/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CategoryDetailScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProfileScreen(targetUid: id);
        },
      ),
      GoRoute(
        path: '/ask',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AskQuestionScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/achievements/:uid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          return AchievementsScreen(uid: uid);
        },
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/discover')) return 1;
  if (location.startsWith('/notifications')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}
