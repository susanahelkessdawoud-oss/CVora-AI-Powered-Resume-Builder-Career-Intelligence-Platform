import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/job_matcher.dart';

class JobMatcherScreen extends StatefulWidget {
  const JobMatcherScreen({super.key});

  @override
  State<JobMatcherScreen> createState() => _JobMatcherScreenState();
}

class _JobMatcherScreenState extends State<JobMatcherScreen> {
  late final TextEditingController jobDescriptionController;
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  JobMatchResult? result;
  String? aiAdvice;
  bool aiLoading = false;
  String? aiError;

  @override
  void initState() {
    super.initState();
    jobDescriptionController = TextEditingController();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  @override
  void dispose() {
    jobDescriptionController.dispose();
    super.dispose();
  }

  void _analyze() {
    if (selected == null || jobDescriptionController.text.trim().isEmpty) return;
    setState(() {
      result = JobMatcher.match(selected!, jobDescriptionController.text);
      aiAdvice = null;
      aiError = null;
    });
  }

  Future<void> _getAiAdvice() async {
    final r = result;
    final resume = selected;
    if (r == null || resume == null) return;
    setState(() {
      aiLoading = true;
      aiError = null;
    });
    try {
      final advice = await AiService.instance.jobMatchAdvice(
        jobDescription: jobDescriptionController.text,
        resumeSummary: resume.professionalSummary,
        matchedKeywords: r.matchedKeywords,
        missingKeywords: r.missingKeywords,
      );
      if (mounted) setState(() => aiAdvice = advice);
    } catch (e) {
      if (mounted) setState(() => aiError = 'AI request failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => aiLoading = false);
    }
  }

  Color _matchColor(int percent) {
    if (percent >= 70) return AppTheme.success;
    if (percent >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match a Job',
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
                        Icons.work_outline,
                        size: 48,
                        color: AppTheme.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nothing to match yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then compare it against a job description.',
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
                  const Text(
                    'Compare with a Job Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste a job description to see how well your document matches its keywords.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
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
                        result = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: jobDescriptionController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      hintText: 'Paste the job description here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _analyze,
                      child: const Text('Analyze Match'),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _matchColor(result!.matchPercent).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: _matchColor(result!.matchPercent).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Match Score',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${result!.matchPercent}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _matchColor(result!.matchPercent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (result!.matchedKeywords.isNotEmpty) ...[
                      const Text(
                        'Matched Keywords',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result!.matchedKeywords
                            .map(
                              (k) => Chip(
                                label: Text(k),
                                avatar: const Icon(Icons.check, size: 16),
                                backgroundColor: AppTheme.success.withValues(alpha: 0.12),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (result!.missingKeywords.isNotEmpty) ...[
                      const Text(
                        'Missing Keywords',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consider weaving these into your summary or experience if they genuinely apply to you.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.grey),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result!.missingKeywords
                            .map(
                              (k) => Chip(
                                label: Text(k),
                                backgroundColor: AppTheme.error.withValues(alpha: 0.08),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: aiLoading ? null : _getAiAdvice,
                        icon: aiLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(aiLoading ? 'Thinking…' : 'Get AI Advice'),
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
                    if (aiAdvice != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.navy.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppTheme.navy.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.auto_awesome, size: 16, color: AppTheme.navy),
                                SizedBox(width: 6),
                                Text(
                                  'AI Advice',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(aiAdvice!, style: const TextStyle(fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ],
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
