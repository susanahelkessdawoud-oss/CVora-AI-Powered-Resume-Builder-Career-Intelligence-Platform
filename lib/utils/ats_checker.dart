import '../models/resume.dart';

class AtsCheck {
  final String label;
  final int points;
  final bool passed;
  final String detail;

  AtsCheck({
    required this.label,
    required this.points,
    required this.passed,
    required this.detail,
  });
}

class AtsCheckResult {
  final int score; // 0-100
  final List<AtsCheck> checks;

  AtsCheckResult({required this.score, required this.checks});

  List<String> get failedLabels =>
      checks.where((c) => !c.passed).map((c) => c.label).toList();
}

/// Deterministic ATS-parsing/formatting checks, independent of the general
/// completeness score in [ResumeScorer]. Mirrors what an ATS text-extraction
/// pass and keyword scan actually look for: parseable contact fields,
/// standard section presence, consistent dates, clean characters, and a
/// substantial-enough body of text to keyword-match against.
class AtsChecker {
  static final RegExp _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phoneDigits = RegExp(r'\d');

  // Curly quotes, bullets, dashes and emoji/symbol ranges that some ATS
  // text extractors mangle or drop.
  static final RegExp _unsafeChars =
      RegExp('[‘’“”•‣◦–—'
          '\u{1F300}-\u{1FAFF}☀-➿]', unicode: true);

  static final RegExp _dateLike =
      RegExp(r'^(present|current)$|\b\d{4}\b', caseSensitive: false);

  static AtsCheckResult check(Resume r) {
    final checks = <AtsCheck>[];

    final hasName = r.fullName.trim().isNotEmpty;
    checks.add(AtsCheck(
      label: 'Parseable full name',
      points: 10,
      passed: hasName,
      detail: hasName
          ? 'Full name is present.'
          : 'No full name — ATS systems often reject resumes with no name field.',
    ));

    final emailOk = _emailFormat.hasMatch(r.email.trim());
    checks.add(AtsCheck(
      label: 'Valid email format',
      points: 10,
      passed: emailOk,
      detail: emailOk
          ? 'Email is present and well-formed.'
          : 'Email is missing or not in a standard address@domain format.',
    ));

    final phoneOk = _phoneDigits.hasMatch(r.phone);
    checks.add(AtsCheck(
      label: 'Phone number present',
      points: 5,
      passed: phoneOk,
      detail: phoneOk
          ? 'Phone number is present.'
          : 'No phone number found — recruiters and ATS contact cards expect one.',
    ));

    final hasSummary = r.professionalSummary.trim().length >= 40;
    checks.add(AtsCheck(
      label: 'Summary section detected',
      points: 10,
      passed: hasSummary,
      detail: hasSummary
          ? 'A substantive summary section was found.'
          : 'Summary is missing or too short for an ATS to treat it as a real section.',
    ));

    final hasExperience = r.experience.isNotEmpty;
    checks.add(AtsCheck(
      label: 'Experience section detected',
      points: 15,
      passed: hasExperience,
      detail: hasExperience
          ? '${r.experience.length} experience entr${r.experience.length == 1 ? 'y' : 'ies'} found.'
          : 'No work experience entries — most ATS systems expect this section.',
    ));

    final hasEducation = r.education.isNotEmpty;
    checks.add(AtsCheck(
      label: 'Education section detected',
      points: 10,
      passed: hasEducation,
      detail: hasEducation
          ? 'Education section found.'
          : 'No education entries — this is a standard ATS-expected section.',
    ));

    final hasSkills = r.skills.length >= 3;
    checks.add(AtsCheck(
      label: 'Skills section detected',
      points: 10,
      passed: hasSkills,
      detail: hasSkills
          ? '${r.skills.length} skills listed for keyword matching.'
          : 'Fewer than 3 skills listed — too little for meaningful keyword matching.',
    ));

    final datesConsistent = r.experience.isEmpty ||
        r.experience.every((e) =>
            e.startDate.trim().isEmpty || _dateLike.hasMatch(e.startDate.trim()));
    checks.add(AtsCheck(
      label: 'Consistent date formatting',
      points: 10,
      passed: datesConsistent,
      detail: datesConsistent
          ? 'Experience dates look consistent and parseable.'
          : 'Some experience dates don\'t look like a standard year/range — ATS date parsers can choke on these.',
    ));

    final bodyText = [
      r.professionalSummary,
      ...r.experience.map((e) => e.description),
      ...r.education.map((e) => '${e.degree} ${e.fieldOfStudy}'),
    ].join(' ');
    final cleanChars = !_unsafeChars.hasMatch(bodyText);
    checks.add(AtsCheck(
      label: 'No ATS-unsafe characters',
      points: 10,
      passed: cleanChars,
      detail: cleanChars
          ? 'No curly quotes, bullets, dashes or symbols that some parsers mangle.'
          : 'Found characters (curly quotes, bullets, em-dashes, emoji) that some ATS text extractors drop or mangle.',
    ));

    final wordCount = [
      r.professionalSummary,
      ...r.experience.map((e) => e.description),
      ...r.skills,
    ].join(' ').trim();
    final enoughContent =
        wordCount.isNotEmpty && wordCount.split(RegExp(r'\s+')).length >= 40;
    checks.add(AtsCheck(
      label: 'Enough content for keyword matching',
      points: 10,
      passed: enoughContent,
      detail: enoughContent
          ? 'Enough body text for a keyword scan to have something to match against.'
          : 'Too little total text (summary + experience + skills) for keyword matching to be meaningful.',
    ));

    final total = checks.fold<int>(0, (sum, c) => sum + (c.passed ? c.points : 0));
    return AtsCheckResult(score: total.clamp(0, 100), checks: checks);
  }
}
