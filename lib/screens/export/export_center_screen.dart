import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/docx_service.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

class ExportCenterScreen extends StatefulWidget {
  const ExportCenterScreen({super.key});

  @override
  State<ExportCenterScreen> createState() => _ExportCenterScreenState();
}

class _ExportCenterScreenState extends State<ExportCenterScreen> {
  late Future<List<Resume>> resumesFuture;
  Resume? selected;
  bool exporting = false;
  bool exportingDocx = false;

  @override
  void initState() {
    super.initState();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  Future<void> _export({required bool share}) async {
    final resume = selected;
    if (resume == null) return;

    setState(() => exporting = true);
    try {
      final bytes = await PdfService.buildResumePdf(resume);
      final fileName =
          '${resume.fullName.isEmpty ? 'resume' : resume.fullName.replaceAll(' ', '_')}.pdf';
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

  Future<void> _exportDocx() async {
    final resume = selected;
    if (resume == null) return;

    setState(() => exportingDocx = true);
    try {
      final bytes = await DocxService.buildResumeDocx(resume);
      final fileName =
          '${resume.fullName.isEmpty ? 'resume' : resume.fullName.replaceAll(' ', '_')}.docx';
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save DOCX',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      if (uri == null) return; // user cancelled
      if (mounted) {
        final display = uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $display')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not export DOCX: $e')));
      }
    } finally {
      if (mounted) setState(() => exportingDocx = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Export Center',
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
                        Icons.picture_as_pdf_outlined,
                        size: 48,
                        color: AppTheme.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nothing to export yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a CV or Resume first, then come back here to export it as a PDF.',
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
                    'Export Your Document',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose which document to export as a PDF.',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  const SizedBox(height: 20),
                  RadioGroup<Resume>(
                    groupValue: selected,
                    onChanged: (value) => setState(() => selected = value),
                    child: Column(
                      children: resumes
                          .map(
                            (resume) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: RadioListTile<Resume>(
                                value: resume,
                                title: Text(
                                  resume.professionalTitle.isEmpty
                                      ? (resume.fullName.isEmpty
                                            ? 'Untitled'
                                            : resume.fullName)
                                      : resume.professionalTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  resume.documentType == 'cv' ? 'CV' : 'Resume',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: exportingDocx ? null : _exportDocx,
                      icon: exportingDocx
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.description_outlined),
                      label: Text(exportingDocx ? 'Preparing...' : 'Export as DOCX'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
