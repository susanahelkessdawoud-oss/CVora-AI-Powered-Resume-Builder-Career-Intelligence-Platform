import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/ats_checker.dart';

/// Dedicated ATS compatibility module — separate from the general Resume
/// Score — focused purely on document parsing/formatting signals: whether
/// an ATS's text extraction and section detection would actually work on
/// this document, not how well-written it is.
class AtsAnalyzerScreen extends StatefulWidget {
  const AtsAnalyzerScreen({super.key});

  @override
  State<AtsAnalyzerScreen> createState() => _AtsAnalyzerScreenState();
}

class _AtsAnalyzerScreenState extends State<AtsAnalyzerScreen> {
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  String? aiFeedback;
  bool aiLoading = false;
  String? aiError;

  @override
  void initState() {
    super.initState();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  String _resumeText(Resume r) {
    return [
      r.professionalTitle,
      r.professionalSummary,
      ...r.experience.map((e) => '${e.jobTitle} at ${e.company}: ${e.description}'),
      ...r.education.map((e) => '${e.degree} ${e.fieldOfStudy} - ${e.school}'),
      'Skills: ${r.skills.join(', ')}',
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  Future<void> _getAiFeedback(AtsCheckResult result) async {
    final resume = selected;
    if (resume == null) return;
    setState(() {
      aiLoading = true;
      aiError = null;
    });
    try {
      final feedback = await AiService.instance.atsFeedback(
        resumeText: _resumeText(resume),
        failedChecks: result.failedLabels,
      );
      if (mounted) setState(() => aiFeedback = feedback);
    } catch (e) {
      if (mounted) setState(() => aiError = 'AI request failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ATS Analyzer',
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
                        Icons.rule_folder_outlined,
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
                        'Create a CV or Resume first, then come back here for an ATS check.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            selected ??= resumes.first;
            final result = AtsChecker.check(selected!);

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
                        aiFeedback = null;
                        aiError = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'ATS Compatibility',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Checks whether an Applicant Tracking System could actually '
                    'parse this document — not how well it\'s written.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _scoreColor(result.score).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: _scoreColor(result.score).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ATS Score',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${result.score}/100',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _scoreColor(result.score),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: result.score / 100,
                            minHeight: 8,
                            color: _scoreColor(result.score),
                            backgroundColor: Colors.black12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Checks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...result.checks.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (c.passed ? AppTheme.success : AppTheme.error)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: (c.passed ? AppTheme.success : AppTheme.error)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            c.passed ? Icons.check_circle_outline : Icons.error_outline,
                            color: c.passed ? AppTheme.success : AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.label} (${c.points} pts)',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.detail,
                                  style: const TextStyle(fontSize: 12.5, color: AppTheme.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: aiLoading ? null : () => _getAiFeedback(result),
                      icon: aiLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(aiLoading ? 'Thinking…' : 'Get AI Fix Suggestions'),
                    ),
                  ),
                  if (aiError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        aiError!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12.5),
                      ),
                    ),
                  if (aiFeedback != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome, size: 16, color: AppTheme.purple),
                              SizedBox(width: 6),
                              Text(
                                'AI Suggestions',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.purple),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(aiFeedback!, style: const TextStyle(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
