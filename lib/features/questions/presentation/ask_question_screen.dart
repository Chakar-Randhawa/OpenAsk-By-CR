import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/category_model.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final raw = _tagController.text.trim().replaceAll('#', '').toLowerCase();
    if (raw.isNotEmpty && !_tags.contains(raw) && _tags.length < 5) {
      setState(() {
        _tags.add(raw);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category for your question.');
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

      // Invalidate feeds so new question appears immediately
      ref.invalidate(feedQuestionsProvider('new'));
      ref.invalidate(feedQuestionsProvider('following'));

      if (mounted) {
        context.pushReplacement('/question/$questionId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to publish question: $e';
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
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Anonymous toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Post Anonymously', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Your public name and avatar will be hidden. Posts remain subject to community rules.',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: Icon(
                    _isAnonymous ? Icons.masks : Icons.person_outline,
                    color: _isAnonymous ? theme.colorScheme.primary : null,
                  ),
                  value: _isAnonymous,
                  onChanged: (val) => setState(() => _isAnonymous = val),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (cats) {
                  return DropdownButtonFormField<CategoryModel>(
                    decoration: InputDecoration(
                      hintText: 'Select a category (50 topics)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    value: _selectedCategory,
                    items: cats.map((cat) {
                      return DropdownMenuItem<CategoryModel>(
                        value: cat,
                        child: Text('${cat.icon}  ${cat.name}'),
                      );
                    }).toList(),
                    onChanged: (cat) => setState(() => _selectedCategory = cat),
                    validator: (val) => val == null ? 'Please select a category' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading categories: $err'),
              ),
              const SizedBox(height: 16),

              // Title input
              Text('Question Title', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 250,
                decoration: InputDecoration(
                  hintText: 'e.g., What is the most reliable way to handle offline sync in Flutter?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 8) {
                    return 'Title must be at least 8 characters long.';
                  }
                  if (val.trim().length > 250) {
                    return 'Title cannot exceed 250 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Body input
              Text('Details & Context', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 7,
                maxLength: 10000,
                decoration: InputDecoration(
                  hintText: 'Provide details, what you have tried, edge cases, and expected outcome...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 15) {
                    return 'Please provide more details (at least 15 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Tags input
              Text('Tags (up to 5)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      onSubmitted: (_) => _addTag(),
                      decoration: InputDecoration(
                        hintText: 'e.g. riverpod, firestore',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _tags.length < 5 ? _addTag : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
