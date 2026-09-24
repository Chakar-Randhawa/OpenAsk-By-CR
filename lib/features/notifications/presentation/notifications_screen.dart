import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).value;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text('Sign in to view your notifications'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final notifRepo = ref.read(notificationRepositoryProvider);
              await notifRepo.markAllAsRead(authUser.uid);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'You will be notified when people answer your questions or post in followed categories.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final dateStr = DateFormat.MMMd().add_jm().format(notif.createdAt);

              IconData icon = Icons.notifications;
              Color iconColor = theme.colorScheme.primary;

              if (notif.type == 'helpful') {
                icon = Icons.check_circle;
                iconColor = Colors.green;
              } else if (notif.type == 'answer') {
                icon = Icons.chat_bubble;
                iconColor = Colors.blue;
              } else if (notif.type == 'category_question') {
                icon = Icons.explore;
                iconColor = Colors.orange;
              }

              return ListTile(
                tileColor: notif.isRead ? null : theme.colorScheme.primary.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif.body),
                    const SizedBox(height: 4),
                    Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11)),
                  ],
                ),
                onTap: () async {
                  if (!notif.isRead) {
                    final notifRepo = ref.read(notificationRepositoryProvider);
                    await notifRepo.markAsRead(notif.id);
                  }
                  if (notif.targetType == 'question' && notif.targetId.isNotEmpty) {
                    context.push('/question/${notif.targetId}');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading notifications: $err')),
      ),
    );
  }
}
