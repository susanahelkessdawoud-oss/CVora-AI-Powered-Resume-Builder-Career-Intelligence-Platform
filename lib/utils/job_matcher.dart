import '../models/resume.dart';

class JobMatchResult {
  final int matchPercent;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;

  JobMatchResult({
    required this.matchPercent,
    required this.matchedKeywords,
    required this.missingKeywords,
  });
}

/// Simple keyword-overlap matcher between a resume and a job description.
///
/// This mirrors what a basic ATS keyword scan does: it is not semantic
/// matching, just literal keyword presence, which is exactly what a lot of
/// real screening tools check.
class JobMatcher {
  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'with', 'you', 'your', 'are', 'will', 'this',
    'that', 'have', 'has', 'from', 'our', 'we', 'a', 'an', 'to', 'of',
    'in', 'on', 'at', 'is', 'as', 'be', 'or', 'by', 'it', 'their', 'they',
    'who', 'all', 'any', 'can', 'may', 'per', 'etc', 'job', 'role',
    'work', 'working', 'team', 'skills', 'experience', 'years', 'year',
    'about', 'into', 'across', 'including', 'must', 'should', 'strong',
    'ability', 'looking', 'candidate', 'candidates', 'us', 'we\'re',
  };

  static List<String> _tokenize(String text) {
    final words = RegExp(
      r"[a-zA-Z][a-zA-Z0-9+#.\-]{1,}",
    ).allMatches(text).map((m) => m.group(0)!.toLowerCase()).toList();
    return words
        .where((w) => w.length >= 3 && !_stopWords.contains(w))
        .toList();
  }

  static JobMatchResult match(Resume resume, String jobDescription) {
    final corpusBuffer = StringBuffer()
      ..writeln(resume.professionalTitle)
      ..writeln(resume.professionalSummary)
      ..writeln(resume.skills.join(' '));
    for (final e in resume.experience) {
      corpusBuffer
        ..writeln(e.jobTitle)
        ..writeln(e.description);
    }
    for (final p in resume.projects) {
      corpusBuffer
        ..writeln(p.name)
        ..writeln(p.description)
        ..writeln(p.technologies);
    }
    for (final c in resume.certifications) {
      corpusBuffer.writeln(c.name);
    }
    final corpus = corpusBuffer.toString().toLowerCase();

    // Rank job-description keywords by frequency and keep the most
    // significant ones, so a huge job posting doesn't dilute the score.
    final counts = <String, int>{};
    for (final word in _tokenize(jobDescription)) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
    final keywords = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final topKeywords = keywords.take(30).toList();

    if (topKeywords.isEmpty) {
      return JobMatchResult(matchPercent: 0, matchedKeywords: [], missingKeywords: []);
    }

    final matched = <String>[];
    final missing = <String>[];
    for (final keyword in topKeywords) {
      if (corpus.contains(keyword)) {
        matched.add(keyword);
      } else {
        missing.add(keyword);
      }
    }

    final percent = ((matched.length / topKeywords.length) * 100).round();
    return JobMatchResult(
      matchPercent: percent,
      matchedKeywords: matched,
      missingKeywords: missing,
    );
  }
}
