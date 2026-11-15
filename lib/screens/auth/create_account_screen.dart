import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cvora_mark.dart';
import '../../widgets/primary_button.dart';
import 'career_goals_screen.dart';

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
  bool agreedToTerms = false;
  bool obscurePass = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    pass.addListener(() => setState(() {}));
  }

  // 0-4: empty, weak, fair, good, strong.
  int get _strength {
    final p = pass.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(1, 4);
  }

  String get _strengthLabel =>
      const ['', 'Weak', 'Fair', 'Good', 'Strong'][_strength];

  Color get _strengthColor => const [
    Colors.transparent,
    AppTheme.dangerColor,
    AppTheme.warningColor,
    AppTheme.cyan,
    AppTheme.successColor,
  ][_strength];

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
    if (!agreedToTerms) {
      msg('Please agree to the Terms and Privacy Policy to continue.');
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService().register(
        email.text.trim(),
        pass.text,
        displayName: name.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CareerGoalsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) msg(e.message ?? 'Could not create account.');
    } catch (e) {
      if (mounted) msg('Could not create account: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void msg(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));

  void _showPolicy(String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Your CV content is processed by Google Gemini to power the '
          "app's AI features. It is never shared with other users and is "
          "never used to invent facts that aren't already in your CV.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [name, email, pass, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Create account'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 4,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Step 1 of 2 · Account',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: CvoraMark(size: 64)),
            const SizedBox(height: 24),
            const Text('Full name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                hintText: 'Sara Ahmed',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: pass,
              obscureText: obscurePass,
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => obscurePass = !obscurePass),
                ),
              ),
            ),
            if (pass.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i <= 4; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _strength ? _strengthColor : AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 4) const SizedBox(width: 6),
                  ],
                  const SizedBox(width: 10),
                  Text(_strengthLabel, style: TextStyle(fontSize: 12, color: _strengthColor, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('Confirm password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: confirm,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: agreedToTerms,
                  onChanged: (v) => setState(() => agreedToTerms = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms',
                            style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => _showPolicy('Terms of Service'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => _showPolicy('Privacy Policy'),
                          ),
                          const TextSpan(text: ', including how my CV data is processed by AI.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Continue to career goals',
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
