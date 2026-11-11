import '../models/resume.dart';

class ScoreSuggestion {
  final String title;
  final String detail;
  final bool isPositive;

  ScoreSuggestion({
    required this.title,
    required this.detail,
    required this.isPositive,
  });
}

class ResumeScoreResult {
  final int score; // 0-100
  final List<ScoreSuggestion> suggestions;

  ResumeScoreResult({required this.score, required this.suggestions});
}

/// A lightweight, deterministic completeness/ATS-friendliness score.
///
/// This is not a machine-learning model — it checks the same structural
/// signals a human reviewer or an ATS parser looks for: contact info,
/// a real summary, quantifiable experience, and a reasonable skill count.
class ResumeScorer {
  static ResumeScoreResult score(Resume r) {
    var points = 0;
    const maxPoints = 100;
    final suggestions = <ScoreSuggestion>[];

    // Contact info (15 pts)
    final hasContact =
        r.fullName.isNotEmpty && r.email.isNotEmpty && r.phone.isNotEmpty;
    if (hasContact) {
      points += 15;
      suggestions.add(
        ScoreSuggestion(
          title: 'Contact info complete',
          detail: 'Name, email and phone are all filled in.',
          isPositive: true,
        ),
      );
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add complete contact info',
          detail: 'Fill in your name, email and phone so recruiters can reach you.',
          isPositive: false,
        ),
      );
    }

    // Professional title (10 pts)
    if (r.professionalTitle.isNotEmpty) {
      points += 10;
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add a professional title',
          detail: 'A clear title like "Senior Backend Engineer" helps ATS keyword matching.',
          isPositive: false,
        ),
      );
    }

    // Summary (15 pts)
    final summaryLen = r.professionalSummary.trim().length;
    if (summaryLen >= 80) {
      points += 15;
      suggestions.add(
        ScoreSuggestion(
          title: 'Strong summary',
          detail: 'Your summary gives recruiters a quick, clear pitch.',
          isPositive: true,
        ),
      );
    } else if (summaryLen > 0) {
      points += 7;
      suggestions.add(
        ScoreSuggestion(
          title: 'Expand your summary',
          detail: 'Aim for 2-3 sentences (roughly 80+ characters) covering your experience and strengths.',
          isPositive: false,
        ),
      );
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add a professional summary',
          detail: 'A short summary at the top helps recruiters decide to keep reading.',
          isPositive: false,
        ),
      );
    }

    // Experience (25 pts)
    if (r.experience.isNotEmpty) {
      final hasDetailedDescription = r.experience.any(
        (e) => e.description.trim().length >= 40,
      );
      points += hasDetailedDescription ? 25 : 15;
      if (!hasDetailedDescription) {
        suggestions.add(
          ScoreSuggestion(
            title: 'Add detail to your experience',
            detail: 'Describe responsibilities and results (ideally with numbers) for each role.',
            isPositive: false,
          ),
        );
      } else {
        suggestions.add(
          ScoreSuggestion(
            title: 'Experience is well described',
            detail: 'Your work history includes meaningful detail.',
            isPositive: true,
          ),
        );
      }
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add work experience',
          detail: 'At least one role — even an internship or freelance project — strengthens your resume.',
          isPositive: false,
        ),
      );
    }

    // Education (10 pts)
    if (r.education.isNotEmpty) {
      points += 10;
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add your education',
          detail: 'Include your degree, school, and field of study.',
          isPositive: false,
        ),
      );
    }

    // Skills (15 pts)
    if (r.skills.length >= 6) {
      points += 15;
      suggestions.add(
        ScoreSuggestion(
          title: 'Good range of skills',
          detail: '${r.skills.length} skills listed helps you match more job keywords.',
          isPositive: true,
        ),
      );
    } else if (r.skills.isNotEmpty) {
      points += 8;
      suggestions.add(
        ScoreSuggestion(
          title: 'Add more skills',
          detail: 'You have ${r.skills.length}. Aim for at least 6-10 relevant skills.',
          isPositive: false,
        ),
      );
    } else {
      suggestions.add(
        ScoreSuggestion(
          title: 'Add your skills',
          detail: 'List technical and soft skills relevant to the roles you want.',
          isPositive: false,
        ),
      );
    }

    // Projects / certifications / achievements (10 pts, up to 3.33 each)
    var extras = 0;
    if (r.projects.isNotEmpty) extras++;
    if (r.certifications.isNotEmpty) extras++;
    if (r.achievements.isNotEmpty) extras++;
    points += (extras * 10 / 3).round();
    if (extras < 2) {
      suggestions.add(
        ScoreSuggestion(
          title: 'Round it out',
          detail: 'Adding projects, certifications, or achievements makes your profile stand out.',
          isPositive: false,
        ),
      );
    }

    final clamped = points.clamp(0, maxPoints);

    // Positive suggestions first, then the actionable ones.
    suggestions.sort((a, b) {
      if (a.isPositive == b.isPositive) return 0;
      return a.isPositive ? -1 : 1;
    });

    return ResumeScoreResult(score: clamped, suggestions: suggestions);
  }
}
