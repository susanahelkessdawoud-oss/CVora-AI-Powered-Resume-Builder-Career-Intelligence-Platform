import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/ats_checker.dart';
import '../../utils/resume_scorer.dart';
import '../../widgets/cv_components.dart';

class _ChatMessage {
  _ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _resumeTitle;
  String? _resumeSummary;
  String? _analysisNote;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('aiChats').doc(uid).get();
      final raw = doc.data()?['messages'] as List? ?? [];
      if (!mounted || raw.isEmpty) return;
      setState(() {
        _messages.addAll(raw.map((m) => _ChatMessage(m['text'] as String, m['fromUser'] as bool)));
      });
      _scrollToEnd();
    } catch (_) {
      // History is a convenience; the chat still works without it.
    }
  }

  Future<void> _persistHistory() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    final recent = _messages.length > 50 ? _messages.sublist(_messages.length - 50) : _messages;
    try {
      await FirebaseFirestore.instance.collection('aiChats').doc(uid).set({
        'messages': recent.map((m) => {'text': m.text, 'fromUser': m.fromUser}).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal: the conversation stays visible in this session either way.
    }
  }

  Future<void> _loadContext() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;
    try {
      final resumes = await DatabaseService.instance.getResumes(uid);
      if (resumes.isNotEmpty && mounted) {
        resumes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final active = resumes.first;
        final ats = AtsChecker.check(active);
        final completeness = ResumeScorer.score(active);
        final failed = ats.checks.where((c) => !c.passed).map((c) => c.label).toList();
        setState(() {
          _resumeTitle = active.professionalTitle.isNotEmpty
              ? active.professionalTitle
              : (active.documentType == 'cv' ? 'Your CV' : 'Your Resume');
          _resumeSummary = active.professionalSummary;
          _analysisNote = 'ATS readiness score: ${ats.score}/100. '
              'Completeness score: ${completeness.score}/100. '
              '${failed.isEmpty ? 'All ATS checks pass.' : 'Failed ATS checks: ${failed.join(', ')}.'}';
        });
      }
    } catch (_) {
      // Context is a nice-to-have; chat still works without it.
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();
    try {
      final reply = await AiService.instance.chatAboutCv(
        question: text,
        resumeSummary: _resumeSummary,
        lastAnalysisNote: _analysisNote,
        selectedJobTitle: _resumeTitle,
        history: _messages
            .take(_messages.length - 1)
            .toList()
            .reversed
            .take(6)
            .toList()
            .reversed
            .map((m) => {'role': m.fromUser ? 'User' : 'Assistant', 'text': m.text})
            .toList(),
      );
      if (mounted) setState(() => _messages.add(_ChatMessage(reply, false)));
      await _persistHistory();
    } catch (e) {
      if (mounted) setState(() => _messages.add(_ChatMessage('Sorry, I could not reach the AI service: $e', false)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        Text(
                          "Knows your CV, last analysis & selected job",
                          style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_resumeTitle != null) ...[
                    StatusChip(label: _resumeTitle!, tone: ChipTone.blue),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Ask me anything about your CV, score, or how to prepare for a job.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final m = _messages[i];
                        return Align(
                          alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            decoration: BoxDecoration(
                              color: m.fromUser
                                  ? AppTheme.primary
                                  : (Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : AppTheme.light),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(color: m.fromUser ? Colors.white : null, fontSize: 14.5),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(label: const Text('Explain my ATS score'), onPressed: () => _send('Explain my ATS score')),
                  ActionChip(label: const Text('Prep for my target role'), onPressed: () => _send('How should I prepare for my target role?')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Ask about your CV...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _sending ? null : () => _send(),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CvBottomNav(currentIndex: 3),
    );
  }
}
