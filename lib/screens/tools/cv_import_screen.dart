import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../builder/resume_builder_screen.dart';

/// AI Engine 1 — Document Understanding, surfaced as an "Upload an existing
/// CV" entry point. The PDF/DOCX is sent directly to Gemini (multimodal)
/// for extraction; the result is only ever a *draft* the user reviews and
/// edits in the normal builder before anything is saved.
class CvImportScreen extends StatefulWidget {
  const CvImportScreen({super.key});

  @override
  State<CvImportScreen> createState() => _CvImportScreenState();
}

class _CvImportScreenState extends State<CvImportScreen> {
  String documentType = 'resume';
  bool busy = false;
  String? error;
  String? pickedFileName;

  Future<void> _pickAndImport() async {
    setState(() {
      error = null;
    });

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => error = 'Could not read that file. Try a different one.');
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    final mimeType = ext == 'docx'
        ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        : 'application/pdf';

    setState(() {
      busy = true;
      pickedFileName = file.name;
    });

    try {
      final parsed = await AiService.instance.parseResumeDocument(
        bytes: bytes,
        mimeType: mimeType,
      );
      final draft = Resume.fromJson({
        ...parsed,
        'documentType': documentType,
      });

      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ResumeBuilderScreen(
            existing: draft,
            documentType: documentType,
          ),
        ),
      );
      if (saved == true && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Could not read that document. Try again, or build from scratch instead.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload a CV',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import an Existing CV',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a PDF or DOCX and AI will extract your contact info, '
                'summary, experience, education, skills, projects, '
                'achievements and certifications into an editable draft — '
                'nothing is saved until you review it.',
                style: TextStyle(color: AppTheme.grey),
              ),
              const SizedBox(height: 20),
              const Text('Import as', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'resume', label: Text('Resume')),
                  ButtonSegment(value: 'cv', label: Text('CV')),
                ],
                selected: {documentType},
                onSelectionChanged: (s) => setState(() => documentType = s.first),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.purple.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  color: AppTheme.purple.withValues(alpha: 0.04),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 40, color: AppTheme.purple),
                    const SizedBox(height: 12),
                    if (pickedFileName != null && busy)
                      Text(
                        'Reading $pickedFileName…',
                        style: const TextStyle(color: AppTheme.grey),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _pickAndImport,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.description_outlined),
                        label: Text(busy ? 'Reading document…' : 'Choose PDF or DOCX'),
                      ),
                    ),
                  ],
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!, style: const TextStyle(color: AppTheme.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
