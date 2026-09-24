import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/categories_data.dart';

/// Clean, multi-step onboarding flow for new OpenAsk members.
/// Guides through interests, category preferences, language, and setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Set<String> _selectedCategoryIds = {};
  String _selectedLanguage = 'en';

  final List<String> _languages = [
    'en', // English
    'ur', // Urdu
    'ar', // Arabic
    'hi', // Hindi
    'es', // Spanish
    'fr', // French
    'pt', // Portuguese
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser != null) {
      final catRepo = ref.read(categoryRepositoryProvider);
      for (final catId in _selectedCategoryIds) {
        await catRepo.followCategory(catId, authUser.uid);
      }
      ref.invalidate(followedCategoryIdsProvider);
    }
    await ref.read(localeProvider.notifier).setLocale(_selectedLanguage);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to OpenAsk'),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildWelcomeStep(theme),
                _buildCategoriesStep(theme),
                _buildLanguageStep(theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(_currentPage == 2 ? 'Get Started' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'A Global Social Knowledge Network',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ask genuine questions, exchange insights with curious minds worldwide, or post anonymously with verified privacy.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your interests',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Select topics to populate your personalized feed.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: kInitialCategories.length,
              itemBuilder: (context, index) {
                final cat = kInitialCategories[index];
                final isSelected = _selectedCategoryIds.contains(cat.id);

                return CheckboxListTile(
                  title: Text(cat.name),
                  subtitle: Text(cat.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCategoryIds.add(cat.id);
                      } else {
                        _selectedCategoryIds.remove(cat.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep(ThemeData theme) {
    final languageNames = {
      'en': 'English',
      'ur': 'Urdu (اردو)',
      'ar': 'Arabic (العربية)',
      'hi': 'Hindi (हिन्दी)',
      'es': 'Spanish (Español)',
      'fr': 'French (Français)',
      'pt': 'Portuguese (Português)',
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Language',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the primary language for your interface.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final code = _languages[index];
                final isSelected = _selectedLanguage == code;
                return ListTile(
                  title: Text(languageNames[code] ?? code),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () {
                    setState(() => _selectedLanguage = code);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
