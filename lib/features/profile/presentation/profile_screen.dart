import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/models/question_model.dart';

final userProfileByIdProvider = FutureProvider.family<UserProfileModel?, String>((ref, uid) async {
  return ref.watch(authRepositoryProvider).getUserProfile(uid);
});

final userQuestionsProvider = FutureProvider.family<List<QuestionModel>, String>((ref, uid) async {
  return ref.watch(questionRepositoryProvider).fetchQuestions(
    feedType: 'user',
    authorUid: uid,
  );
});

final savedQuestionsListProvider = FutureProvider.family<List<QuestionModel>, String>((ref, uid) async {
  return ref.watch(questionRepositoryProvider).fetchSavedQuestions(uid);
});

class ProfileScreen extends ConsumerWidget {
  final String? targetUid;
  const ProfileScreen({super.key, this.targetUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).value;

    final effectiveUid = targetUid ?? authUser?.uid;

    if (effectiveUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined, size: 72, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text('Sign in to view your profile and questions'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('Sign In or Register'),
              ),
            ],
          ),
        ),
      );
    }

    final isCurrentUser = authUser?.uid == effectiveUid;
    final profileAsync = isCurrentUser
        ? ref.watch(currentProfileProvider)
        : ref.watch(userProfileByIdProvider(effectiveUid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'My Profile' : 'User Profile'),
        actions: [
          if (isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ],
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          return DefaultTabController(
            length: isCurrentUser ? 2 : 1,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                                child: profile.photoUrl == null
                                    ? Text(
                                        profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'U',
                                        style: TextStyle(fontSize: 28, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                                      )
                                    : null,
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
                                        // Reputation Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.18),
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
                                        const SizedBox(width: 8),
                                        // Role badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            profile.role.toUpperCase(),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSecondaryContainer),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(profile.bio!, style: theme.textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 16),
                          // Stats row
                          Row(
                            children: [
                              _ProfileStat(label: 'Questions', value: '${profile.questionCount}'),
                              const SizedBox(width: 24),
                              _ProfileStat(label: 'Answers', value: '${profile.answerCount}'),
                              const SizedBox(width: 24),
                              _ProfileStat(label: 'Followers', value: '${profile.followersCount}'),
                            ],
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit Profile & Avatar'),
                                onPressed: () => _showEditProfileDialog(context, ref, profile),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.outline,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: [
                          const Tab(text: 'Questions'),
                          if (isCurrentUser) const Tab(text: 'Saved'),
                        ],
                      ),
                      theme.colorScheme.surface,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _UserQuestionsTab(uid: effectiveUid),
                  if (isCurrentUser) _SavedQuestionsTab(uid: effectiveUid),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

class _UserQuestionsTab extends ConsumerWidget {
  final String uid;
  const _UserQuestionsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(userQuestionsProvider(uid));

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No questions posted yet.'));
        }

        return ListView.separated(
          itemCount: questions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final q = questions[index];
            return ListTile(
              title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(q.categoryName),
              trailing: Text('${q.answerCount} answers'),
              onTap: () => context.push('/question/${q.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading questions: $e')),
    );
  }
}

class _SavedQuestionsTab extends ConsumerWidget {
  final String uid;
  const _SavedQuestionsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedQuestionsListProvider(uid));

    return savedAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No saved questions.'));
        }

        return ListView.separated(
          itemCount: questions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final q = questions[index];
            return ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.blue),
              title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(q.categoryName),
              onTap: () => context.push('/question/${q.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading saved questions: $e')),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfileModel profile) {
  final nameController = TextEditingController(text: profile.displayName);
  final usernameController = TextEditingController(text: profile.username);
  final bioController = TextEditingController(text: profile.bio ?? '');
  final photoUrlController = TextEditingController(text: profile.photoUrl ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      bool isSaving = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Profile & Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar Image URL (HTTPS)',
                      hintText: 'https://images.unsplash.com/...',
                      border: OutlineInputBorder(),
                      helperText: 'Free Spark Architecture: direct image URL (no Cloud Storage needed)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final newName = nameController.text.trim();
                        final newBio = bioController.text.trim();
                        final newPhoto = photoUrlController.text.trim();

                        if (newName.length < 2) {
                          setModalState(() => errorMessage = 'Display name must be at least 2 characters.');
                          return;
                        }

                        if (newPhoto.isNotEmpty && !newPhoto.startsWith('https://')) {
                          setModalState(() => errorMessage = 'Avatar URL must start with https://');
                          return;
                        }

                        setModalState(() { isSaving = true; errorMessage = null; });

                        try {
                          await ref.read(authRepositoryProvider).updateProfile(
                            uid: profile.id,
                            displayName: newName,
                            username: profile.username,
                            bio: newBio.isEmpty ? null : newBio,
                            photoUrl: newPhoto.isEmpty ? null : newPhoto,
                          );
                          ref.invalidate(currentProfileProvider);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
