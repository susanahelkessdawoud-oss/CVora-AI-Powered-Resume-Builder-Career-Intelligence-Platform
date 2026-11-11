import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';

/// Appearance (persistent dark mode), account info, and sign-out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Appearance',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance,
              builder: (context, mode, _) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System default'),
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 32),
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Signed in as'),
              subtitle: Text(auth.currentUser?.email ?? 'Unknown'),
            ),
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Log out',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  // Return to the gate; the auth stream shows Login.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
            const Divider(height: 32),
            Text('About', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('CareerCraft'),
              subtitle: Text('Version 1.0.0'),
            ),
          ],
        ),
      ),
    );
  }

  void _set(ThemeMode? mode) {
    if (mode != null) ThemeController.instance.setMode(mode);
  }
}
