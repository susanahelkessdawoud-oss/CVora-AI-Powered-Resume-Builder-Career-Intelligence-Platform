import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import 'builder/resume_builder_screen.dart';
import 'document_type_screen.dart';
import 'tools/resume_score_screen.dart';
import 'preview_screen.dart';

/// Screens 06 / 19 — the user's saved resumes, loaded from SQLite, with a
/// search filter, per-item score, and edit / preview / delete actions.
class MyResumesScreen extends StatefulWidget {
  final DocType? filter;
  const MyResumesScreen({super.key, this.filter});

  @override
  State<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends State<MyResumesScreen> {
  final _auth = AuthService();
  final _db = DatabaseService.instance;
  final _search = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Resume> _all = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resumes = await _db.getResumes(uid, docType: widget.filter);
      if (!mounted) return;
      setState(() {
        _all = resumes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your resumes.';
        _loading = false;
      });
    }
  }

  List<Resume> get _visible {
    if (_query.trim().isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where((r) =>
            r.fullName.toLowerCase().contains(q) ||
            r.jobTitle.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openBuilder({Resume? existing}) async {
    final route = existing == null
        ? MaterialPageRoute(builder: (_) => const DocumentTypeScreen())
        : MaterialPageRoute(
            builder: (_) => ResumeBuilderScreen(existing: existing));
    await Navigator.of(context).push(route);
    await _load();
  }

  String get _title {
    switch (widget.filter) {
      case DocType.cv:
        return 'My CVs';
      case DocType.resume:
        return 'My Resumes';
      case null:
        return 'My Documents';
    }
  }

  Future<void> _preview(Resume resume) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewScreen(resume: resume)),
    );
    await _load();
  }

  Future<void> _confirmDelete(Resume resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text(
          'This will permanently delete '
          '"${resume.fullName.isEmpty ? 'Untitled resume' : resume.fullName}".',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.deleteResume(resume.id, uid);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete resume.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBuilder(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView(message: 'Loading your resumes…');
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    if (_all.isEmpty) {
      return EmptyView(
        icon: Icons.description_outlined,
        title: 'Nothing here yet',
        message:
            'Create your first document and start building your career '
            'profile.',
        actionLabel: 'Create New',
        onAction: () => _openBuilder(),
      );
    }

    final items = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search resumes',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyView(
                  icon: Icons.search_off_outlined,
                  title: 'No matches',
                  message: 'No resumes match your search.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _ResumeCard(
                      resume: items[i],
                      onEdit: () => _openBuilder(existing: items[i]),
                      onPreview: () => _preview(items[i]),
                      onDelete: () => _confirmDelete(items[i]),
                      onScore: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ResumeScoreScreen(resume: items[i]),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final Resume resume;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onScore;

  const _ResumeCard({
    required this.resume,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
    required this.onScore,
  });

  Color _scoreColor(int s) {
    if (s >= 80) return AppColors.success;
    if (s >= 60) return AppColors.brand;
    if (s >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = resume.completionScore;
    final color = _scoreColor(score);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.fullName.isEmpty
                          ? 'Untitled resume'
                          : resume.fullName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (resume.jobTitle.isNotEmpty)
                      Text(resume.jobTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              InkWell(
                onTap: onScore,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$score%',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 3),
                      Icon(Icons.chevron_right, size: 16, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
