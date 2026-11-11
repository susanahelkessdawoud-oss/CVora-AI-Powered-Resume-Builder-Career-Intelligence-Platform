import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/resume.dart';

/// Builds a minimal but valid .docx (OOXML) resume export, hand-constructed
/// as a zip of XML parts — no external docx-template dependency, so there
/// are no proprietary template limitations. Mirrors [PdfService]'s section
/// ordering so the two exports stay consistent.
class DocxService {
  static Future<Uint8List> buildResumeDocx(Resume resume) async {
    final body = StringBuffer();

    body.write(_heading(resume.fullName.isEmpty ? 'Untitled' : resume.fullName, size: 36));
    if (resume.professionalTitle.isNotEmpty) {
      body.write(_paragraph(resume.professionalTitle, bold: true, color: '7C3AED'));
    }
    final contact = [resume.email, resume.phone, resume.location]
        .where((s) => s.isNotEmpty)
        .join('   •   ');
    if (contact.isNotEmpty) {
      body.write(_paragraph(contact, size: 19, color: '6B7280'));
    }
    body.write(_emptyParagraph());

    if (resume.professionalSummary.trim().isNotEmpty) {
      body.write(_sectionTitle('Summary'));
      body.write(_paragraph(resume.professionalSummary));
    }

    if (resume.experience.isNotEmpty) {
      body.write(_sectionTitle('Experience'));
      for (final e in resume.experience) {
        final dates = _dateRange(e.startDate, e.endDate);
        body.write(_entryHeading(e.jobTitle, e.company, dates));
        if (e.description.isNotEmpty) body.write(_paragraph(e.description));
      }
    }

    if (resume.education.isNotEmpty) {
      body.write(_sectionTitle('Education'));
      for (final e in resume.education) {
        final dates = _dateRange(e.startDate, e.endDate);
        final title = e.degree.isEmpty ? e.fieldOfStudy : e.degree;
        body.write(_entryHeading(title, e.school, dates));
        if (e.fieldOfStudy.isNotEmpty && e.degree.isNotEmpty) {
          body.write(_paragraph(e.fieldOfStudy));
        }
      }
    }

    if (resume.projects.isNotEmpty) {
      body.write(_sectionTitle('Projects'));
      for (final p in resume.projects) {
        body.write(_entryHeading(p.name, p.link, _dateRange(p.startDate, p.endDate)));
        if (p.description.isNotEmpty) body.write(_paragraph(p.description));
      }
    }

    if (resume.skills.isNotEmpty) {
      body.write(_sectionTitle('Skills'));
      body.write(_paragraph(resume.skills.join('   •   ')));
    }

    if (resume.certifications.isNotEmpty) {
      body.write(_sectionTitle('Certifications'));
      for (final c in resume.certifications) {
        body.write(_entryHeading(c.name, c.issuedBy, c.issueDate));
      }
    }

    if (resume.achievements.isNotEmpty) {
      body.write(_sectionTitle('Achievements'));
      for (final a in resume.achievements) {
        body.write(_entryHeading(a.title, '', a.date));
        if (a.description.isNotEmpty) body.write(_paragraph(a.description));
      }
    }

    return _package(body.toString());
  }

  static String _dateRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _run(String text, {bool bold = false, int size = 22, String? color}) {
    final props = StringBuffer('<w:rPr>');
    if (bold) props.write('<w:b/>');
    props.write('<w:sz w:val="$size"/><w:szCs w:val="$size"/>');
    if (color != null) props.write('<w:color w:val="$color"/>');
    props.write('</w:rPr>');
    return '<w:r>$props<w:t xml:space="preserve">${_escape(text)}</w:t></w:r>';
  }

  static String _paragraph(String text, {bool bold = false, int size = 22, String? color}) {
    return '<w:p><w:pPr><w:spacing w:after="160"/></w:pPr>${_run(text, bold: bold, size: size, color: color)}</w:p>';
  }

  static String _heading(String text, {int size = 32}) {
    return '<w:p><w:pPr><w:spacing w:after="80"/></w:pPr>${_run(text, bold: true, size: size)}</w:p>';
  }

  static String _sectionTitle(String text) {
    return '<w:p><w:pPr><w:spacing w:before="200" w:after="120"/>'
        '<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="4" w:color="7C3AED"/></w:pBdr></w:pPr>'
        '${_run(text.toUpperCase(), bold: true, size: 22, color: '7C3AED')}</w:p>';
  }

  static String _entryHeading(String title, String subtitle, String dates) {
    final parts = StringBuffer('<w:p><w:pPr><w:spacing w:after="40"/></w:pPr>');
    parts.write(_run(title.isEmpty ? subtitle : title, bold: true));
    if (dates.isNotEmpty) {
      parts.write(_run('   —   $dates', size: 19, color: '6B7280'));
    }
    parts.write('</w:p>');
    if (subtitle.isNotEmpty && title.isNotEmpty) {
      parts.write(_paragraph(subtitle, size: 20, color: '7C3AED'));
    }
    return parts.toString();
  }

  static String _emptyParagraph() => '<w:p/>';

  static Future<Uint8List> _package(String bodyXml) async {
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    const documentRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';

    final document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $bodyXml
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000"/>
    </w:sectPr>
  </w:body>
</w:document>''';

    final archive = Archive();
    void addFile(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    addFile('[Content_Types].xml', contentTypes);
    addFile('_rels/.rels', rootRels);
    addFile('word/document.xml', document);
    addFile('word/_rels/document.xml.rels', documentRels);

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }
}
