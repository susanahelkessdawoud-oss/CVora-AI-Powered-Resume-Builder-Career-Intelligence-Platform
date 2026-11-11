import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/resume.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class _GithubRepo {
  final String name;
  final String description;
  final String url;
  final String language;
  final int stars;

  _GithubRepo({
    required this.name,
    required this.description,
    required this.url,
    required this.language,
    required this.stars,
  });

  factory _GithubRepo.fromJson(Map<String, dynamic> json) {
    return _GithubRepo(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['html_url'] ?? '',
      language: json['language'] ?? '',
      stars: json['stargazers_count'] ?? 0,
    );
  }
}

class GithubScreen extends StatefulWidget {
  const GithubScreen({super.key});

  @override
  State<GithubScreen> createState() => _GithubScreenState();
}

class _GithubScreenState extends State<GithubScreen> {
  late TextEditingController githubUsernameController;
  bool isLoading = false;
  bool isImporting = false;
  String? error;
  List<_GithubRepo> repos = [];
  final Set<int> selectedIndexes = {};

  late Future<List<Resume>> resumesFuture;
  Resume? selectedResume;

  @override
  void initState() {
    super.initState();
    githubUsernameController = TextEditingController();
    final userId = AuthService.instance.currentUser?.id;
    resumesFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getResumes(userId);
  }

  @override
  void dispose() {
    githubUsernameController.dispose();
    super.dispose();
  }

  Future<void> _fetchRepos() async {
    final username = githubUsernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      isLoading = true;
      error = null;
      repos = [];
      selectedIndexes.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/users/$username/repos?sort=updated&per_page=20',
        ),
      );

      if (response.statusCode == 404) {
        setState(() => error = 'No GitHub user named "$username" was found.');
        return;
      }
      if (response.statusCode == 403) {
        setState(
          () => error = 'GitHub rate limit reached. Please try again shortly.',
        );
        return;
      }
      if (response.statusCode != 200) {
        setState(() => error = 'GitHub returned an error (${response.statusCode}).');
        return;
      }

      final data = jsonDecode(response.body) as List;
      setState(() {
        repos = data
            .map((r) => _GithubRepo.fromJson(r as Map<String, dynamic>))
            .where((r) => r.name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() => error = 'Could not reach GitHub: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _importSelected() async {
    if (selectedIndexes.isEmpty || selectedResume == null) return;

    setState(() => isImporting = true);
    try {
      final resume = selectedResume!;
      final existingLinks = resume.projects.map((p) => p.link).toSet();

      final newProjects = selectedIndexes
          .map((i) => repos[i])
          .where((repo) => !existingLinks.contains(repo.url))
          .map(
            (repo) => Project(
              id: '',
              name: repo.name,
              description: repo.description,
              link: repo.url,
              technologies: repo.language,
              startDate: '',
              endDate: '',
            ),
          )
          .toList();

      final updated = Resume(
        id: resume.id,
        userId: resume.userId,
        fullName: resume.fullName,
        email: resume.email,
        phone: resume.phone,
        location: resume.location,
        professionalTitle: resume.professionalTitle,
        professionalSummary: resume.professionalSummary,
        documentType: resume.documentType,
        resumeType: resume.resumeType,
        template: resume.template,
        education: resume.education,
        experience: resume.experience,
        skills: resume.skills,
        projects: [...resume.projects, ...newProjects],
        achievements: resume.achievements,
        certifications: resume.certifications,
        createdAt: resume.createdAt,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateResume(resume.id, updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newProjects.length} project(s) added to "${resume.fullName.isEmpty ? 'your resume' : resume.fullName}".',
            ),
          ),
        );
        setState(() => selectedIndexes.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not import: $e')));
      }
    } finally {
      if (mounted) setState(() => isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GitHub Portfolio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Your GitHub Projects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fetch your public repositories and add them as projects on your resume.',
                style: TextStyle(color: AppTheme.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: githubUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'GitHub Username',
                        prefixIcon: Icon(Icons.code),
                      ),
                      onSubmitted: (_) => _fetchRepos(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: isLoading ? null : _fetchRepos,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Fetch'),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Text(error!, style: const TextStyle(color: AppTheme.error)),
              ],
              if (repos.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  '${repos.length} repositories found',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...List.generate(repos.length, (index) {
                  final repo = repos[index];
                  final selected = selectedIndexes.contains(index);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedIndexes.add(index);
                          } else {
                            selectedIndexes.remove(index);
                          }
                        });
                      },
                      title: Text(
                        repo.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (repo.description.isNotEmpty) repo.description,
                          if (repo.language.isNotEmpty) repo.language,
                          '${repo.stars} ★',
                        ].join(' · '),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                FutureBuilder<List<Resume>>(
                  future: resumesFuture,
                  builder: (context, snapshot) {
                    final resumes = snapshot.data ?? [];
                    if (resumes.isEmpty) {
                      return const Text(
                        'Create a CV or Resume first to import projects into it.',
                        style: TextStyle(color: AppTheme.grey),
                      );
                    }
                    selectedResume ??= resumes.first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<Resume>(
                          initialValue: selectedResume,
                          decoration: const InputDecoration(
                            labelText: 'Import into',
                          ),
                          items: resumes
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r.professionalTitle.isEmpty
                                        ? (r.fullName.isEmpty ? 'Untitled' : r.fullName)
                                        : r.professionalTitle,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => selectedResume = value),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed:
                                selectedIndexes.isEmpty || isImporting
                                ? null
                                : _importSelected,
                            child: Text(
                              isImporting
                                  ? 'Importing...'
                                  : 'Import ${selectedIndexes.length} Selected',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
