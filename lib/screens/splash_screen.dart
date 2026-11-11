import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/cvora_logo.dart';

/// Navy-gradient branded splash shown while Firebase resolves the auth state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navyBg,
              Color(0xFF16225C),
              Color(0xFF1B2A6B),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: const CvoraLogo(size: 96),
              ),
              const SizedBox(height: 28),
              const Text('CVORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  )),
              const SizedBox(height: 6),
              const Text('Build it. Improve it. Get hired.',
                  style: TextStyle(color: Color(0xFFAEB6DA), fontSize: 14)),
              const SizedBox(height: 44),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
