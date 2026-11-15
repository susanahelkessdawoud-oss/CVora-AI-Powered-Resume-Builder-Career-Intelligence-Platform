import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../activity/activity_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/ats_checker.dart';
import '../../utils/resume_scorer.dart';
import '../../widgets/cv_components.dart';
import '../../widgets/cvora_mark.dart';
import '../builder/document_type_screen.dart';
import '../builder/resume_builder_screen.dart';
import '../preview/resume_preview_screen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  Resume? _activeResume;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final resumes = await DatabaseService.instance.getResumes(uid);
      if (resumes.isNotEmpty) {
        resumes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      if (mounted) {
        setState(() {
          _activeResume = resumes.isEmpty ? null : resumes.first;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _load());
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'there');

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CvoraMark(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                                Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          CvAppBarAction(
                            icon: Icons.notifications_outlined,
                            onTap: () => openPage(context, const ActivityScreen()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_activeResume == null) _emptyStateCard(context) else _activeCvCard(context, _activeResume!),
                      if (_activeResume != null) ...[
                        const SizedBox(height: 14),
                        ..._nextBestStep(context, _activeResume!),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.78,
                        children: [
                          _tool(context, Icons.insights_outlined, 'CV Analyzer', AppTheme.primary, const CvAnalyzerScreen()),
                          _tool(context, Icons.rule_folder_outlined, 'ATS Check', AppTheme.successColor, const AtsAnalyzerScreen()),
                          _tool(context, Icons.work_outline, 'Match Job', AppTheme.cyan, const JobMatcherScreen()),
                          _tool(context, Icons.tune_outlined, 'Optimize', AppTheme.aiPurple, const CvOptimizerScreen()),
                          _tool(context, Icons.mail_outline, 'Cover Letter', AppTheme.warningColor, const CoverLetterScreen()),
                          _tool(context, Icons.mic_none_outlined, 'Interview', AppTheme.dangerColor, const InterviewCoachScreen()),
                          _tool(context, Icons.psychology_outlined, 'Skills', AppTheme.successColor, const SkillsIntelligenceScreen()),
                          _tool(context, Icons.explore_outlined, 'Career', AppTheme.cyan, const CareerAdvisorScreen()),
                          _tool(context, Icons.auto_fix_high, 'Improve', AppTheme.aiPurple, const ResumeScoreScreen()),
                          _tool(context, Icons.code, 'GitHub', AppTheme.primaryLight, const GithubScreen()),
                          _tool(context, Icons.emoji_events_outlined, 'Vault', AppTheme.warningColor, const AchievementVaultScreen()),
                          _tool(context, Icons.picture_as_pdf_outlined, 'Export', AppTheme.primary, const ExportCenterScreen()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const CvBottomNav(currentIndex: 0),
    );
  }

  Widget _emptyStateCard(BuildContext context) {
    return CvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create or upload your first CV', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Build a resume that represents you — with AI in every step.',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openPage(context, const DocumentTypeScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Create New Resume'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openPage(context, const CvImportScreen()),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload an Existing CV'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeCvCard(BuildContext context, Resume resume) {
    final completeness = ResumeScorer.score(resume).score;
    final ats = AtsChecker.check(resume).score;
    final docLabel = resume.documentType == 'cv' ? 'CV' : 'Resume';
    final title = resume.professionalTitle.isNotEmpty ? resume.professionalTitle : '${resume.fullName}\'s $docLabel';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreRing(score: completeness, size: 78),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR ACTIVE $docLabel'.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${resume.template} · edited ${_timeAgo(resume.updatedAt)}',
                      style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Expanded(child: _statBlock(context, '$ats', 'ATS ready', AppTheme.successColor)),
                Container(width: 1, height: 28, color: AppTheme.border),
                Expanded(child: _statBlock(context, '$completeness%', 'Complete', AppTheme.cyan)),
                Container(width: 1, height: 28, color: AppTheme.border),
                Expanded(child: _statBlock(context, '${resume.skills.length}', 'Skills', AppTheme.warningColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => openPage(
                    context,
                    ResumeBuilderScreen(existing: resume, documentType: resume.documentType),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Continue editing'),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => openPage(context, ResumePreviewScreen(resume: resume)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.visibility_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }

  List<Widget> _nextBestStep(BuildContext context, Resume resume) {
    final gaps = ResumeScorer.score(resume).suggestions.where((s) => !s.isPositive).toList();
    if (gaps.isEmpty) return const [];
    final top = gaps.first;
    return [
      AiCard(
        child: InkWell(
          onTap: () => openPage(context, const ResumeScoreScreen()),
          child: Row(
            children: [
              const IconTile(icon: Icons.auto_awesome, color: AppTheme.aiPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEXT BEST STEP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.aiPurple, letterSpacing: 0.6)),
                    const SizedBox(height: 3),
                    Text(top.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    Text(top.detail, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.aiPurple),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _tool(BuildContext context, IconData icon, String label, Color color, Widget page) {
    return InkWell(
      onTap: () => openPage(context, page),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

