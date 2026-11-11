import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Renders the resume in the selected template and saves it to SQLite.
///
/// The preview is driven entirely by the live [Resume] object — there is no
/// duplicated preview data anywhere.
class PreviewScreen extends StatefulWidget {
  final Resume resume;
  const PreviewScreen({super.key, required this.resume});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    if (widget.resume.fullName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your full name before saving.')),
      );
      return;
    }
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await DatabaseService.instance.saveResume(widget.resume);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume saved.')),
      );
      // Unwind the whole builder flow back to Home.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = widget.resume;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: resume.templateId == 'classic'
                ? _ClassicTemplate(resume: resume)
                : _ModernTemplate(resume: resume),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks (always dark ink on white "paper", like a real CV).
// ---------------------------------------------------------------------------
const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF555555);
const _accent = Color(0xFF5B5FEF);

Widget _sectionTitle(String text, {Color color = _accent}) {
  return Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _ModernTemplate extends StatelessWidget {
  final Resume resume;
  const _ModernTemplate({required this.resume});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resume.fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              if (resume.jobTitle.isNotEmpty)
                Text(resume.jobTitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          [resume.email, resume.phone, resume.location]
              .where((s) => s.isNotEmpty)
              .join('  •  '),
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (resume.summary.isNotEmpty) ...[
          _sectionTitle('Profile'),
          Text(resume.summary,
              style: const TextStyle(color: _ink, height: 1.4)),
        ],
        _body(),
      ],
    );
  }

  Widget _body() => _ResumeBody(resume: resume, accent: _accent);
}

class _ClassicTemplate extends StatelessWidget {
  final Resume resume;
  const _ClassicTemplate({required this.resume});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Text(resume.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              if (resume.jobTitle.isNotEmpty)
                Text(resume.jobTitle,
                    style: const TextStyle(color: _muted, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                [resume.email, resume.phone, resume.location]
                    .where((s) => s.isNotEmpty)
                    .join('  |  '),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(color: _ink, height: 24),
        if (resume.summary.isNotEmpty) ...[
          _sectionTitle('Summary', color: _ink),
          Text(resume.summary,
              style: const TextStyle(color: _ink, height: 1.4)),
        ],
        _ResumeBody(resume: resume, accent: _ink),
      ],
    );
  }
}

/// The shared middle sections (experience, skills, education) so the two
/// templates stay in sync while differing in their headers/accent.
class _ResumeBody extends StatelessWidget {
  final Resume resume;
  final Color accent;
  const _ResumeBody({required this.resume, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resume.experiences.isNotEmpty) ...[
          _sectionTitle('Experience', color: accent),
          ...resume.experiences.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.position}${e.company.isEmpty ? '' : ' — ${e.company}'}',
                      style: const TextStyle(
                          color: _ink, fontWeight: FontWeight.bold)),
                  if (e.dateRange.isNotEmpty)
                    Text(e.dateRange,
                        style: const TextStyle(color: _muted, fontSize: 12)),
                  if (e.description.isNotEmpty)
                    Text(e.description,
                        style: const TextStyle(color: _ink, height: 1.35)),
                ],
              ),
            ),
          ),
        ],
        if (resume.skills.isNotEmpty) ...[
          _sectionTitle('Skills', color: accent),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: resume.skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: _muted),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s.name,
                          style: const TextStyle(color: _ink, fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
        if (resume.educations.isNotEmpty) ...[
          _sectionTitle('Education', color: accent),
          ...resume.educations.map(
            (edu) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${edu.degree}${edu.field.isEmpty ? '' : ', ${edu.field}'}',
                      style: const TextStyle(
                          color: _ink, fontWeight: FontWeight.bold)),
                  Text([edu.institution, edu.yearRange]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
