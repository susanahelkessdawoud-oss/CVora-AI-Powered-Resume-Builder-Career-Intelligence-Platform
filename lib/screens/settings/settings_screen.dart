import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import '../../providers/theme_manager.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;
  bool notificationsEnabled = true;
  bool loadingNotificationsPref = true;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    darkModeEnabled = _themeService.isDarkMode;
    PreferencesService.getNotificationsEnabled().then((value) {
      if (mounted) {
        setState(() {
          notificationsEnabled = value;
          loadingNotificationsPref = false;
        });
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      darkModeEnabled = value;
    });
    _themeService.setDarkMode(value);
  }

  void _toggleNotifications(bool value) {
    setState(() => notificationsEnabled = value);
    PreferencesService.setNotificationsEnabled(value);
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editProfile() async {
    final user = AuthService.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Display name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;
    try {
      await AuthService.instance.updateProfile(displayName: newName);
      if (mounted) {
        setState(() {});
        _msg('Profile updated.');
      }
    } catch (e) {
      _msg('Could not update profile: $e');
    }
  }

  Future<void> _changePassword() async {
    final user = AuthService.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      _msg('No email on this account.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
          'We\'ll send a password reset link to $email. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await AuthService.instance.resetPassword(email);
      _msg('Password reset link sent to $email.');
    } catch (e) {
      _msg('Could not send reset link: $e');
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CVORA',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.description_outlined, size: 40),
      children: const [
        SizedBox(height: 12),
        Text(
          'An AI-powered resume builder and career intelligence platform — '
          'build CVs, analyze and optimize them for the job you want, '
          'practice interviews, and get career guidance, all backed by '
          'Google Gemini.',
        ),
        SizedBox(height: 12),
        Text(
          'Graduation project — iSchool X / Orange Digital Center Mobile '
          'Development Track, in collaboration with NTI.',
        ),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Getting started',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Create a resume from scratch, or upload an existing CV and '
                'let AI extract it into an editable draft.',
              ),
              SizedBox(height: 12),
              Text(
                'AI tools',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'CV Analyzer, ATS Analyzer, Skills Intelligence, Job Matcher, '
                'CV Optimizer, Cover Letter, Interview Coach and Career '
                'Advisor are all on the home screen — each one works on a '
                'document you\'ve already created.',
              ),
              SizedBox(height: 12),
              Text(
                'Something not working?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Most errors come from a missing connection to the backend. '
                'Check your internet connection and try again.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              const Text(
                'Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(user?.displayName?.trim().isNotEmpty == true
                      ? user!.displayName!
                      : 'Profile'),
                  subtitle: Text(user?.email ?? 'Not logged in'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: _editProfile,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outlined),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: _changePassword,
                ),
              ),
              const SizedBox(height: 24),
              // Preferences Section
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: darkModeEnabled,
                    onChanged: _toggleDarkMode,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text(
                    'In-app reminders for completed analyses and exports',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: loadingNotificationsPref ? null : _toggleNotifications,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // About Section
              const Text(
                'About',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outlined),
                  title: const Text('About CVORA'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: _showAbout,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outlined),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: _showHelp,
                ),
              ),
              if (kDebugMode && !kIsWeb) ...[
                const SizedBox(height: 24),
                const Text(
                  'Debug',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Signed in as'),
                    subtitle: Text(user?.id ?? 'none'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => logout(context),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
