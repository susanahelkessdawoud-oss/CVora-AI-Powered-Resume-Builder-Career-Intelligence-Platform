import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

/// Pick a saved resume, paste a job description, and get a tailored,
/// ready-to-send cover letter — editable and exportable to PDF.
class CoverLetterScreen extends StatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  late final TextEditingController jobDescriptionController;
  late final TextEditingController companyController;
  late final TextEditingController letterController;
  late Future<List<Resume>> resumesFuture;

  Resume? selected;
  bool generating = false;
  bool exporting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    jobDescriptionController = TextEditingController();
    companyController = TextEditingController();
    letterController = TextEditingController();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  @override
  void dispose() {
    jobDescriptionController.dispose();
    companyController.dispose();
    letterController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final resume = selected;
    if (resume == null || jobDescriptionController.text.trim().isEmpty) return;

    setState(() {
      generating = true;
      error = null;
    });
    try {
      final experienceHighlights = resume.experience
          .map((e) => '${e.jobTitle} at ${e.company}: ${e.description}')
          .where((s) => s.trim().isNotEmpty)
          .join('\n');

      final letter = await AiService.instance.generateCoverLetter(
        fullName: resume.fullName,
        jobTitle: resume.professionalTitle,
        resumeSummary: resume.professionalSummary,
        skills: resume.skills,
        experienceHighlights: experienceHighlights,
        jobDescription: jobDescriptionController.text,
        companyName: companyController.text,
      );
      if (mounted) setState(() => letterController.text = letter);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'AI request failed. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  Future<void> _export({required bool share}) async {
    final resume = selected;
    if (resume == null || letterController.text.trim().isEmpty) return;

    setState(() => exporting = true);
    try {
      final bytes = await PdfService.buildLetterPdf(
        fullName: resume.fullName,
        body: letterController.text,
      );
      final fileName =
          '${resume.fullName.isEmpty ? 'cover_letter' : '${resume.fullName.replaceAll(' ', '_')}_cover_letter'}.pdf';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not export PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cover Letter',
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
                        Icons.mail_outline,
                        size: 48,
                        color: AppTheme.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nothing to write from yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then come back here to generate a tailored cover letter.',
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
                    'Generate a Cover Letter',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a document, paste the job description, and let AI draft a tailored letter.',
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
                      onChanged: (value) => setState(() => selected = value),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company name (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    child: FilledButton.icon(
                      onPressed: generating ? null : _generate,
                      icon: generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(generating ? 'Writing…' : 'Generate Cover Letter'),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12.5),
                      ),
                    ),
                  if (letterController.text.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Your Cover Letter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Edit freely before exporting.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: letterController,
                      maxLines: 16,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: exporting ? null : () => _export(share: true),
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Share PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: exporting ? null : () => _export(share: false),
                            icon: exporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(exporting ? 'Preparing...' : 'Export as PDF'),
                          ),
                        ),
                      ],
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
