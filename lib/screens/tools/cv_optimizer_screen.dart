import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

/// Screen 13 — AI CV Optimizer.
///
/// Tailors an existing resume to a specific job description, shows a
/// before/after for every change, and only applies the ones the user
/// explicitly accepts — saved as a brand new document so the original is
/// never touched.
class CvOptimizerScreen extends StatefulWidget {
  const CvOptimizerScreen({super.key});

  @override
  State<CvOptimizerScreen> createState() => _CvOptimizerScreenState();
}

class _CvOptimizerScreenState extends State<CvOptimizerScreen> {
  late final TextEditingController jobDescriptionController;
  late Future<List<Resume>> resumesFuture;
  Resume? selected;

  Map<String, dynamic>? result;
  bool loading = false;
  bool saving = false;
  String? error;

  bool summaryAccepted = false;
  final Map<int, bool> experienceAccepted = {};
  final Map<int, bool> projectAccepted = {};

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

  Future<void> _optimize() async {
    final resume = selected;
    if (resume == null || jobDescriptionController.text.trim().isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      result = null;
      summaryAccepted = false;
      experienceAccepted.clear();
      projectAccepted.clear();
    });
    try {
      final r = await AiService.instance.optimizeForJob(
        resumeSummary: resume.professionalSummary,
        experienceDescriptions: resume.experience.map((e) => e.description).toList(),
        projectDescriptions: resume.projects.map((p) => p.description).toList(),
        skills: resume.skills,
        jobDescription: jobDescriptionController.text,
      );
      if (mounted) setState(() => result = r);
    } catch (e) {
      if (mounted) setState(() => error = 'AI optimization failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveOptimizedCopy() async {
    final resume = selected;
    final r = result;
    if (resume == null || r == null) return;

    setState(() => saving = true);
    try {
      final optimizedSummary = (r['optimizedSummary'] as String?) ?? '';
      final expChanges = <int, String>{};
      for (final raw in (r['experience'] as List? ?? const [])) {
        final e = raw as Map;
        final i = (e['index'] as num?)?.toInt();
        final text = e['optimizedDescription'] as String?;
        if (i != null && text != null) expChanges[i] = text;
      }
      final projChanges = <int, String>{};
      for (final raw in (r['projects'] as List? ?? const [])) {
        final p = raw as Map;
        final i = (p['index'] as num?)?.toInt();
        final text = p['optimizedDescription'] as String?;
        if (i != null && text != null) projChanges[i] = text;
      }

      final newExperience = [
        for (var i = 0; i < resume.experience.length; i++)
          (experienceAccepted[i] == true && expChanges.containsKey(i))
              ? Experience(
                  id: resume.experience[i].id,
                  jobTitle: resume.experience[i].jobTitle,
                  company: resume.experience[i].company,
                  startDate: resume.experience[i].startDate,
                  endDate: resume.experience[i].endDate,
                  description: expChanges[i]!,
                  isCurrentJob: resume.experience[i].isCurrentJob,
                )
              : resume.experience[i],
      ];

      final newProjects = [
        for (var i = 0; i < resume.projects.length; i++)
          (projectAccepted[i] == true && projChanges.containsKey(i))
              ? Project(
                  id: resume.projects[i].id,
                  name: resume.projects[i].name,
                  description: projChanges[i]!,
                  link: resume.projects[i].link,
                  technologies: resume.projects[i].technologies,
                  startDate: resume.projects[i].startDate,
                  endDate: resume.projects[i].endDate,
                )
              : resume.projects[i],
      ];

      final now = DateTime.now();
      final optimizedCopy = Resume(
        id: '',
        userId: resume.userId,
        fullName: resume.fullName,
        email: resume.email,
        phone: resume.phone,
        location: resume.location,
        professionalTitle: '${resume.professionalTitle} (Optimized)',
        professionalSummary: summaryAccepted ? optimizedSummary : resume.professionalSummary,
        documentType: resume.documentType,
        resumeType: resume.resumeType,
        template: resume.template,
        education: resume.education,
        experience: newExperience,
        skills: resume.skills,
        projects: newProjects,
        achievements: resume.achievements,
        certifications: resume.certifications,
        createdAt: now,
        updatedAt: now,
      );

      await DatabaseService.instance.createResume(optimizedCopy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved as a new, optimized document.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _diffCard({
    required String title,
    required String original,
    required String optimized,
    required bool accepted,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text('Before', style: TextStyle(fontSize: 11, color: AppTheme.grey, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            original.isEmpty ? '(empty)' : original,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.grey),
          ),
          const SizedBox(height: 10),
          const Text('After', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(optimized, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Accept this change', style: TextStyle(fontSize: 13)),
            value: accepted,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CV Optimizer',
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
                      Icon(Icons.tune_outlined, size: 48, color: AppTheme.grey.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      const Text('Nothing to optimize yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then come back here to tailor it to a job.',
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
                      onChanged: (value) => setState(() {
                        selected = value;
                        result = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Optimize For a Job',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste the job description. AI will suggest tailored rewrites — '
                    'you choose which ones to keep, saved as a new document.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: jobDescriptionController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: loading ? null : _optimize,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(loading ? 'Optimizing…' : 'Optimize My CV'),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: AppTheme.error)),
                    ),
                  if (result != null) ..._buildDiffs(resumes),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDiffs(List<Resume> resumes) {
    final resume = selected!;
    final r = result!;
    final optimizedSummary = (r['optimizedSummary'] as String?) ?? '';
    final expMap = <int, String>{};
    for (final raw in (r['experience'] as List? ?? const [])) {
      final e = raw as Map;
      final i = (e['index'] as num?)?.toInt();
      final text = e['optimizedDescription'] as String?;
      if (i != null && text != null) expMap[i] = text;
    }
    final projMap = <int, String>{};
    for (final raw in (r['projects'] as List? ?? const [])) {
      final p = raw as Map;
      final i = (p['index'] as num?)?.toInt();
      final text = p['optimizedDescription'] as String?;
      if (i != null && text != null) projMap[i] = text;
    }
    final keywords = (r['keywordsToAdd'] as List?)?.cast<String>() ?? const [];

    final anyAccepted = summaryAccepted ||
        experienceAccepted.values.any((v) => v) ||
        projectAccepted.values.any((v) => v);

    return [
      const SizedBox(height: 24),
      if (keywords.isNotEmpty) ...[
        const Text('Suggested Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((k) => Chip(label: Text(k))).toList(),
        ),
        const SizedBox(height: 18),
      ],
      const Text('Review Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (optimizedSummary.trim().isNotEmpty)
        _diffCard(
          title: 'Professional Summary',
          original: resume.professionalSummary,
          optimized: optimizedSummary,
          accepted: summaryAccepted,
          onChanged: (v) => setState(() => summaryAccepted = v),
        ),
      for (final i in expMap.keys)
        if (i < resume.experience.length)
          _diffCard(
            title: 'Experience: ${resume.experience[i].jobTitle.isEmpty ? resume.experience[i].company : resume.experience[i].jobTitle}',
            original: resume.experience[i].description,
            optimized: expMap[i]!,
            accepted: experienceAccepted[i] ?? false,
            onChanged: (v) => setState(() => experienceAccepted[i] = v),
          ),
      for (final i in projMap.keys)
        if (i < resume.projects.length)
          _diffCard(
            title: 'Project: ${resume.projects[i].name}',
            original: resume.projects[i].description,
            optimized: projMap[i]!,
            accepted: projectAccepted[i] ?? false,
            onChanged: (v) => setState(() => projectAccepted[i] = v),
          ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: (!anyAccepted || saving) ? null : _saveOptimizedCopy,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Saving…' : 'Save Optimized Copy'),
        ),
      ),
    ];
  }
}
