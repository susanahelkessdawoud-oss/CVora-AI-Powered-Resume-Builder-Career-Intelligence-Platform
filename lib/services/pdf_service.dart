import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume.dart';

/// Renders a [Resume] into a downloadable/shareable PDF document.
class PdfService {
  static const PdfColor _accent = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);

  static Future<Uint8List> buildResumePdf(Resume resume) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(resume),
          pw.SizedBox(height: 16),
          if (resume.professionalSummary.trim().isNotEmpty) ...[
            _sectionTitle('Summary'),
            pw.Text(
              resume.professionalSummary,
              style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
            ),
            pw.SizedBox(height: 14),
          ],
          if (resume.experience.isNotEmpty) ...[
            _sectionTitle('Experience'),
            ...resume.experience.map(
              (e) => _entry(
                title: e.jobTitle,
                subtitle: e.company,
                dates: _dateRange(e.startDate, e.endDate),
                body: e.description,
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          if (resume.education.isNotEmpty) ...[
            _sectionTitle('Education'),
            ...resume.education.map(
              (e) => _entry(
                title: e.degree.isEmpty ? e.fieldOfStudy : e.degree,
                subtitle: e.school,
                dates: _dateRange(e.startDate, e.endDate),
                body: e.fieldOfStudy.isEmpty || e.degree.isEmpty
                    ? ''
                    : e.fieldOfStudy,
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          if (resume.projects.isNotEmpty) ...[
            _sectionTitle('Projects'),
            ...resume.projects.map(
              (p) => _entry(
                title: p.name,
                subtitle: p.link,
                dates: _dateRange(p.startDate, p.endDate),
                body: p.description,
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          if (resume.skills.isNotEmpty) ...[
            _sectionTitle('Skills'),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resume.skills
                  .map(
                    (skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF3F4F6),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        skill,
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 14),
          ],
          if (resume.certifications.isNotEmpty) ...[
            _sectionTitle('Certifications'),
            ...resume.certifications.map(
              (c) => _entry(
                title: c.name,
                subtitle: c.issuedBy,
                dates: c.issueDate,
                body: '',
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          if (resume.achievements.isNotEmpty) ...[
            _sectionTitle('Achievements'),
            ...resume.achievements.map(
              (a) => _entry(
                title: a.title,
                subtitle: '',
                dates: a.date,
                body: a.description,
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static String _dateRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  static pw.Widget _header(Resume resume) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          resume.fullName.isEmpty ? 'Untitled' : resume.fullName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        if (resume.professionalTitle.isNotEmpty)
          pw.Text(
            resume.professionalTitle,
            style: pw.TextStyle(
              fontSize: 12.5,
              color: _accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 12,
          children: [
            if (resume.email.isNotEmpty) pw.Text(resume.email, style: pw.TextStyle(fontSize: 9.5, color: _grey)),
            if (resume.phone.isNotEmpty) pw.Text(resume.phone, style: pw.TextStyle(fontSize: 9.5, color: _grey)),
            if (resume.location.isNotEmpty) pw.Text(resume.location, style: pw.TextStyle(fontSize: 9.5, color: _grey)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _accent, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _entry({
    required String title,
    required String subtitle,
    required String dates,
    required String body,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (dates.isNotEmpty)
                pw.Text(dates, style: pw.TextStyle(fontSize: 9, color: _grey)),
            ],
          ),
          if (subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 10, color: _accent),
            ),
          if (body.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(body, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.5)),
          ],
        ],
      ),
    );
  }
}
