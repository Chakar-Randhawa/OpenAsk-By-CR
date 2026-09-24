import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/answer_model.dart';

final questionDetailProvider = FutureProvider.family<QuestionModel?, String>((ref, id) async {
  return ref.watch(questionRepositoryProvider).getQuestionById(id);
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
  bool _isSaved = false;

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
      if (authUser != null) {
        ref.read(questionRepositoryProvider).recordView(widget.questionId, authUser.uid);
      }
    });
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

  void _showReportDialog(String targetType, String targetId) {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    showDialog(
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
                  DropdownMenuItem(value: 'inappropriate', child: Text('Inappropriate content')),
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
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authUser = ref.read(authStateProvider).value;
                if (authUser == null) {
                  Navigator.pop(ctx);
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
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you. The report has been received.')),
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
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: 'Save Question',
            onPressed: () async {
              if (authUser == null) {
                context.push('/auth');
                return;
              }
              final repo = ref.read(questionRepositoryProvider);
              final newSaved = await repo.toggleSaveQuestion(widget.questionId, authUser.uid);
              setState(() => _isSaved = newSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(newSaved ? 'Question saved' : 'Question removed from saved')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'report') {
                _showReportDialog('question', widget.questionId);
              }
            },
            itemBuilder: (_) => [
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
                    // Category & Date
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.push('/category/${question.categoryId}'),
                          child: Chip(
                            label: Text(question.categoryName),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
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
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: (!question.isAnonymous && question.authorPhotoUrl != null)
                              ? NetworkImage(question.authorPhotoUrl!)
                              : null,
                          child: (question.isAnonymous || question.authorPhotoUrl == null)
                              ? Icon(question.isAnonymous ? Icons.masks : Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.isAnonymous ? 'Anonymous' : question.authorDisplayName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (!question.isAnonymous)
                              Text('Author', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
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
                      const SizedBox(height: 16),
                    ],

                    const Divider(),
                    const SizedBox(height: 8),

                    // Answers Section Header
                    answersAsync.when(
                      data: (answers) => Text(
                        '${answers.length} Answers',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                const Text('No answers yet. Share your knowledge!'),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: answers.map((answer) {
                            return _AnswerItemCard(
                              answer: answer,
                              question: question,
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
  final String? currentUid;
  final VoidCallback onReport;

  const _AnswerItemCard({
    required this.answer,
    required this.question,
    required this.currentUid,
    required this.onReport,
  });

  @override
  ConsumerState<_AnswerItemCard> createState() => _AnswerItemCardState();
}

class _AnswerItemCardState extends ConsumerState<_AnswerItemCard> {
  int _userVote = 0;
  int _netVoteCount = 0;
  bool _isLoadingVote = true;

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
      if (mounted) setState(() { _userVote = vote; _netVoteCount = count; _isLoadingVote = false; });
    } else {
      if (mounted) setState(() { _netVoteCount = count; _isLoadingVote = false; });
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
    final isQuestionAuthor = widget.currentUid == widget.question.authorUid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: widget.answer.isHelpful
          ? Colors.green.withOpacity(0.06)
          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
            // Helpful badge & Header
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: (!widget.answer.isAnonymous && widget.answer.authorPhotoUrl != null)
                      ? NetworkImage(widget.answer.authorPhotoUrl!)
                      : null,
                  child: (widget.answer.isAnonymous || widget.answer.authorPhotoUrl == null)
                      ? Icon(widget.answer.isAnonymous ? Icons.masks : Icons.person, size: 14)
                      : null,
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
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Helpful Solution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
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
                // Upvote button
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    size: 18,
                    color: _userVote == 1 ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                  tooltip: 'Upvote (+10 reputation)',
                  onPressed: () => _vote(1),
                ),
                Text(
                  '$_netVoteCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _userVote != 0 ? theme.colorScheme.primary : null,
                  ),
                ),
                // Downvote button
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    size: 18,
                    color: _userVote == -1 ? Colors.red : theme.colorScheme.outline,
                  ),
                  tooltip: 'Downvote (-2 reputation)',
                  onPressed: () => _vote(-1),
                ),
                const Spacer(),

                // Mark as helpful action (only for question author)
                if (isQuestionAuthor)
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
                        questionAuthorUid: widget.question.authorUid,
                      );
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
