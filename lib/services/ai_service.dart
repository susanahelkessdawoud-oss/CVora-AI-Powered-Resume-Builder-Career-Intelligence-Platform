import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../secrets.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  GenerativeModel? _model;

  // The full "gemini-flash-latest" model routes to whatever is the newest
  // flagship release, which tends to run hot with demand (frequent 503
  // "high demand" errors). The lite variant is materially more available
  // in practice and is more than capable for these short rewrite tasks.
  GenerativeModel get _client {
    return _model ??= GenerativeModel(
      model: 'gemini-flash-lite-latest',
      apiKey: geminiApiKey,
    );
  }

  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  Future<String> _generate(String prompt) =>
      _generateFromContent([Content.text(prompt)]);

  Future<String> _generateFromContent(List<Content> content) async {
    if (geminiApiKey.isEmpty) {
      throw StateError(
        'No Gemini API key configured. Add one to lib/secrets.dart.',
      );
    }

    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _client.generateContent(content);
        final text = response.text?.trim();
        if (text == null || text.isEmpty) {
          throw StateError('Gemini returned an empty response.');
        }
        return text;
      } on ServerException catch (_) {
        if (attempt >= _retryDelays.length) rethrow;
        await Future.delayed(_retryDelays[attempt]);
      }
    }
  }

  /// Calls Gemini expecting a strict-JSON reply and decodes it, stripping
  /// a ```json fence if the model added one despite being told not to.
  Future<Map<String, dynamic>> _generateJson(List<Content> content) async {
    final raw = await _generateFromContent(content);
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Expected a JSON object.');
    } catch (e) {
      throw StateError('Gemini returned malformed JSON: $e');
    }
  }

  Future<String> improveSummary({
    required String currentText,
    String? jobTitle,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a resume-writing assistant. Rewrite the professional '
        'summary below so it is more compelling, concise and '
        'achievement-oriented.',
      )
      ..writeln(
        'Reply with ONLY the rewritten summary text: 2-4 sentences, no '
        'markdown, no quotes, no preamble.',
      );
    if (jobTitle != null && jobTitle.trim().isNotEmpty) {
      prompt.writeln('The candidate\'s target role is: ${jobTitle.trim()}.');
    }
    prompt.writeln('Current summary:');
    prompt.writeln(_orPlaceholder(
      currentText,
      '(empty — write a strong generic starting point the candidate can edit)',
    ));
    return _generate(prompt.toString());
  }

  Future<String> improveExperienceDescription({
    required String currentText,
    String? position,
    String? company,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a resume-writing assistant. Rewrite the work experience '
        'bullet/description below so it leads with strong action verbs, '
        'highlights measurable impact where plausible, and reads '
        'concisely.',
      )
      ..writeln(
        'Reply with ONLY the rewritten description text: 1-3 short '
        'sentences or bullet lines, no markdown headers, no preamble.',
      );
    final role = [
      if (position != null && position.trim().isNotEmpty) position.trim(),
      if (company != null && company.trim().isNotEmpty) company.trim(),
    ].join(' at ');
    if (role.isNotEmpty) {
      prompt.writeln('Role: $role.');
    }
    prompt.writeln('Current description:');
    prompt.writeln(_orPlaceholder(
      currentText,
      '(empty — write a strong generic starting point for this role that '
      'the candidate can edit)',
    ));
    return _generate(prompt.toString());
  }

  Future<String> improveAchievementDescription({
    required String currentText,
    String? title,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a resume-writing assistant. Rewrite the achievement '
        'description below so it is concise and clearly states the '
        'impact or recognition involved.',
      )
      ..writeln(
        'Reply with ONLY the rewritten description text: 1-2 short '
        'sentences, no markdown, no preamble.',
      );
    if (title != null && title.trim().isNotEmpty) {
      prompt.writeln('Achievement title: ${title.trim()}.');
    }
    prompt.writeln('Current description:');
    prompt.writeln(_orPlaceholder(
      currentText,
      '(empty — write a strong generic starting point the candidate can edit)',
    ));
    return _generate(prompt.toString());
  }

  Future<String> jobMatchAdvice({
    required String jobDescription,
    required String resumeSummary,
    required List<String> matchedKeywords,
    required List<String> missingKeywords,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a career coach helping a candidate tailor their resume '
        'to a specific job posting.',
      )
      ..writeln(
        'Give 2-4 short, specific, actionable sentences of advice on how '
        'they could honestly strengthen their resume for this role. '
        'Do not invent experience they do not have — only suggest '
        'rewording, reordering, or emphasizing things they may already '
        'do. No markdown, no preamble, no bullet points.',
      )
      ..writeln('Job description:')
      ..writeln(jobDescription.trim())
      ..writeln('Candidate\'s current resume summary:')
      ..writeln(_orPlaceholder(resumeSummary, '(none provided)'))
      ..writeln('Keywords already matched: ${matchedKeywords.join(', ')}')
      ..writeln('Keywords missing: ${missingKeywords.join(', ')}');
    return _generate(prompt.toString());
  }

  Future<String> resumeFeedback({
    required String resumeText,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are an experienced resume reviewer. Read the resume content '
        'below and give focused, encouraging feedback.',
      )
      ..writeln(
        'Reply with 3-5 short sentences covering the single most '
        'impactful improvement the candidate could make next. No '
        'markdown, no preamble, no bullet points.',
      )
      ..writeln('Resume content:')
      ..writeln(resumeText.trim());
    return _generate(prompt.toString());
  }

  Future<String> atsFeedback({
    required String resumeText,
    List<String> failedChecks = const [],
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are an ATS (Applicant Tracking System) optimization expert.',
      )
      ..writeln(
        'Review the resume content below purely for ATS compatibility and '
        'keyword strength: standard section naming, action verbs, '
        'quantifiable results, and any jargon, acronyms or phrasing an '
        'ATS keyword search or resume parser might miss or choke on.',
      )
      ..writeln(
        'Reply with 3-5 short, specific, actionable sentences. No '
        'markdown, no preamble, no bullet points.',
      )
      ..writeln('Resume content:')
      ..writeln(resumeText.trim());
    if (failedChecks.isNotEmpty) {
      prompt.writeln(
        'Automated checks already flagged: ${failedChecks.join(', ')}. '
        'Address these directly.',
      );
    }
    return _generate(prompt.toString());
  }

  Future<String> generateCoverLetter({
    required String fullName,
    required String jobTitle,
    required String resumeSummary,
    required List<String> skills,
    required String experienceHighlights,
    required String jobDescription,
    String? companyName,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a professional cover-letter writer. Write a complete, '
        'ready-to-send cover letter for the candidate described below, '
        'tailored to the job description that follows.',
      )
      ..writeln(
        'Rules: 3-4 short paragraphs, professional and warm tone, no '
        'markdown, no placeholders like [Company Name] — use the real '
        'company name if given or refer to "your team" if not. Do not '
        'invent specific employers, dates or credentials beyond what is '
        'given. Open with a greeting and close with a sign-off using the '
        'candidate\'s name.',
      )
      ..writeln('Candidate name: $fullName')
      ..writeln('Candidate target role: $jobTitle')
      ..writeln(
          'Candidate summary: ${_orPlaceholder(resumeSummary, '(none)')}')
      ..writeln('Candidate skills: ${skills.isEmpty ? '(none listed)' : skills.join(', ')}')
      ..writeln(
          'Candidate experience highlights: ${_orPlaceholder(experienceHighlights, '(none listed)')}')
      ..writeln(
          'Company: ${companyName != null && companyName.trim().isNotEmpty ? companyName.trim() : '(not specified)'}')
      ..writeln('Job description:')
      ..writeln(jobDescription.trim());
    return _generate(prompt.toString());
  }

  /// AI Engine 1 — Document Understanding.
  ///
  /// Sends a PDF/DOCX resume file directly to Gemini (multimodal input) and
  /// asks it to extract the content into our Resume JSON shape. The caller
  /// is responsible for letting the user review/edit before saving — this
  /// never writes to the database itself.
  Future<Map<String, dynamic>> parseResumeDocument({
    required Uint8List bytes,
    required String mimeType,
  }) {
    const prompt = '''
You are a resume-parsing assistant. Read the attached document and extract
its content into the exact JSON shape below. Use "" for any text field you
cannot find, and [] for any list you cannot find. Do not invent information
that is not in the document. Respond with ONLY the JSON object — no
markdown fences, no commentary.

{
  "fullName": "",
  "email": "",
  "phone": "",
  "location": "",
  "professionalTitle": "",
  "professionalSummary": "",
  "education": [{"school": "", "degree": "", "fieldOfStudy": "", "startDate": "", "endDate": "", "description": ""}],
  "experience": [{"jobTitle": "", "company": "", "startDate": "", "endDate": "", "description": "", "isCurrentJob": false}],
  "skills": [""],
  "projects": [{"name": "", "description": "", "link": "", "technologies": "", "startDate": "", "endDate": ""}],
  "achievements": [{"title": "", "description": "", "date": ""}],
  "certifications": [{"name": "", "issuedBy": "", "issueDate": "", "expiryDate": "", "link": ""}]
}
''';
    return _generateJson([
      Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
    ]);
  }

  /// AI Engine 3 — Resume Evaluation.
  ///
  /// Produces an explainable, category-scored evaluation rather than a
  /// single opaque number — each category carries its own score and a
  /// one-line reason so the UI can show *why*, not just *what*.
  Future<Map<String, dynamic>> analyzeResume({
    required String resumeText,
  }) {
    final prompt = '''
You are an expert resume reviewer. Evaluate the resume content below across
exactly these categories: "Content Quality", "Professional Language",
"Experience Impact", "Skills Relevance", "Structure & Completeness".

For each category give a 0-100 score and a one-sentence reason. Also give an
overall 0-100 score (a holistic judgment, not necessarily the average),
3-5 strengths, 3-5 weaknesses, and up to 3 critical issues that would hurt
the candidate most. Be honest and specific — do not inflate scores.

Respond with ONLY this exact JSON shape, no markdown fences, no commentary:
{
  "overallScore": 0,
  "categories": [{"name": "", "score": 0, "reason": ""}],
  "strengths": [""],
  "weaknesses": [""],
  "criticalIssues": [""]
}

Resume content:
${resumeText.trim()}
''';
    return _generateJson([Content.text(prompt)]);
  }

  /// AI Engine 5/6 (Skills Intelligence).
  ///
  /// Categorizes the candidate's existing skills and — only when a job
  /// description is supplied — identifies genuine gaps against it. Never
  /// invents skills the candidate doesn't already list; recommendations are
  /// clearly separated as "to learn", not asserted as already possessed.
  Future<Map<String, dynamic>> analyzeSkills({
    required List<String> skills,
    required String resumeText,
    String? jobDescription,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a career/skills analyst. The candidate lists these skills: '
        '${skills.isEmpty ? '(none listed)' : skills.join(', ')}.',
      )
      ..writeln('Full resume content for context:')
      ..writeln(resumeText.trim())
      ..writeln();
    if (jobDescription != null && jobDescription.trim().isNotEmpty) {
      prompt
        ..writeln('Target job description:')
        ..writeln(jobDescription.trim())
        ..writeln(
          'Compare the candidate\'s listed skills against this job and '
          'identify genuine gaps.',
        );
    } else {
      prompt.writeln(
        'No specific job was given — base gap suggestions on what is '
        'generally expected for the candidate\'s apparent target role.',
      );
    }
    prompt.writeln(
      'Categorize ONLY the skills the candidate actually listed (never '
      'invent a skill they don\'t have) into technical / soft / tools / '
      'languages. Flag any near-duplicates (e.g. "JS" and "JavaScript"). '
      'Separately, list skill gaps as things to learn — these must be '
      'clearly recommendations, not claims the candidate already has them. '
      'Suggest up to 3 portfolio project ideas that would demonstrate the '
      'missing skills.',
    );
    prompt.writeln(
      'Respond with ONLY this exact JSON shape, no markdown fences, no '
      'commentary:',
    );
    prompt.writeln('''
{
  "categorized": {"technical": [""], "soft": [""], "tools": [""], "languages": [""]},
  "duplicates": [{"skills": [""], "suggestion": ""}],
  "gaps": [{"skill": "", "reason": ""}],
  "suggestedProjects": [{"title": "", "description": ""}]
}''');
    return _generateJson([Content.text(prompt.toString())]);
  }

  /// Screen 13 — AI CV Optimizer.
  ///
  /// Produces job-targeted rewrites keyed by the position of each
  /// experience/project entry (these models have no stable server id), so
  /// the caller can show before/after and apply only the ones the user
  /// accepts. Never invents experience — only rewrites what's given.
  Future<Map<String, dynamic>> optimizeForJob({
    required String resumeSummary,
    required List<String> experienceDescriptions,
    required List<String> projectDescriptions,
    required List<String> skills,
    required String jobDescription,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a resume optimization expert. Tailor the candidate\'s '
        'existing resume content to the job description below. Rewrite '
        'for relevance and impact — do NOT invent employers, dates, '
        'metrics, or skills that aren\'t implied by the original text.',
      )
      ..writeln('Job description:')
      ..writeln(jobDescription.trim())
      ..writeln()
      ..writeln('Current professional summary:')
      ..writeln(_orPlaceholder(resumeSummary, '(none)'))
      ..writeln()
      ..writeln('Current skills: ${skills.isEmpty ? '(none)' : skills.join(', ')}')
      ..writeln();
    for (var i = 0; i < experienceDescriptions.length; i++) {
      prompt.writeln('Experience entry $i description:');
      prompt.writeln(_orPlaceholder(experienceDescriptions[i], '(empty)'));
    }
    for (var i = 0; i < projectDescriptions.length; i++) {
      prompt.writeln('Project entry $i description:');
      prompt.writeln(_orPlaceholder(projectDescriptions[i], '(empty)'));
    }
    prompt.writeln(
      'Respond with ONLY this exact JSON shape, no markdown fences, no '
      'commentary. Omit an experience/project entry from the arrays only '
      'if you have nothing meaningful to change.',
    );
    prompt.writeln('''
{
  "optimizedSummary": "",
  "experience": [{"index": 0, "optimizedDescription": ""}],
  "projects": [{"index": 0, "optimizedDescription": ""}],
  "keywordsToAdd": [""]
}''');
    return _generateJson([Content.text(prompt.toString())]);
  }

  /// Screen 16 — AI Interview Coach: question generation.
  ///
  /// Mixes technical, behavioral, CV-based and (when a job is given)
  /// job-specific questions, grounded in the candidate's actual background.
  Future<Map<String, dynamic>> generateInterviewQuestions({
    required String resumeSummary,
    required String experienceHighlights,
    required List<String> skills,
    String? jobDescription,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are an experienced technical interviewer preparing a mock '
        'interview for this candidate.',
      )
      ..writeln('Candidate summary: ${_orPlaceholder(resumeSummary, '(none)')}')
      ..writeln(
          'Candidate experience: ${_orPlaceholder(experienceHighlights, '(none)')}')
      ..writeln('Candidate skills: ${skills.isEmpty ? '(none)' : skills.join(', ')}');
    if (jobDescription != null && jobDescription.trim().isNotEmpty) {
      prompt
        ..writeln('Target job description:')
        ..writeln(jobDescription.trim());
    }
    prompt.writeln(
      'Generate exactly 6 interview questions: 2 technical (grounded in '
      'their actual listed skills), 2 behavioral, 1 that asks them to go '
      'deeper on something specific from their CV, and 1 that relates to '
      'the target job if one was given (otherwise another behavioral '
      'question). Each question should be answerable in a few sentences.',
    );
    prompt.writeln(
      'Respond with ONLY this exact JSON shape, no markdown fences, no '
      'commentary:',
    );
    prompt.writeln('''
{"questions": [{"question": "", "type": "technical|behavioral|cv-based|job-specific"}]}''');
    return _generateJson([Content.text(prompt.toString())]);
  }

  /// Screen 16 — AI Interview Coach: answer evaluation.
  Future<Map<String, dynamic>> evaluateInterviewAnswer({
    required String question,
    required String answer,
  }) {
    final prompt = '''
You are an interview coach. Evaluate the candidate's answer to this
interview question.

Question: ${question.trim()}
Candidate's answer: ${_orPlaceholder(answer, '(no answer given)')}

Give a 0-100 score for how well the answer addresses the question
(clarity, relevance, structure, specificity), plus 2-3 short, specific,
constructive sentences of feedback — including what to improve. Do not
be falsely encouraging; be honest.

Respond with ONLY this exact JSON shape, no markdown fences, no commentary:
{"score": 0, "feedback": ""}
''';
    return _generateJson([Content.text(prompt)]);
  }

  /// Screen 17 — AI Career Advisor.
  ///
  /// Grounds every recommendation in the candidate's actual background —
  /// no generic "learn to code" filler.
  Future<Map<String, dynamic>> careerRecommendations({
    required String resumeText,
    required List<String> skills,
    String? careerInterests,
  }) {
    final prompt = StringBuffer()
      ..writeln(
        'You are a career advisor. Base every recommendation below on the '
        'candidate\'s actual background — explain WHY each one fits them '
        'specifically, not generic advice.',
      )
      ..writeln('Resume content:')
      ..writeln(resumeText.trim())
      ..writeln('Skills: ${skills.isEmpty ? '(none)' : skills.join(', ')}');
    if (careerInterests != null && careerInterests.trim().isNotEmpty) {
      prompt.writeln('Stated career interests: ${careerInterests.trim()}');
    }
    prompt.writeln(
      'Suggest 2-3 suitable job roles, 3-5 skills to develop next (with '
      'why), and a 3-phase learning roadmap (short/medium/long term). Each '
      'item must include a one-sentence reason tied to their actual '
      'background.',
    );
    prompt.writeln(
      'Respond with ONLY this exact JSON shape, no markdown fences, no '
      'commentary:',
    );
    prompt.writeln('''
{
  "suggestedRoles": [{"role": "", "why": ""}],
  "skillsToDevelop": [{"skill": "", "why": ""}],
  "roadmap": [{"phase": "", "focus": ""}]
}''');
    return _generateJson([Content.text(prompt.toString())]);
  }

  String _orPlaceholder(String text, String placeholder) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? placeholder : trimmed;
  }
}
