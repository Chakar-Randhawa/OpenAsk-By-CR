import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/validators.dart';

class AskQuestionScreen extends ConsumerStatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  ConsumerState<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends ConsumerState<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();

  CategoryModel? _selectedCategory;
  bool _isAnonymous = false;
  final List<String> _tags = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  List<QuestionModel> _similarQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final draft = await LocalStorageService.getQuestionDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = (draft['title'] as String?) ?? '';
        _bodyController.text = (draft['body'] as String?) ?? '';
        _isAnonymous = (draft['isAnonymous'] as bool?) ?? false;
        final savedTags = draft['tags'] as List<dynamic>?;
        if (savedTags != null) {
          _tags.addAll(savedTags.map((e) => e.toString()));
        }
      });
    }
  }

  Future<void> _saveDraft() async {
    await LocalStorageService.saveQuestionDraft(
      title: _titleController.text,
      body: _bodyController.text,
      categoryId: _selectedCategory?.id,
      tags: _tags,
      isAnonymous: _isAnonymous,
    );
  }

  void _addTag() {
    final raw = _tagController.text.trim().replaceAll('#', '').toLowerCase();
    if (raw.isNotEmpty && !_tags.contains(raw) && _tags.length < 5) {
      setState(() {
        _tags.add(raw);
        _tagController.clear();
      });
      _saveDraft();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _saveDraft();
  }

  Future<void> _checkForSimilarQuestions() async {
    if (_titleController.text.trim().length < 8 || _selectedCategory == null) return;
    try {
      final repo = ref.read(questionRepositoryProvider);
      final similar = await repo.findSimilarQuestions(
        title: _titleController.text.trim(),
        categoryId: _selectedCategory!.id,
      );
      if (mounted) {
        setState(() {
          _similarQuestions = similar;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a topic category for your question.');
      return;
    }

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      context.push('/auth');
      return;
    }

    final profile = await ref.read(currentProfileProvider.future);
    final authorDisplayName = profile?.displayName ?? authUser.displayName ?? 'Member';

    setState(() => _isSubmitting = true);

    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final questionId = await questionRepo.createQuestion(
        authorUid: authUser.uid,
        authorDisplayName: authorDisplayName,
        authorPhotoUrl: profile?.photoUrl ?? authUser.photoURL,
        isAnonymous: _isAnonymous,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        tags: _tags,
      );

      // Clear draft on successful submit
      await LocalStorageService.clearQuestionDraft();

      // Log analytics
      await AnalyticsService.logQuestionCreated(
        categoryId: _selectedCategory!.id,
        isAnonymous: _isAnonymous,
        tagCount: _tags.length,
      );

      // Invalidate feeds
      ref.invalidate(feedQuestionsProvider('new'));
      ref.invalidate(feedQuestionsProvider('following'));

      if (mounted) {
        context.pushReplacement('/question/$questionId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to publish: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Anonymous posting switch
              Card(
                child: SwitchListTile(
                  title: const Text('Post Anonymously', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Your identity and UID are never exposed in public documents.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isAnonymous,
                  onChanged: (v) {
                    setState(() => _isAnonymous = v);
                    _saveDraft();
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<CategoryModel>(
                    decoration: const InputDecoration(
                      labelText: 'Select Topic Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    initialValue: _selectedCategory,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (cat) {
                      setState(() => _selectedCategory = cat);
                      _checkForSimilarQuestions();
                      _saveDraft();
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: 16),

              // Question Title
              TextFormField(
                controller: _titleController,
                validator: Validators.questionTitle,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: 'Question Title',
                  hintText: 'What would you like to inquire about?',
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (v) {
                  _saveDraft();
                  if (v.length > 8 && _selectedCategory != null) {
                    _checkForSimilarQuestions();
                  }
                },
              ),

              // Similar questions alert if detected
              if (_similarQuestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Similar questions already exist:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._similarQuestions.map(
                        (sq) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            onTap: () => context.push('/question/${sq.id}'),
                            child: Text(
                              '• ${sq.title}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Question Body
              TextFormField(
                controller: _bodyController,
                validator: Validators.questionBody,
                maxLines: 8,
                minLines: 4,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: 'Question Details',
                  hintText: 'Provide context, background, and what you have already tried...',
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _saveDraft(),
              ),
              const SizedBox(height: 16),

              // Tags input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add Tag (e.g. flutter, privacy)',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add tag',
                    onPressed: _addTag,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((t) {
                    return Chip(
                      label: Text('#$t'),
                      onDeleted: () => _removeTag(t),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
