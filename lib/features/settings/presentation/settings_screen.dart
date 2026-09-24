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

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Answer Alerts'),
            subtitle: const Text('Receive push alerts when someone answers your question'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          if (authUser != null) ...[
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Address'),
              subtitle: Text(authUser.email ?? 'No email associated'),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('User ID'),
              subtitle: Text(authUser.uid, style: const TextStyle(fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Role'),
              subtitle: Text(profile?.role.toUpperCase() ?? 'MEMBER'),
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
            child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('OpenAsk'),
            subtitle: Text('Version 1.0.0 (Production Architecture)'),
          ),
        ],
      ),
    );
  }
}
