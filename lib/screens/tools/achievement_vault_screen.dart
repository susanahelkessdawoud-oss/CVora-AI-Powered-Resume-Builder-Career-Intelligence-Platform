import 'package:flutter/material.dart';

import '../../models/resume.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_improve_button.dart';

class AchievementVaultScreen extends StatefulWidget {
  const AchievementVaultScreen({super.key});

  @override
  State<AchievementVaultScreen> createState() =>
      _AchievementVaultScreenState();
}

class _AchievementVaultScreenState extends State<AchievementVaultScreen> {
  late Future<List<Achievement>> achievementsFuture;

  String? get _userId => AuthService.instance.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = _userId;
    achievementsFuture = userId == null
        ? Future.value([])
        : DatabaseService.instance.getVaultAchievements(userId);
  }

  Future<void> _refresh() async {
    setState(_load);
  }

  Future<void> _openEditor({Achievement? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final dateCtrl = TextEditingController(text: existing?.date ?? '');
    final descCtrl = TextEditingController(
      text: existing?.description ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Achievement' : 'Edit Achievement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date (optional)',
                  hintText: 'e.g. March 2026',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              AiImproveButton(
                onImprove: () => AiService.instance.improveAchievementDescription(
                  currentText: descCtrl.text,
                  title: titleCtrl.text,
                ),
                onResult: (text) => descCtrl.text = text,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || titleCtrl.text.trim().isEmpty) return;

    final userId = _userId;
    if (userId == null) return;

    final achievement = Achievement(
      id: existing?.id ?? '',
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      date: dateCtrl.text.trim(),
    );

    try {
      if (existing == null) {
        await DatabaseService.instance.addVaultAchievement(
          userId,
          achievement,
        );
      } else {
        await DatabaseService.instance.updateVaultAchievement(achievement);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _delete(Achievement achievement) async {
    final userId = _userId;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete achievement?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DatabaseService.instance.deleteVaultAchievement(
        achievement.id,
        userId,
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achievement Vault',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Achievement>>(
          future: achievementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong.\n${snapshot.error}'));
            }

            final achievements = snapshot.data ?? [];

            if (achievements.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 48,
                        color: AppTheme.amber,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your vault is empty',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save achievements here once, then reuse them across every CV or Resume you build.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.grey),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Achievement'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: AppTheme.amber,
                        ),
                      ),
                      title: Text(
                        achievement.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          achievement.date,
                          achievement.description,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEditor(existing: achievement);
                          } else if (value == 'delete') {
                            _delete(achievement);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
