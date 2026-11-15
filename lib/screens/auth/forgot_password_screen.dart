import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool loading = false;
  bool sent = false;
  int cooldown = 0;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final address = email.text.trim();
    if (address.isEmpty) return;
    setState(() => loading = true);
    try {
      await AuthService.instance.resetPassword(address);
    } catch (_) {
      // Deliberately swallowed: the confirmation below is shown either
      // way, so this screen never reveals whether an account exists for
      // a given email.
    }
    if (!mounted) return;
    setState(() {
      loading = false;
      sent = true;
      cooldown = 60;
    });
    _tickCooldown();
  }

  void _tickCooldown() async {
    while (cooldown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => cooldown--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(Icons.lock_outline, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 20),
              Text(
                "Enter the email you signed up with. We'll send a secure link that expires in 30 minutes.",
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading || cooldown > 0 ? null : _send,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(cooldown > 0 ? 'Resend in ${cooldown}s' : 'Send reset link'),
                ),
              ),
              if (sent) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Check your inbox', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              "If an account exists for this email, a reset link is on its way. Didn't get it? Check spam or resend in 60s.",
                              style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
