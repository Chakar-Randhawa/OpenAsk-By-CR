import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';

final userProfileByIdProvider = FutureProvider.family<UserProfileModel?, String>((ref, uid) async {
  return ref.watch(authRepositoryProvider).getUserProfile(uid);
});

final userQuestionsProvider = FutureProvider.family<List<QuestionModel>, String>((ref, uid) async {
  return ref.watch(questionRepositoryProvider).fetchQuestions(
    feedType: 'user',
    authorUid: uid,
  );
});

final isFollowingUserProvider = FutureProvider.family<bool, String>((ref, targetUid) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return false;
  return ref.watch(authRepositoryProvider).isFollowingUser(authUser.uid, targetUid);
});

class ProfileScreen extends ConsumerWidget {
  final String? targetUid;
  const ProfileScreen({super.key, this.targetUid});

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, UserProfileModel profile) {
    final nameController = TextEditingController(text: profile.displayName);
    final usernameController = TextEditingController(text: profile.username);
    final bioController = TextEditingController(text: profile.bio ?? '');
    final avatarController = TextEditingController(text: profile.photoUrl ?? '');
    final countryController = TextEditingController(text: profile.country ?? '');
    final websiteController = TextEditingController(text: profile.website ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username (unique)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: avatarController,
                decoration: const InputDecoration(
                  labelText: 'Avatar Image URL (HTTPS)',
                  hintText: 'https://example.com/avatar.jpg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country / Region'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(labelText: 'Website / Portfolio Link'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final authRepo = ref.read(authRepositoryProvider);
                      await authRepo.updateProfile(
                        uid: profile.id,
                        displayName: nameController.text.trim(),
                        username: usernameController.text.trim(),
                        bio: bioController.text.trim(),
                        photoUrl: avatarController.text.trim().isEmpty ? null : avatarController.text.trim(),
                        country: countryController.text.trim(),
                        website: websiteController.text.trim(),
                      );
                      ref.invalidate(currentProfileProvider);
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).value;
    final effectiveUid = targetUid ?? authUser?.uid;

    if (effectiveUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyStateView(
          icon: Icons.account_circle_outlined,
          title: 'Sign in to access profile',
          description: 'Sign in to view your questions, reputation score, and contribution history.',
          buttonText: 'Sign In or Register',
          onButtonPressed: () => context.push('/auth'),
        ),
      );
    }

    final isCurrentUser = authUser?.uid == effectiveUid;
    final profileAsync = isCurrentUser
        ? ref.watch(currentProfileProvider)
        : ref.watch(userProfileByIdProvider(effectiveUid));
    final isFollowingAsync = isCurrentUser
        ? const AsyncValue.data(false)
        : ref.watch(isFollowingUserProvider(effectiveUid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'My Profile' : 'Member Profile'),
        actions: [
          if (isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.military_tech_outlined),
              tooltip: 'Trust & Badges',
              onPressed: () => context.push('/achievements/$effectiveUid'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'block') {
                  final confirmed = await ConfirmationDialog.show(
                    context: context,
                    title: 'Block User',
                    content: 'Block this user? You will not see their content or receive alerts.',
                    confirmLabel: 'Block',
                    isDestructive: true,
                  );
                  if (confirmed && authUser != null) {
                    final modRepo = ref.read(moderationRepositoryProvider);
                    await modRepo.blockUser(authUser.uid, effectiveUid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User blocked.')),
                    );
                  }
                } else if (val == 'mute') {
                  if (authUser != null) {
                    final modRepo = ref.read(moderationRepositoryProvider);
                    await modRepo.muteUser(authUser.uid, effectiveUid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User muted.')),
                    );
                  }
                } else if (val == 'report') {
                  if (authUser != null) {
                    final modRepo = ref.read(moderationRepositoryProvider);
                    await modRepo.submitReport(
                      reporterUid: authUser.uid,
                      targetType: 'user',
                      targetId: effectiveUid,
                      reason: 'profile_violation',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile report submitted.')),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'mute', child: Text('Mute User')),
                const PopupMenuItem(value: 'block', child: Text('Block User')),
                const PopupMenuItem(value: 'report', child: Text('Report Profile')),
              ],
            ),
          ],
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar & Basic Info
              Row(
                children: [
                  AppAvatar(
                    photoUrl: profile.photoUrl,
                    displayName: profile.displayName,
                    radius: 36,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${profile.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Verifiable Reputation Pill
                            InkWell(
                              onTap: () => context.push('/achievements/$effectiveUid'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profile.reputation} rep',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                Text(profile.bio!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],

              // Metadata row: Country & Website
              if (profile.country != null || profile.website != null) ...[
                Row(
                  children: [
                    if (profile.country != null) ...[
                      Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(profile.country!, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                    ],
                    if (profile.website != null) ...[
                      Icon(Icons.link, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(profile.website!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Stats Row
              Row(
                children: [
                  _ProfileStat(label: 'Questions', value: '${profile.questionCount}'),
                  const SizedBox(width: 24),
                  _ProfileStat(label: 'Answers', value: '${profile.answerCount}'),
                  const SizedBox(width: 24),
                  _ProfileStat(label: 'Followers', value: '${profile.followersCount}'),
                  const SizedBox(width: 24),
                  _ProfileStat(label: 'Following', value: '${profile.followingCount}'),
                ],
              ),
              const SizedBox(height: 16),

              if (isCurrentUser) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile & Avatar'),
                    onPressed: () => _showEditProfileSheet(context, ref, profile),
                  ),
                ),
              ] else ...[
                isFollowingAsync.when(
                  data: (isFollowing) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary,
                        foregroundColor: isFollowing ? theme.colorScheme.onSurfaceVariant : Colors.white,
                      ),
                      onPressed: () async {
                        if (authUser == null) {
                          context.push('/auth');
                          return;
                        }
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.followUser(authUser.uid, effectiveUid);
                        ref.invalidate(isFollowingUserProvider(effectiveUid));
                        ref.invalidate(userProfileByIdProvider(effectiveUid));
                      },
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],

              const Divider(height: 32),

              // Questions by user section
              Text(
                'Questions by ${profile.displayName}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ref.watch(userQuestionsProvider(effectiveUid)).when(
                data: (questions) {
                  if (questions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No public questions published yet.')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return ListTile(
                        title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${q.answerCount} answers • ${q.categoryName}'),
                        onTap: () => context.push('/question/${q.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading questions: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
