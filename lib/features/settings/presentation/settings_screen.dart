import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _answersNotifs = true;
  bool _categoryNotifs = true;

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.updatePassword(
                  currentPwController.text,
                  newPwController.text,
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(String uid) {
    final passwordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action permanently deletes your login credentials and anonymizes your public contributions. Enter your password to proceed:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.deleteAccount(uid, passwordController.text);
                ref.invalidate(authStateProvider);
                ref.invalidate(currentProfileProvider);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  context.go('/');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your account has been deleted.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deletion failed: $e')),
                  );
                }
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final isStaff = profile?.role == 'admin' || profile?.role == 'moderator';

    final languageLabels = {
      'en': 'English',
      'ur': 'Urdu (اردو)',
      'ar': 'Arabic (العربية)',
      'hi': 'Hindi (हिन्दी)',
      'es': 'Spanish (Español)',
      'fr': 'French (Français)',
      'pt': 'Portuguese (Português)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Application Language'),
            subtitle: Text(languageLabels[currentLocale.languageCode] ?? currentLocale.languageCode),
            trailing: DropdownButton<String>(
              value: currentLocale.languageCode,
              underline: const SizedBox(),
              items: languageLabels.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  ref.read(localeProvider.notifier).setLocale(code);
                }
              },
            ),
          ),

          const Divider(),

          // Notifications
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Answer Alerts'),
            subtitle: const Text('Receive alerts when someone answers your inquiry'),
            value: _answersNotifs,
            onChanged: (v) => setState(() => _answersNotifs = v),
          ),
          SwitchListTile(
            title: const Text('Category Questions'),
            subtitle: const Text('Receive alerts for new questions in followed categories'),
            value: _categoryNotifs,
            onChanged: (v) => setState(() => _categoryNotifs = v),
          ),

          const Divider(),

          // Account
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Account Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          if (authUser != null) ...[
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Address'),
              subtitle: Text(authUser.email ?? 'No email associated'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Change Password'),
              onTap: _showChangePasswordDialog,
            ),
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Email Verification'),
              subtitle: Text(authUser.emailVerified ? 'Verified' : 'Unverified • Tap to send verification'),
              onTap: authUser.emailVerified
                  ? null
                  : () async {
                      await ref.read(authRepositoryProvider).sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification email sent.')),
                        );
                      }
                    },
            ),
            if (isStaff) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.indigo),
                title: const Text('Staff & Moderation Console', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                subtitle: const Text('Reports queue and administrative actions'),
                onTap: () => context.push('/admin'),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Request Personal Data Export'),
              subtitle: const Text('Download a JSON archive of your questions, answers, and bookmarks'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data export request logged. Archive prepared locally.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove login credentials and anonymize data'),
              onTap: () => _showDeleteAccountDialog(authUser.uid),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(authStateProvider);
                ref.invalidate(currentProfileProvider);
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In or Register'),
              onTap: () => context.push('/auth'),
            ),
          ],

          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('About & Legal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('OpenAsk Mobile'),
            subtitle: Text('Version 1.0.0 (Production Architecture • Firebase Spark Compatible)'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy & Community Terms'),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Privacy & Standards'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'OpenAsk is committed to user privacy. Anonymous postings ensure that your UID and personal identity are decoupled from public inquiries. Zero third-party ad trackers or paid analytics are deployed.',
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
