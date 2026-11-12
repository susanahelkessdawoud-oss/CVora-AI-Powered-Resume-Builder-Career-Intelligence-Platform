import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../builder/document_type_screen.dart';
import '../resumes/my_resumes_screen.dart';
import '../tools/job_matcher_screen.dart';
import '../tools/resume_score_screen.dart';
import '../tools/github_screen.dart';
import '../tools/achievement_vault_screen.dart';
import '../tools/cover_letter_screen.dart';
import '../tools/ats_analyzer_screen.dart';
import '../tools/cv_analyzer_screen.dart';
import '../tools/skills_intelligence_screen.dart';
import '../tools/cv_import_screen.dart';
import '../tools/cv_optimizer_screen.dart';
import '../tools/interview_coach_screen.dart';
import '../tools/career_advisor_screen.dart';
import '../export/export_center_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget featureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
    Color accent = AppTheme.navy,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Several accent colors are deliberately very dark navy for a subtle
    // look in light mode — on a dark background that same color (and an
    // icon drawn in it) nearly disappears, so lighten it for display here.
    final displayAccent =
        isDark ? Color.lerp(accent, Colors.white, 0.45)! : accent;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        openPage(context, page);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: displayAccent.withValues(alpha: isDark ? 0.3 : 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    displayAccent.withValues(alpha: isDark ? 0.3 : 0.22),
                    displayAccent.withValues(alpha: isDark ? 0.15 : 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: displayAccent),
            ),

            const Spacer(),

            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CVORA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            onPressed: () {
              openPage(context, const SettingsScreen());
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.navyGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Firebase can briefly return a partially-populated
                    // User (uid only, no email yet) right after a cold
                    // start restores the persisted session — listening to
                    // authStateChanges() instead of reading currentUser
                    // once means this corrects itself the moment the full
                    // profile loads, rather than showing the generic
                    // greeting for the rest of the screen's lifetime.
                    StreamBuilder<AppUser?>(
                      stream: AuthService.instance.userChanges(),
                      initialData: AuthService.instance.currentUser,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final displayName =
                            user?.displayName?.trim() ??
                            user?.email?.split('@').first ??
                            '';
                        return Text(
                          displayName.isEmpty ? 'Welcome to CVORA 👋' : 'Welcome, $displayName 👋',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Build a resume that represents you — with AI in every step.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // CREATE RESUME BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    openPage(context, const DocumentTypeScreen());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Create New Resume',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    openPage(context, const CvImportScreen());
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text(
                    'Upload an Existing CV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Your Career Tools',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  featureCard(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'My Resumes',
                    subtitle: 'View resumes',
                    page: const MyResumesScreen(filterType: 'resume'),
                    accent: AppTheme.navy,
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.file_copy_outlined,
                    title: 'My CVs',
                    subtitle: 'View CVs',
                    page: const MyResumesScreen(filterType: 'cv'),
                    accent: const Color(0xFF27496D),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.auto_fix_high,
                    title: 'Improve',
                    subtitle: 'Suggestions',
                    page: const ResumeScoreScreen(),
                    accent: const Color(0xFF1B2A4A),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.work_outline,
                    title: 'Match Job',
                    subtitle: 'Compare',
                    page: const JobMatcherScreen(),
                    accent: const Color(0xFF2E5984),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.mail_outline,
                    title: 'Cover Letter',
                    subtitle: 'AI generated',
                    page: const CoverLetterScreen(),
                    accent: const Color(0xFF3B6E91),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.code,
                    title: 'GitHub',
                    subtitle: 'Projects',
                    page: const GithubScreen(),
                    accent: const Color(0xFF16263E),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.insights_outlined,
                    title: 'CV Analyzer',
                    subtitle: 'AI deep dive',
                    page: const CvAnalyzerScreen(),
                    accent: AppTheme.navyDark,
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.rule_folder_outlined,
                    title: 'ATS Analyzer',
                    subtitle: 'Parse check',
                    page: const AtsAnalyzerScreen(),
                    accent: const Color(0xFF255F85),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.psychology_outlined,
                    title: 'Skills',
                    subtitle: 'Intelligence',
                    page: const SkillsIntelligenceScreen(),
                    accent: const Color(0xFF3A5A7A),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.tune_outlined,
                    title: 'CV Optimizer',
                    subtitle: 'Tailor to job',
                    page: const CvOptimizerScreen(),
                    accent: const Color(0xFF1F4068),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.mic_none_outlined,
                    title: 'Interview',
                    subtitle: 'AI coach',
                    page: const InterviewCoachScreen(),
                    accent: const Color(0xFF2C4870),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.explore_outlined,
                    title: 'Career Advisor',
                    subtitle: 'Plan ahead',
                    page: const CareerAdvisorScreen(),
                    accent: const Color(0xFF142D4C),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Vault',
                    subtitle: 'Achievements',
                    page: const AchievementVaultScreen(),
                    accent: const Color(0xFF3D5A80),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Export',
                    subtitle: 'Get your PDF',
                    page: const ExportCenterScreen(),
                    accent: const Color(0xFF22394F),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
