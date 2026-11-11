import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'document_type_screen.dart';
import 'my_resumes_screen.dart';
import 'tools/resume_score_screen.dart';

/// The welcome dashboard: greeting by name plus a grid of career tools.
class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onGoToTab;
  const DashboardScreen({super.key, required this.onGoToTab});

  /// Best-effort display name that never shows a raw email address.
  String? _firstName() {
    final raw = AuthService().currentUser?.displayName?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('@')) return null; // don't greet with an email
    return raw.split(' ').first;
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final first = _firstName();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final tiles = <_Tile>[
      _Tile(
        title: 'My Resumes',
        subtitle: 'View resumes',
        icon: Icons.description_outlined,
        color: AppColors.brand,
        onTap: () =>
            _push(context, const MyResumesScreen(filter: DocType.resume)),
      ),
      _Tile(
        title: 'My CVs',
        subtitle: 'View CVs',
        icon: Icons.menu_book_outlined,
        color: AppColors.teal,
        onTap: () =>
            _push(context, const MyResumesScreen(filter: DocType.cv)),
      ),
      _Tile(
        title: 'Match a Job',
        subtitle: 'Job Matcher',
        icon: Icons.center_focus_strong_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => onGoToTab(3),
      ),
      _Tile(
        title: 'Achievement Vault',
        subtitle: 'Manage wins',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFEC4899),
        onTap: () => onGoToTab(2),
      ),
      _Tile(
        title: 'Resume Score',
        subtitle: 'Check & improve',
        icon: Icons.tips_and_updates_outlined,
        color: AppColors.success,
        onTap: () => _push(context, const ResumeScoreScreen()),
      ),
      _Tile(
        title: 'Settings',
        subtitle: 'Preferences',
        icon: Icons.settings_outlined,
        color: AppColors.brandBright,
        onTap: () => onGoToTab(4),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first == null ? 'Welcome 👋' : 'Welcome, $first 👋',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('Build a resume or CV that represents you.',
                        style: TextStyle(color: muted)),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () =>
                          _push(context, const DocumentTypeScreen()),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New'),
                    ),
                    const SizedBox(height: 24),
                    Text('Your Career Tools',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TileCard(tile: tiles[i]),
                  childCount: tiles.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _TileCard extends StatelessWidget {
  final _Tile tile;
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tile.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tile.icon, color: tile.color, size: 24),
              ),
              const Spacer(),
              Text(tile.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tile.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
