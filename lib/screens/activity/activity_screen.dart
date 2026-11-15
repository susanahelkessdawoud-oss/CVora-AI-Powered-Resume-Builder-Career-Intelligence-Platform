import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cv_components.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _loading = true;
  List<Resume> _resumes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final resumes = await DatabaseService.instance.getResumes(uid);
      resumes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) {
        setState(() {
          _resumes = resumes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CvAppBar(title: 'Activity', subtitle: 'Your real document history'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _resumes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.mutedText),
                          const SizedBox(height: 16),
                          const Text('No activity yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            'Create or edit a CV and it will show up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _resumes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _resumes[i];
                        final isNew = r.createdAt.difference(r.updatedAt).abs().inMinutes < 2;
                        return CvCard(
                          child: Row(
                            children: [
                              IconTile(icon: isNew ? Icons.add_circle_outline : Icons.edit_outlined, color: isNew ? AppTheme.successColor : AppTheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isNew ? 'Created "${r.professionalTitle.isEmpty ? r.fullName : r.professionalTitle}"' : 'Updated "${r.professionalTitle.isEmpty ? r.fullName : r.professionalTitle}"',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      '${r.documentType == 'cv' ? 'CV' : 'Resume'} · ${r.template}',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                  ],
                                ),
                              ),
                              Text(_timeAgo(r.updatedAt), style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
