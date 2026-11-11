import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool loading = false;
  bool rememberMe = true;

  @override
  void initState() {
    super.initState();
    _restoreSavedEmail();
  }

  Future<void> _restoreSavedEmail() async {
    final remember = await PreferencesService.getRememberMe();
    final savedEmail = await PreferencesService.getSavedEmail();
    if (!mounted) return;
    setState(() {
      rememberMe = remember;
      if (savedEmail != null) email.text = savedEmail;
    });
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      msg('Enter email and password.');
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().login(email.text.trim(), password.text);
      await PreferencesService.setRememberMe(
        rememberMe,
        email: email.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (mounted) msg(e.message);
    } catch (e) {
      if (mounted) msg('Login failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void msg(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Center(
              child: Text(
                'CVORA',
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.purple,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 35),
            const Text(
              'Welcome back 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login to your CVORA account',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (value) =>
                      setState(() => rememberMe = value ?? true),
                ),
                GestureDetector(
                  onTap: () => setState(() => rememberMe = !rememberMe),
                  child: const Text('Remember me'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Login', onPressed: login, isLoading: loading),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAccountScreen(),
                  ),
                ),
                child: const Text("Don't have an account? Sign up"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
