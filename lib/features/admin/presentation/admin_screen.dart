import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/models/report_model.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';

final reportQueueProvider = FutureProvider<List<ReportModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getReportQueue();
});

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAuditLogs();
});

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    final theme = Theme.of(context);

    final isStaff = profile?.role == 'admin' || profile?.role == 'moderator';

    if (authUser == null || !isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff Dashboard')),
        body: const EmptyStateView(
          icon: Icons.security,
          title: 'Restricted Access',
          description: 'This console requires an authorized moderator or admin profile.',
        ),
      );
    }

    final reportsAsync = ref.watch(reportQueueProvider);
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation & Admin Console'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Reports Queue'),
            Tab(text: 'Audit Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Reports Queue
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportQueueProvider);
            },
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'Queue is Clean',
                    description: 'No pending user reports requiring moderation review.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final dateStr = DateFormat.yMMMd().format(report.createdAt);

                    return ListTile(
                      title: Text(
                        'Reported ${report.targetType.toUpperCase()}: ${report.reason}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.details.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Details: ${report.details}'),
                          ],
                          const SizedBox(height: 4),
                          Text('Reported on $dateStr • Target ID: ${report.targetId}',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          final adminRepo = ref.read(adminRepositoryProvider);
                          if (action == 'dismiss') {
                            await adminRepo.resolveReport(
                              reportId: report.id,
                              actionTaken: 'dismissed',
                              moderatorUid: authUser.uid,
                            );
                            ref.invalidate(reportQueueProvider);
                          } else if (action == 'remove') {
                            final confirmed = await ConfirmationDialog.show(
                              context: context,
                              title: 'Remove Content',
                              content: 'Remove this reported ${report.targetType} from public visibility?',
                              confirmLabel: 'Remove',
                              isDestructive: true,
                            );
                            if (confirmed) {
                              await adminRepo.removeContent(
                                targetType: report.targetType,
                                targetId: report.targetId,
                                reason: report.reason,
                                moderatorUid: authUser.uid,
                              );
                              await adminRepo.resolveReport(
                                reportId: report.id,
                                actionTaken: 'removed_content',
                                moderatorUid: authUser.uid,
                              );
                              ref.invalidate(reportQueueProvider);
                              ref.invalidate(auditLogsProvider);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'dismiss', child: Text('Dismiss Report')),
                          const PopupMenuItem(value: 'remove', child: Text('Remove Content', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading queue: $err')),
            ),
          ),

          // Tab 2: Audit Logs
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(auditLogsProvider);
            },
            child: auditLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.history,
                    title: 'No actions recorded yet',
                    description: 'Staff moderation actions will appear here in chronological order.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final dateStr = DateFormat.yMMMd().add_jm().format(log.createdAt);

                    return ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(log.action.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Target: ${log.targetType} (${log.targetId})\nReason: ${log.reason}\nTime: $dateStr'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading logs: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
