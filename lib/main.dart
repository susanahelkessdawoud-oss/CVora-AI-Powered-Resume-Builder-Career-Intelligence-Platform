import 'package:flutter/material.dart';
import 'providers/theme_manager.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart' as auth_login;
import 'screens/auth/create_account_screen.dart' as auth_register;
import 'screens/home/home_screen.dart';
import 'screens/resumes/my_resumes_screen.dart';
import 'screens/builder/resume_builder_screen.dart';
import 'screens/builder/document_type_screen.dart';
import 'screens/tools/resume_score_screen.dart';
import 'screens/tools/job_matcher_screen.dart';
import 'screens/tools/github_screen.dart';
import 'screens/tools/achievement_vault_screen.dart';
import 'screens/tools/cover_letter_screen.dart';
import 'screens/tools/ats_analyzer_screen.dart';
import 'screens/tools/cv_analyzer_screen.dart';
import 'screens/tools/skills_intelligence_screen.dart';
import 'screens/tools/cv_import_screen.dart';
import 'screens/tools/cv_optimizer_screen.dart';
import 'screens/tools/interview_coach_screen.dart';
import 'screens/tools/career_advisor_screen.dart';
import 'screens/export/export_center_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() is awaited inside SplashScreen instead of here.
  // On Windows, firebase_core/cloud_firestore are native plugins whose
  // startup work blocks the first frame if awaited before runApp() —
  // rendering the splash screen immediately and initializing Firebase
  // after keeps the window responsive instead of appearing frozen.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static State<MyApp>? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.isDarkModeNotifier.addListener(() {
      setState(() {});
    });
    _themeService.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CVORA',
      theme: _themeService.isDarkMode
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // SplashScreen checks AuthService.instance.isLoggedIn() (backed by
      // Firebase's persisted session) and routes to /home or /onboarding.
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const auth_login.LoginScreen(),
        '/register': (context) => const auth_register.CreateAccountScreen(),
        '/home': (context) => const HomeScreen(),
        '/my-resumes': (context) => const MyResumesScreen(),
        '/resume-builder': (context) => const ResumeBuilderScreen(),
        '/document-type': (context) => const DocumentTypeScreen(),
        '/resume-score': (context) => const ResumeScoreScreen(),
        '/job-matcher': (context) => const JobMatcherScreen(),
        '/github': (context) => const GithubScreen(),
        '/achievements-vault': (context) => const AchievementVaultScreen(),
        '/cover-letter': (context) => const CoverLetterScreen(),
        '/ats-analyzer': (context) => const AtsAnalyzerScreen(),
        '/cv-analyzer': (context) => const CvAnalyzerScreen(),
        '/skills-intelligence': (context) => const SkillsIntelligenceScreen(),
        '/cv-import': (context) => const CvImportScreen(),
        '/cv-optimizer': (context) => const CvOptimizerScreen(),
        '/interview-coach': (context) => const InterviewCoachScreen(),
        '/career-advisor': (context) => const CareerAdvisorScreen(),
        '/export': (context) => const ExportCenterScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
