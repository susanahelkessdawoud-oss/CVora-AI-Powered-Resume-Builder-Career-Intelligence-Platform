import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../builder/document_type_screen.dart';
import '../resumes/my_resumes_screen.dart';
import '../tools/job_matcher_screen.dart';
import '../tools/resume_score_screen.dart';
import '../tools/github_screen.dart';
import '../tools/achievement_vault_screen.dart';
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
  }) {
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
                color: AppTheme.purple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppTheme.purple),
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
    final user = AuthService.instance.currentUser;
    final displayName =
        (user?.userMetadata?['display_name'] as String?)?.trim() ??
        user?.email?.split('@').first ??
        '';

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
              Text(
                displayName.isEmpty ? 'Welcome to CVORA 👋' : 'Welcome, $displayName 👋',
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 7),

              const Text(
                'Build a resume that represents you.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
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
                childAspectRatio: 0.9,
                children: [
                  featureCard(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'My Resumes',
                    subtitle: 'View resumes',
                    page: const MyResumesScreen(filterType: 'resume'),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.file_copy_outlined,
                    title: 'My CVs',
                    subtitle: 'View CVs',
                    page: const MyResumesScreen(filterType: 'cv'),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.auto_fix_high,
                    title: 'Improve',
                    subtitle: 'Suggestions',
                    page: const ResumeScoreScreen(),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.work_outline,
                    title: 'Match Job',
                    subtitle: 'Compare',
                    page: const JobMatcherScreen(),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.code,
                    title: 'GitHub',
                    subtitle: 'Projects',
                    page: const GithubScreen(),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Vault',
                    subtitle: 'Achievements',
                    page: const AchievementVaultScreen(),
                  ),

                  featureCard(
                    context: context,
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Export',
                    subtitle: 'Get your PDF',
                    page: const ExportCenterScreen(),
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
