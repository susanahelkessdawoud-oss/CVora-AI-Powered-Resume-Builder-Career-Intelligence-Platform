import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _initError;

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    setState(() => _initError = null);

    try {
      // Initialized here (after the first frame), not in main() before
      // runApp() — on Windows, firebase_core/cloud_firestore are native
      // plugins whose startup work would otherwise block that first frame,
      // leaving the window looking frozen instead of showing this splash.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 20));
      }
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final rememberMe = await PreferencesService.getRememberMe();
    if (!rememberMe && AuthService.instance.isLoggedIn()) {
      await AuthService.instance.logout();
    }

    if (!mounted) return;
    final isLoggedIn = AuthService.instance.isLoggedIn();
    Navigator.of(
      context,
    ).pushReplacementNamed(isLoggedIn ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navyDark, AppTheme.navy, AppTheme.navyLight],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'CVORA',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI-Powered Resume Builder & Career Intelligence',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              if (_initError == null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        'Could not connect: $_initError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: _navigateToHome,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
