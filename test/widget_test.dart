import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openask/core/widgets/app_avatar.dart';
import 'package:openask/core/widgets/stat_badge.dart';
import 'package:openask/core/widgets/loading_skeleton.dart';
import 'package:openask/core/widgets/empty_state_view.dart';
import 'package:openask/core/widgets/error_state_view.dart';

void main() {
  group('Core UI Widgets Test Suite', () {
    testWidgets('AppAvatar renders anonymous mask icon when isAnonymous is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              displayName: 'John Doe',
              isAnonymous: true,
              radius: 20,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.masks_outlined), findsOneWidget);
    });

    testWidgets('AppAvatar renders initials when no image URL provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              displayName: 'Sarah Connor',
              isAnonymous: false,
              radius: 20,
            ),
          ),
        ),
      );

      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('StatBadge renders counts and label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(
              icon: Icons.chat_bubble_outline,
              count: '42',
              label: 'answers',
              isHighlighted: true,
            ),
          ),
        ),
      );

      expect(find.text('42 answers'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, description, and button', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'Empty Box',
              description: 'Nothing here yet.',
              buttonText: 'Action',
              onButtonPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty Box'), findsOneWidget);
      expect(find.text('Nothing here yet.'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);

      await tester.tap(find.text('Action'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorStateView renders retry button and handles tap', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              message: 'Failed to connect',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('LoadingSkeleton renders with given dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });
  });
}
