import 'package:flutter/material.dart';

/// Google / Apple continue buttons (UI). Wire these up once Google/Apple
/// OAuth is configured in Firebase; for now they call [onTap].
class SocialButtons extends StatelessWidget {
  final VoidCallback onTap;
  const SocialButtons({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Google', onTap: onTap)),
        const SizedBox(width: 12),
        Expanded(child: _SocialButton(icon: Icons.apple_rounded, label: 'Apple', onTap: onTap)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    );
  }
}
