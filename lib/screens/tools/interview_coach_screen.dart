import 'package:flutter/material.dart';

import '../../models/interview.dart';
import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

/// Screen 16 — AI Interview Coach.
///
/// Generates a mix of technical/behavioral/CV-based/job-specific questions
/// grounded in the candidate's actual resume, runs a simple multi-turn
/// session (one question at a time), evaluates each answer honestly, and
/// persists the session so past practice rounds can be reviewed.
class InterviewCoachScreen extends StatefulWidget {
  const InterviewCoachScreen({super.key});

  @override
  State<InterviewCoachScreen> createState() => _InterviewCoachScreenState();
}

enum _Mode { setup, interviewing, summary, history }

class _InterviewCoachScreenState extends State<InterviewCoachScreen> {
  late final TextEditingController jobDescriptionController;
  late final TextEditingController answerController;
  late Future<List<Resume>> resumesFuture;

  Resume? selected;
  _Mode mode = _Mode.setup;
  bool busy = false;
  String? error;

  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  InterviewSession? session;
  final List<InterviewAnswer> answeredSoFar = [];
  Map<String, dynamic>? lastEvaluation;

  List<InterviewSession> history = [];
  List<InterviewAnswer>? historyDetail;

  @override
  void initState() {
    super.initState();
    jobDescriptionController = TextEditingController();
    answerController = TextEditingController();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  @override
  void dispose() {
    jobDescriptionController.dispose();
    answerController.dispose();
    super.dispose();
  }

  String get _userId => AuthService.instance.currentUser?.id ?? '';

  Future<void> _startInterview() async {
    final resume = selected;
    if (resume == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await AiService.instance.generateInterviewQuestions(
        resumeSummary: resume.professionalSummary,
        experienceHighlights: resume.experience
            .map((e) => '${e.jobTitle} at ${e.company}: ${e.description}')
            .join('\n'),
        skills: resume.skills,
        jobDescription: jobDescriptionController.text.trim().isEmpty
            ? null
            : jobDescriptionController.text,
      );
      final newSession = await DatabaseService.instance.createInterviewSession(
        userId: _userId,
        resumeId: resume.id.isEmpty ? null : resume.id,
        jobDescription: jobDescriptionController.text,
      );
      if (!mounted) return;
      setState(() {
        questions = (result['questions'] as List? ?? const [])
            .cast<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
        session = newSession;
        currentIndex = 0;
        answeredSoFar.clear();
        lastEvaluation = null;
        answerController.clear();
        mode = _Mode.interviewing;
      });
    } catch (e) {
      if (mounted) setState(() => error = 'Could not start the interview. Try again in a moment.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submitAnswer() async {
    final s = session;
    if (s == null || currentIndex >= questions.length) return;
    final q = questions[currentIndex];
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final evaluation = await AiService.instance.evaluateInterviewAnswer(
        question: q['question'] as String? ?? '',
        answer: answerController.text,
      );
      final saved = await DatabaseService.instance.addInterviewAnswer(
        sessionId: s.id,
        userId: _userId,
        question: q['question'] as String? ?? '',
        questionType: q['type'] as String? ?? 'behavioral',
        answer: answerController.text,
        feedback: (evaluation['feedback'] as String?) ?? '',
        score: (evaluation['score'] as num?)?.toInt(),
      );
      if (!mounted) return;
      setState(() {
        answeredSoFar.add(saved);
        lastEvaluation = evaluation;
      });
    } catch (e) {
      if (mounted) setState(() => error = 'Could not evaluate that answer. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _nextQuestion() {
    setState(() {
      currentIndex++;
      lastEvaluation = null;
      answerController.clear();
      if (currentIndex >= questions.length) mode = _Mode.summary;
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      busy = true;
      mode = _Mode.history;
      historyDetail = null;
    });
    try {
      final sessions = await DatabaseService.instance.getInterviewSessions(_userId);
      if (mounted) setState(() => history = sessions);
    } catch (e) {
      if (mounted) setState(() => error = 'Could not load interview history.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openHistorySession(InterviewSession s) async {
    setState(() => busy = true);
    try {
      final answers = await DatabaseService.instance.getInterviewAnswers(s.id);
      if (mounted) setState(() => historyDetail = answers);
    } catch (e) {
      if (mounted) setState(() => error = 'Could not load that session.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Color _scoreColor(num score) {
    if (score >= 70) return AppTheme.success;
    if (score >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Coach', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: busy ? null : _loadHistory,
            tooltip: 'History',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (mode) {
      case _Mode.setup:
        return _buildSetup();
      case _Mode.interviewing:
        return _buildInterviewing();
      case _Mode.summary:
        return _buildSummary();
      case _Mode.history:
        return _buildHistory();
    }
  }

  Widget _buildSetup() {
    return FutureBuilder<List<Resume>>(
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
                  Icon(Icons.mic_none_outlined, size: 48, color: AppTheme.grey.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  const Text('Nothing to practice with yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a CV or Resume first, then come back here to practice interviewing.',
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
              const Text('Practice Interview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                '6 questions tailored to your resume — technical, behavioral, CV-based, '
                'and job-specific if you add a job description.',
                style: TextStyle(color: AppTheme.grey),
              ),
              const SizedBox(height: 16),
              if (resumes.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<Resume>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Document'),
                    items: resumes
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.professionalTitle.isEmpty
                                  ? (r.fullName.isEmpty ? 'Untitled' : r.fullName)
                                  : r.professionalTitle),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ),
              TextField(
                controller: jobDescriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Target job description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: busy ? null : _startInterview,
                  icon: busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow),
                  label: Text(busy ? 'Preparing…' : 'Start Interview'),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: AppTheme.error)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterviewing() {
    if (questions.isEmpty || currentIndex >= questions.length) {
      return const Center(child: Text('No questions available.'));
    }
    final q = questions[currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${currentIndex + 1} of ${questions.length} · ${(q['type'] as String? ?? '').toUpperCase()}',
            style: const TextStyle(fontSize: 12, color: AppTheme.grey, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            q['question'] as String? ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: answerController,
            maxLines: 6,
            enabled: lastEvaluation == null,
            decoration: const InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (lastEvaluation == null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: busy ? null : _submitAnswer,
                icon: busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: Text(busy ? 'Evaluating…' : 'Submit Answer'),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _scoreColor((lastEvaluation!['score'] as num?) ?? 0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _scoreColor((lastEvaluation!['score'] as num?) ?? 0).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: ${lastEvaluation!['score']}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _scoreColor((lastEvaluation!['score'] as num?) ?? 0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(lastEvaluation!['feedback'] as String? ?? '', style: const TextStyle(fontSize: 13.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _nextQuestion,
                child: Text(currentIndex == questions.length - 1 ? 'Finish' : 'Next Question'),
              ),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final scores = answeredSoFar.where((a) => a.score != null).map((a) => a.score!).toList();
    final avg = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session Complete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _scoreColor(avg).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: _scoreColor(avg).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('Average Score', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${avg.round()}/100',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _scoreColor(avg))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...answeredSoFar.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Score: ${a.score ?? '-'}/100',
                        style: TextStyle(color: _scoreColor(a.score ?? 0), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(a.feedback, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => setState(() => mode = _Mode.setup),
              child: const Text('Practice Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (busy) return const Center(child: CircularProgressIndicator());
    if (historyDetail != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => historyDetail = null),
                ),
                const Text('Session Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            if (historyDetail!.isEmpty) const Text('No answers recorded for this session.'),
            ...historyDetail!.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Your answer: ${a.answer}', style: const TextStyle(fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Text('Score: ${a.score ?? '-'}/100',
                          style: TextStyle(color: _scoreColor(a.score ?? 0), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(a.feedback, style: const TextStyle(fontSize: 12.5, color: AppTheme.grey)),
                    ],
                  ),
                )),
          ],
        ),
      );
    }
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No practice sessions yet.', style: TextStyle(color: AppTheme.grey)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => mode = _Mode.setup),
                child: const Text('Start One'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final s = history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: Text(
              s.jobDescription.trim().isEmpty ? 'General practice' : 'Job-specific practice',
            ),
            subtitle: Text(s.createdAt.toLocal().toString().split('.').first),
            onTap: () => _openHistorySession(s),
          ),
        );
      },
    );
  }
}
