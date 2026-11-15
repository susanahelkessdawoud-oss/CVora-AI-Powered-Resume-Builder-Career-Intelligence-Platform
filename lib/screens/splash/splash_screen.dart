import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../firebase_options.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cvora_mark.dart';

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
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CvoraMark(size: 132, animate: true),
              const SizedBox(height: 28),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: const [
                    TextSpan(text: 'CV'),
                    TextSpan(text: 'o', style: TextStyle(color: AppTheme.primaryLight)),
                    TextSpan(text: 'ra'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'BUILD · OPTIMIZE · GROW',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  letterSpacing: 2,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 64),
              if (_initError == null)
                Column(
                  children: [
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: AppTheme.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loading your workspace...',
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.mutedText),
                    ),
                  ],
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
