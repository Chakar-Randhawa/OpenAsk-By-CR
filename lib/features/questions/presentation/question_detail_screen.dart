import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/answer_model.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/widgets/app_avatar.dart';

final questionDetailProvider = FutureProvider.family<QuestionModel?, String>((ref, id) async {
  final authUser = ref.watch(authStateProvider).value;
  return ref.watch(questionRepositoryProvider).getQuestionById(id, viewerUid: authUser?.uid);
});

final answersStreamProvider = StreamProvider.family<List<AnswerModel>, String>((ref, questionId) {
  return ref.watch(answerRepositoryProvider).streamAnswers(questionId);
});

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isAnswerAnonymous = false;
  bool _isSubmittingAnswer = false;
  bool _isQuestionAuthor = false;
  bool _checkedOwnership = false;

  @override
  void initState() {
    super.initState();
    _recordView();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _recordView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = ref.read(authStateProvider).value;
      ref.read(questionRepositoryProvider).recordView(widget.questionId, authUser?.uid);
      AnalyticsService.logQuestionViewed(widget.questionId);
    });
  }

  Future<void> _checkOwnership(String currentUid) async {
    if (_checkedOwnership) return;
    final repo = ref.read(questionRepositoryProvider);
    final isOwner = await repo.isQuestionOwner(widget.questionId, currentUid);
    if (mounted) {
      setState(() {
        _isQuestionAuthor = isOwner;
        _checkedOwnership = true;
      });
    }
  }

  Future<void> _submitAnswer(QuestionModel question) async {
    final text = _answerController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer must be at least 5 characters long.')),
      );
      return;
    }

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      context.push('/auth');
      return;
    }

    final profile = await ref.read(currentProfileProvider.future);
    final authorDisplayName = profile?.displayName ?? authUser.displayName ?? 'Member';

    setState(() => _isSubmittingAnswer = true);

    try {
      final answerRepo = ref.read(answerRepositoryProvider);
      await answerRepo.createAnswer(
        questionId: question.id,
        authorUid: authUser.uid,
        authorDisplayName: authorDisplayName,
        authorPhotoUrl: profile?.photoUrl ?? authUser.photoURL,
        isAnonymous: _isAnswerAnonymous,
        body: text,
      );

      await AnalyticsService.logAnswerCreated(
        questionId: question.id,
        isAnonymous: _isAnswerAnonymous,
      );

      _answerController.clear();
      setState(() {
        _isSubmittingAnswer = false;
        _isAnswerAnonymous = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingAnswer = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post answer: $e')),
        );
      }
    }
  }

  void _shareQuestion() {
    final url = DeepLinkService.buildQuestionUrl(widget.questionId);
    Clipboard.setData(ClipboardData(text: url));
    AnalyticsService.logQuestionShared(widget.questionId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link copied to clipboard: $url')),
    );
  }

  void _showAddCommentDialog(String targetType, String targetId) {
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Clarify or inquire respectfully...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authUser = ref.read(authStateProvider).value;
              if (authUser == null) {
                Navigator.of(ctx).pop();
                context.push('/auth');
                return;
              }
              final text = commentController.text.trim();
              if (text.length >= 2) {
                final profile = await ref.read(currentProfileProvider.future);
                final repo = ref.read(commentRepositoryProvider);
                await repo.addComment(
                  targetType: targetType,
                  targetId: targetId,
                  authorUid: authUser.uid,
                  authorDisplayName: profile?.displayName ?? 'Member',
                  authorPhotoUrl: profile?.photoUrl,
                  text: text,
                );
                if (mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Comment'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String targetType, String targetId) {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Report $targetType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'spam', child: Text('Spam or advertising')),
                  DropdownMenuItem(value: 'harassment', child: Text('Harassment or hate speech')),
                  DropdownMenuItem(value: 'misinformation', child: Text('Misinformation')),
                  DropdownMenuItem(value: 'nsfw', child: Text('Inappropriate / NSFW')),
                  DropdownMenuItem(value: 'copyright', child: Text('Copyright violation')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authUser = ref.read(authStateProvider).value;
                if (authUser == null) {
                  Navigator.of(ctx).pop();
                  context.push('/auth');
                  return;
                }
                final modRepo = ref.read(moderationRepositoryProvider);
                await modRepo.submitReport(
                  reporterUid: authUser.uid,
                  targetType: targetType,
                  targetId: targetId,
                  reason: selectedReason,
                  details: detailsController.text,
                );
                await AnalyticsService.logReportCreated(targetType);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report received for moderation review.')),
                  );
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionAsync = ref.watch(questionDetailProvider(widget.questionId));
    final answersAsync = ref.watch(answersStreamProvider(widget.questionId));
    final commentsAsync = ref.watch(commentsStreamProvider(widget.questionId));
    final authUser = ref.watch(authStateProvider).value;

    if (authUser != null && !_checkedOwnership) {
      _checkOwnership(authUser.uid);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Question Link',
            onPressed: _shareQuestion,
          ),
          questionAsync.when(
            data: (q) => IconButton(
              icon: Icon(q?.isSaved == true ? Icons.bookmark : Icons.bookmark_border),
              tooltip: 'Save Question',
              onPressed: () async {
                if (authUser == null) {
                  context.push('/auth');
                  return;
                }
                final repo = ref.read(questionRepositoryProvider);
                final saved = await repo.toggleSaveQuestion(widget.questionId, authUser.uid);
                ref.invalidate(questionDetailProvider(widget.questionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(saved ? 'Question saved' : 'Removed from saved')),
                );
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'report') {
                _showReportDialog('question', widget.questionId);
              } else if (val == 'close' && _isQuestionAuthor) {
                final repo = ref.read(questionRepositoryProvider);
                await repo.updateQuestionStatus(
                  questionId: widget.questionId,
                  userUid: authUser!.uid,
                  newStatus: 'closed',
                );
                ref.invalidate(questionDetailProvider(widget.questionId));
              } else if (val == 'resolve' && _isQuestionAuthor) {
                final repo = ref.read(questionRepositoryProvider);
                await repo.updateQuestionStatus(
                  questionId: widget.questionId,
                  userUid: authUser!.uid,
                  newStatus: 'resolved',
                );
                ref.invalidate(questionDetailProvider(widget.questionId));
              }
            },
            itemBuilder: (_) => [
              if (_isQuestionAuthor) ...[
                const PopupMenuItem(value: 'resolve', child: Text('Mark as Resolved')),
                const PopupMenuItem(value: 'close', child: Text('Close Question')),
              ],
              const PopupMenuItem(value: 'report', child: Text('Report Question')),
            ],
          ),
        ],
      ),
      body: questionAsync.when(
        data: (question) {
          if (question == null) {
            return const Center(child: Text('Question not found or deleted.'));
          }

          final formattedDate = DateFormat.yMMMd().format(question.createdAt);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Category & Status
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.push('/category/${question.categoryId}'),
                          child: Chip(
                            label: Text(question.categoryName),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (question.status == 'resolved') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Resolved',
                                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ] else if (question.status == 'closed') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Closed',
                                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const Spacer(),
                        Text(formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      question.title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Author info
                    Row(
                      children: [
                        AppAvatar(
                          photoUrl: question.authorPhotoUrl,
                          displayName: question.authorDisplayName,
                          isAnonymous: question.isAnonymous,
                          radius: 16,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.isAnonymous ? 'Anonymous' : question.authorDisplayName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              question.isAnonymous ? 'Verified Private Author' : 'Question Author',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Body
                    Text(
                      question.body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (question.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children: question.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Comments on question
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.mode_comment_outlined, size: 16),
                          label: const Text('Add Clarification Comment'),
                          onPressed: () => _showAddCommentDialog('question', question.id),
                        ),
                      ],
                    ),

                    commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) return const SizedBox();
                        return Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: comments.map((c) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('• ${c.authorDisplayName}: ${c.text}',
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),

                    const Divider(),
                    const SizedBox(height: 12),

                    // Answers Section Header
                    answersAsync.when(
                      data: (answers) => Row(
                        children: [
                          Text(
                            '${answers.length} Answers',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      loading: () => const Text('Loading answers...'),
                      error: (e, _) => Text('Error loading answers: $e'),
                    ),
                    const SizedBox(height: 12),

                    // Answers List
                    answersAsync.when(
                      data: (answers) {
                        if (answers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.outline),
                                const SizedBox(height: 8),
                                const Text('No answers yet. Share your expertise!'),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: answers.map((answer) {
                            return _AnswerItemCard(
                              answer: answer,
                              question: question,
                              isQuestionAuthor: _isQuestionAuthor,
                              currentUid: authUser?.uid,
                              onReport: () => _showReportDialog('answer', answer.id),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),

              // Answer Input Bottom Bar
              if (question.status == 'active')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _isAnswerAnonymous,
                              onChanged: (v) => setState(() => _isAnswerAnonymous = v ?? false),
                            ),
                            const Text('Answer anonymously', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _answerController,
                                maxLines: 4,
                                minLines: 1,
                                decoration: const InputDecoration(
                                  hintText: 'Write a helpful answer...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSubmittingAnswer ? null : () => _submitAnswer(question),
                              child: _isSubmittingAnswer
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Post'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    'This question is ${question.status}. New answers are disabled.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading question: $err')),
      ),
    );
  }
}

class _AnswerItemCard extends ConsumerStatefulWidget {
  final AnswerModel answer;
  final QuestionModel question;
  final bool isQuestionAuthor;
  final String? currentUid;
  final VoidCallback onReport;

  const _AnswerItemCard({
    required this.answer,
    required this.question,
    required this.isQuestionAuthor,
    required this.currentUid,
    required this.onReport,
  });

  @override
  ConsumerState<_AnswerItemCard> createState() => _AnswerItemCardState();
}

class _AnswerItemCardState extends ConsumerState<_AnswerItemCard> {
  int _userVote = 0;
  int _netVoteCount = 0;

  @override
  void initState() {
    super.initState();
    _netVoteCount = widget.answer.voteCount;
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    final answerRepo = ref.read(answerRepositoryProvider);
    final count = await answerRepo.getAnswerVoteCount(widget.answer.id);
    if (widget.currentUid != null) {
      final vote = await answerRepo.getUserVote(widget.answer.id, widget.currentUid!);
      if (mounted) setState(() { _userVote = vote; _netVoteCount = count; });
    } else {
      if (mounted) setState(() => _netVoteCount = count);
    }
  }

  Future<void> _vote(int value) async {
    if (widget.currentUid == null) {
      context.push('/auth');
      return;
    }
    final answerRepo = ref.read(answerRepositoryProvider);
    final result = await answerRepo.voteAnswer(
      answerId: widget.answer.id,
      uid: widget.currentUid!,
      voteValue: value,
    );
    final newCount = await answerRepo.getAnswerVoteCount(widget.answer.id);
    if (mounted) setState(() { _userVote = result; _netVoteCount = newCount; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: widget.answer.isHelpful
          ? Colors.green.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.answer.isHelpful ? Colors.green.shade300 : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  photoUrl: widget.answer.authorPhotoUrl,
                  displayName: widget.answer.authorDisplayName,
                  isAnonymous: widget.answer.isAnonymous,
                  radius: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.answer.isAnonymous ? 'Anonymous' : widget.answer.authorDisplayName,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.answer.isHelpful)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Helpful Solution',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) {
                    if (val == 'report') widget.onReport();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'report', child: Text('Report Answer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Answer body
            Text(widget.answer.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 12),

            // Footer: Voting and Helpful toggle
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    size: 18,
                    color: _userVote == 1 ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                  tooltip: 'Upvote',
                  onPressed: () => _vote(1),
                ),
                Text(
                  '$_netVoteCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _userVote != 0 ? theme.colorScheme.primary : null,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    size: 18,
                    color: _userVote == -1 ? Colors.red : theme.colorScheme.outline,
                  ),
                  tooltip: 'Downvote',
                  onPressed: () => _vote(-1),
                ),
                const Spacer(),

                // Mark as helpful action (only for question author)
                if (widget.isQuestionAuthor)
                  TextButton.icon(
                    icon: Icon(
                      widget.answer.isHelpful ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.answer.isHelpful ? Colors.green : theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text(
                      widget.answer.isHelpful ? 'Helpful Solution' : 'Mark as Helpful',
                      style: TextStyle(
                        color: widget.answer.isHelpful ? Colors.green : theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () async {
                      final answerRepo = ref.read(answerRepositoryProvider);
                      await answerRepo.markAnswerHelpful(
                        questionId: widget.question.id,
                        answerId: widget.answer.id,
                        questionAuthorUid: widget.currentUid ?? '',
                      );
                      ref.invalidate(questionDetailProvider(widget.question.id));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
