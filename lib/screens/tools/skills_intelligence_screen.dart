import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

/// Skills Intelligence — categorizes the candidate's existing skills,
/// flags near-duplicates, and (optionally, against a pasted job
/// description) identifies genuine gaps with project ideas to close them.
/// Never adds an unverified skill to the CV itself.
class SkillsIntelligenceScreen extends StatefulWidget {
  const SkillsIntelligenceScreen({super.key});

  @override
  State<SkillsIntelligenceScreen> createState() => _SkillsIntelligenceScreenState();
}

class _SkillsIntelligenceScreenState extends State<SkillsIntelligenceScreen> {
  late final TextEditingController jobDescriptionController;
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  Map<String, dynamic>? result;
  bool loading = false;
  String? error;

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

  String _resumeText(Resume r) {
    return [
      r.professionalTitle,
      r.professionalSummary,
      ...r.experience.map((e) => '${e.jobTitle} at ${e.company}: ${e.description}'),
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
      final r = await AiService.instance.analyzeSkills(
        skills: resume.skills,
        resumeText: _resumeText(resume),
        jobDescription: jobDescriptionController.text.trim().isEmpty
            ? null
            : jobDescriptionController.text,
      );
      if (mounted) setState(() => result = r);
    } catch (e) {
      if (mounted) setState(() => error = 'AI request failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skills Intelligence',
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
                        Icons.psychology_outlined,
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
                        'Create a CV or Resume with some skills listed first.',
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
                        result = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Analyze Your Skills',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Optionally paste a job description to find genuine gaps against it.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: jobDescriptionController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Job description (optional)',
                      border: OutlineInputBorder(),
                    ),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(loading ? 'Analyzing…' : 'Analyze Skills'),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: AppTheme.error)),
                    ),
                  if (result != null) ..._buildResults(result!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildResults(Map<String, dynamic> r) {
    final categorized = (r['categorized'] as Map?) ?? const {};
    final duplicates = (r['duplicates'] as List?) ?? const [];
    final gaps = (r['gaps'] as List?) ?? const [];
    final projects = (r['suggestedProjects'] as List?) ?? const [];

    Widget chipGroup(String title, List? items, Color color) {
      final list = (items ?? const []).cast<String>();
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: color.withValues(alpha: 0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    return [
      const SizedBox(height: 24),
      const Text('Your Skills, Categorized', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      chipGroup('Technical', categorized['technical'] as List?, AppTheme.purple),
      chipGroup('Tools', categorized['tools'] as List?, AppTheme.blue),
      chipGroup('Languages', categorized['languages'] as List?, AppTheme.green),
      chipGroup('Soft Skills', categorized['soft'] as List?, AppTheme.amber),
      if (duplicates.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Possible Duplicates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...duplicates.map((raw) {
          final d = raw as Map;
          final skills = (d['skills'] as List?)?.cast<String>().join(' / ') ?? '';
          final suggestion = (d['suggestion'] as String?) ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.content_copy, size: 16, color: AppTheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                      children: [
                        TextSpan(text: '$skills — ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: suggestion),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      if (gaps.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Skill Gaps To Learn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'Recommendations only — these are not added to your CV.',
          style: TextStyle(fontSize: 12, color: AppTheme.grey),
        ),
        const SizedBox(height: 8),
        ...gaps.map((raw) {
          final g = raw as Map;
          final skill = (g['skill'] as String?) ?? '';
          final reason = (g['reason'] as String?) ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(reason, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
              ],
            ),
          );
        }),
      ],
      if (projects.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Suggested Portfolio Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...projects.map((raw) {
          final p = raw as Map;
          final title = (p['title'] as String?) ?? '';
          final description = (p['description'] as String?) ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
              ],
            ),
          );
        }),
      ],
    ];
  }
}
