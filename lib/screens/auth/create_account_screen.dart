import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      pass = TextEditingController(),
      confirm = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if ([name, email, pass, confirm].any((c) => c.text.trim().isEmpty)) {
      msg('Complete all fields.');
      return;
    }
    if (pass.text.length < 6) {
      msg('Password must be at least 6 characters.');
      return;
    }
    if (pass.text != confirm.text) {
      msg('Passwords do not match.');
      return;
    }
    setState(() => loading = true);
    try {
      final response = await AuthService().register(
        email.text.trim(),
        pass.text,
        displayName: name.text.trim(),
      );
      if (!mounted) return;

      if (response.session == null) {
        // Supabase requires email confirmation before a session is issued.
        msg('Account created! Check your email to confirm it, then log in.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (mounted) msg(e.message);
    } catch (e) {
      if (mounted) msg('Could not create account: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void msg(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));

  @override
  void dispose() {
    for (final c in [name, email, pass, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Text(
                'CVORA',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.purple,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Create Account',
              onPressed: register,
              isLoading: loading,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
