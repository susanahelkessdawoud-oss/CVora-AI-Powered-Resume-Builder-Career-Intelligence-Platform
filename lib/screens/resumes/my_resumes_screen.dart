import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../builder/document_type_screen.dart';
import '../builder/resume_builder_screen.dart';
import '../preview/resume_preview_screen.dart';

class MyResumesScreen extends StatefulWidget {
  /// 'cv', 'resume', or null to show both.
  final String? filterType;

  const MyResumesScreen({super.key, this.filterType});

  @override
  State<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends State<MyResumesScreen> {
  late Future<List<Resume>> resumesFuture;

  @override
  void initState() {
    super.initState();
    loadResumes();
  }

  void loadResumes() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      resumesFuture = Future.value([]);
      return;
    }
    resumesFuture = DatabaseService.instance.getResumes(userId).then((all) {
      if (widget.filterType == null) return all;
      return all.where((r) => r.documentType == widget.filterType).toList();
    });
  }

  Future<void> refresh() async {
    setState(() {
      loadResumes();
    });
  }

  void createResume() {
    final page = widget.filterType == null
        ? const DocumentTypeScreen()
        : ResumeBuilderScreen(documentType: widget.filterType!);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      refresh();
    });
  }

  void editResume(Resume resume) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResumeBuilderScreen(existing: resume)),
    ).then((_) {
      refresh();
    });
  }

  Future<void> deleteResume(Resume resume) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Resume?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await DatabaseService.instance.deleteResume(resume.id, userId);

    refresh();
  }

  String get _label {
    switch (widget.filterType) {
      case 'cv':
        return 'CVs';
      case 'resume':
        return 'Resumes';
      default:
        return 'Documents';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My $_label',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: createResume, icon: const Icon(Icons.add)),
        ],
      ),

      body: FutureBuilder<List<Resume>>(
        future: resumesFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final resumes = snapshot.data ?? [];

          if (resumes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 38,
                        color: AppTheme.purple,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'No $_label yet',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Create your first professional document and start building your career profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: createResume,
                      icon: const Icon(Icons.add),
                      label: Text('Create New ${widget.filterType == 'cv' ? 'CV' : 'Resume'}'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resumes.length,
              itemBuilder: (context, index) {
                final resume = resumes[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.purple,
                      ),
                    ),

                    title: Text(
                      resume.professionalTitle.isEmpty
                          ? 'Untitled Resume'
                          : resume.professionalTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${resume.resumeType} • ${resume.fullName.isEmpty ? 'No name yet' : resume.fullName}',
                      ),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResumePreviewScreen(resume: resume),
                        ),
                      );
                    },

                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          editResume(resume);
                        }

                        if (value == 'delete') {
                          deleteResume(resume);
                        }
                      },

                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
