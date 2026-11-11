import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

class ResumePreviewScreen extends StatefulWidget {
  final Resume resume;

  const ResumePreviewScreen({super.key, required this.resume});

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  bool exporting = false;

  Future<void> _exportPdf({required bool share}) async {
    setState(() => exporting = true);
    try {
      final bytes = await PdfService.buildResumePdf(widget.resume);
      final fileName =
          '${widget.resume.fullName.isEmpty ? 'resume' : widget.resume.fullName.replaceAll(' ', '_')}.pdf';
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
    final r = widget.resume;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          r.documentType == 'cv' ? 'CV Preview' : 'Resume Preview',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: exporting ? null : () => _exportPdf(share: true),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.fullName.isEmpty ? 'Untitled' : r.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (r.professionalTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.professionalTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.purple,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (r.email.isNotEmpty) _contactChip(Icons.email_outlined, r.email),
                        if (r.phone.isNotEmpty) _contactChip(Icons.phone_outlined, r.phone),
                        if (r.location.isNotEmpty) _contactChip(Icons.location_on_outlined, r.location),
                      ],
                    ),
                    if (r.professionalSummary.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Summary'),
                      Text(r.professionalSummary),
                    ],
                    if (r.experience.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Experience'),
                      ...r.experience.map(
                        (e) => _entryTile(
                          title: e.jobTitle,
                          subtitle: e.company,
                          dates: _dateRange(e.startDate, e.endDate),
                          body: e.description,
                        ),
                      ),
                    ],
                    if (r.education.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Education'),
                      ...r.education.map(
                        (e) => _entryTile(
                          title: e.degree.isEmpty ? e.fieldOfStudy : e.degree,
                          subtitle: e.school,
                          dates: _dateRange(e.startDate, e.endDate),
                          body: '',
                        ),
                      ),
                    ],
                    if (r.projects.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Projects'),
                      ...r.projects.map(
                        (p) => _entryTile(
                          title: p.name,
                          subtitle: p.link,
                          dates: _dateRange(p.startDate, p.endDate),
                          body: p.description,
                        ),
                      ),
                    ],
                    if (r.skills.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Skills'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: r.skills
                            .map((skill) => Chip(label: Text(skill)))
                            .toList(),
                      ),
                    ],
                    if (r.certifications.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Certifications'),
                      ...r.certifications.map(
                        (c) => _entryTile(
                          title: c.name,
                          subtitle: c.issuedBy,
                          dates: c.issueDate,
                          body: '',
                        ),
                      ),
                    ],
                    if (r.achievements.isNotEmpty) ...[
                      const Divider(height: 28),
                      _section('Achievements'),
                      ...r.achievements.map(
                        (a) => _entryTile(
                          title: a.title,
                          subtitle: '',
                          dates: a.date,
                          body: a.description,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: exporting ? null : () => _exportPdf(share: true),
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: exporting ? null : () => _exportPdf(share: false),
                      icon: exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_outlined),
                      label: Text(exporting ? 'Preparing...' : 'Download as PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  Widget _contactChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.purple,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _entryTile({
    required String title,
    required String subtitle,
    required String dates,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (dates.isNotEmpty)
                Text(dates, style: const TextStyle(fontSize: 11.5, color: AppTheme.grey)),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.purple, fontSize: 13),
            ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
