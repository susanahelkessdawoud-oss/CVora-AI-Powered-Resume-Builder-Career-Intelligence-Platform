import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

/// Screen 17 — AI Career Advisor. Recommends roles, skills to develop, and
/// a phased roadmap, every item grounded in the candidate's actual resume
/// rather than generic advice.
class CareerAdvisorScreen extends StatefulWidget {
  const CareerAdvisorScreen({super.key});

  @override
  State<CareerAdvisorScreen> createState() => _CareerAdvisorScreenState();
}

class _CareerAdvisorScreenState extends State<CareerAdvisorScreen> {
  late final TextEditingController interestsController;
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  Map<String, dynamic>? result;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    interestsController = TextEditingController();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  @override
  void dispose() {
    interestsController.dispose();
    super.dispose();
  }

  String _resumeText(Resume r) {
    return [
      r.professionalTitle,
      r.professionalSummary,
      ...r.experience.map((e) => '${e.jobTitle} at ${e.company}: ${e.description}'),
      ...r.education.map((e) => '${e.degree} ${e.fieldOfStudy}'),
      ...r.projects.map((p) => 'Project ${p.name}: ${p.description}'),
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  Future<void> _getRecommendations() async {
    final resume = selected;
    if (resume == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await AiService.instance.careerRecommendations(
        resumeText: _resumeText(resume),
        skills: resume.skills,
        careerInterests: interestsController.text.trim().isEmpty ? null : interestsController.text,
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
        title: const Text('Career Advisor', style: TextStyle(fontWeight: FontWeight.w800)),
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
                      Icon(Icons.explore_outlined, size: 48, color: AppTheme.grey.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      const Text('Nothing to advise on yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then come back here for career guidance.',
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
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.professionalTitle.isEmpty
                                    ? (r.fullName.isEmpty ? 'Untitled' : r.fullName)
                                    : r.professionalTitle),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        selected = v;
                        result = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Plan Your Career', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Recommendations grounded in your actual background — not generic advice.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: interestsController,
                    decoration: const InputDecoration(
                      labelText: 'Career interests (optional)',
                      hintText: 'e.g. interested in moving into backend / management / data',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: loading ? null : _getRecommendations,
                      icon: loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(loading ? 'Thinking…' : 'Get Recommendations'),
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
    final roles = (r['suggestedRoles'] as List?) ?? const [];
    final skills = (r['skillsToDevelop'] as List?) ?? const [];
    final roadmap = (r['roadmap'] as List?) ?? const [];

    Widget section(String title, List items, Color color, IconData icon,
        String Function(Map) heading, String Function(Map) body) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...items.map((raw) {
              final m = raw as Map;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(heading(m), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(body(m), style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return [
      const SizedBox(height: 24),
      section('Suggested Roles', roles, AppTheme.purple, Icons.work_outline,
          (m) => (m['role'] as String?) ?? '', (m) => (m['why'] as String?) ?? ''),
      section('Skills To Develop', skills, AppTheme.blue, Icons.trending_up,
          (m) => (m['skill'] as String?) ?? '', (m) => (m['why'] as String?) ?? ''),
      section('Learning Roadmap', roadmap, AppTheme.success, Icons.map_outlined,
          (m) => (m['phase'] as String?) ?? '', (m) => (m['focus'] as String?) ?? ''),
    ];
  }
}
