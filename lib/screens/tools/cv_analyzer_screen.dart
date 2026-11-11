import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../builder/resume_builder_screen.dart';

/// AI Engine 3 (Resume Evaluation) surfaced as a dedicated analyzer —
/// category-scored, explainable, and rerunnable after edits. Distinct from
/// the deterministic "Resume Score" tool: this one is a holistic AI read of
/// quality, not a checklist.
class CvAnalyzerScreen extends StatefulWidget {
  const CvAnalyzerScreen({super.key});

  @override
  State<CvAnalyzerScreen> createState() => _CvAnalyzerScreenState();
}

class _CvAnalyzerScreenState extends State<CvAnalyzerScreen> {
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  Map<String, dynamic>? analysis;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  String _resumeText(Resume r) {
    return [
      r.fullName,
      r.professionalTitle,
      r.professionalSummary,
      ...r.experience.map((e) => '${e.jobTitle} at ${e.company} (${e.startDate}-${e.endDate}): ${e.description}'),
      ...r.education.map((e) => '${e.degree} ${e.fieldOfStudy} - ${e.school}'),
      'Skills: ${r.skills.join(', ')}',
      ...r.projects.map((p) => 'Project ${p.name}: ${p.description}'),
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  Future<void> _analyze() async {
    final resume = selected;
    if (resume == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await AiService.instance.analyzeResume(
        resumeText: _resumeText(resume),
      );
      if (mounted) setState(() => analysis = result);
    } catch (e) {
      if (mounted) setState(() => error = 'AI analysis failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Heuristic mapping from a category name to the builder page it's most
  // actionable from, so "Fix This" lands somewhere useful.
  int _pageFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('skill')) return 4;
    if (c.contains('experience')) return 3;
    if (c.contains('structure') || c.contains('completeness')) return 0;
    return 1; // Content quality / professional language -> Summary
  }

  Color _scoreColor(num score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CV Analyzer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Resume>>(
          future: resumesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final resumes = snapshot.data ?? [];
            if (resumes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 48,
                        color: AppTheme.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nothing to analyze yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then come back here for a full AI analysis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            selected ??= resumes.first;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resumes.length > 1) ...[
                    DropdownButtonFormField<Resume>(
                      initialValue: selected,
                      decoration: const InputDecoration(labelText: 'Document'),
                      items: resumes
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.professionalTitle.isEmpty
                                    ? (r.fullName.isEmpty ? 'Untitled' : r.fullName)
                                    : r.professionalTitle,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        selected = value;
                        analysis = null;
                        error = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'AI CV Analysis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A holistic AI read of content quality, impact, and structure — '
                    'rerun it any time after editing.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: loading ? null : _analyze,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(loading
                          ? 'Analyzing…'
                          : (analysis == null ? 'Analyze My CV' : 'Re-analyze')),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: AppTheme.error)),
                    ),
                  if (analysis != null) ..._buildResults(context, analysis!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildResults(BuildContext context, Map<String, dynamic> a) {
    final overall = (a['overallScore'] as num?) ?? 0;
    final categories = (a['categories'] as List?) ?? const [];
    final strengths = (a['strengths'] as List?)?.cast<String>() ?? const [];
    final weaknesses = (a['weaknesses'] as List?)?.cast<String>() ?? const [];
    final critical = (a['criticalIssues'] as List?)?.cast<String>() ?? const [];

    return [
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _scoreColor(overall).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: _scoreColor(overall).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Text('Overall Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              '$overall/100',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _scoreColor(overall)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...categories.map((raw) {
        final c = raw as Map;
        final name = (c['name'] as String?) ?? '';
        final score = (c['score'] as num?) ?? 0;
        final reason = (c['reason'] as String?) ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('$score/100',
                      style: TextStyle(fontWeight: FontWeight.w800, color: _scoreColor(score))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 6,
                  color: _scoreColor(score),
                  backgroundColor: Colors.black12,
                ),
              ),
              const SizedBox(height: 6),
              Text(reason, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final resume = selected;
                    if (resume == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResumeBuilderScreen(
                          existing: resume,
                          documentType: resume.documentType,
                          initialPage: _pageFor(name),
                        ),
                      ),
                    );
                  },
                  child: const Text('Fix This'),
                ),
              ),
            ],
          ),
        );
      }),
      if (critical.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Critical Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...critical.map((s) => _bullet(s, AppTheme.error, Icons.priority_high)),
      ],
      if (weaknesses.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Weaknesses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...weaknesses.map((s) => _bullet(s, AppTheme.warning, Icons.lightbulb_outline)),
      ],
      if (strengths.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Strengths', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...strengths.map((s) => _bullet(s, AppTheme.success, Icons.check_circle_outline)),
      ],
    ];
  }

  Widget _bullet(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
