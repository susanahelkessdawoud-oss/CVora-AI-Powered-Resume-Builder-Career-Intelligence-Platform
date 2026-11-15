import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A standard elevated-free surface card: radius 18, 1px border, the
/// app's default container for grouped content.
class CvCard extends StatelessWidget {
  const CvCard({super.key, required this.child, this.padding, this.color, this.borderColor, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppTheme.surface : AppTheme.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: borderColor ?? (isDark ? AppTheme.border : AppTheme.light)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      onTap: onTap,
      child: card,
    );
  }
}

/// A 40x40 rounded icon tile with a tint color, used for list rows and
/// feature grids throughout the app.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = AppTheme.iconTileSize});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 2),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

enum ChipTone { neutral, success, warning, danger, blue, purple }

/// A small pill-shaped status label, colored by semantic tone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral});

  final String label;
  final ChipTone tone;

  Color _color() => switch (tone) {
    ChipTone.success => AppTheme.successColor,
    ChipTone.warning => AppTheme.warningColor,
    ChipTone.danger => AppTheme.dangerColor,
    ChipTone.blue => AppTheme.cyan,
    ChipTone.purple => AppTheme.aiPurple,
    ChipTone.neutral => AppTheme.mutedText,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      height: AppTheme.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.chipHeight / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The small purple "AI" sparkle badge used to mark AI-generated content.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'AI'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.aiPurple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.chipHeight / 2),
        border: Border.all(color: AppTheme.aiCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: AppTheme.aiPurple),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppTheme.aiPurple, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A card tinted to signal AI-generated content, with a purple border.
class AiCard extends StatelessWidget {
  const AiCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.aiCardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.aiCardBorder),
      ),
      child: child,
    );
  }
}

/// A circular progress ring with a centered number and caption below it
/// — the score display used across Home, CV Analyzer, ATS Analyzer and
/// Job Matcher.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.max = 100,
    this.size = 84,
    this.caption,
    this.color,
  });

  final int score;
  final int max;
  final double size;
  final String? caption;
  final Color? color;

  Color _autoColor() {
    final pct = score / max;
    if (pct >= 0.8) return AppTheme.successColor;
    if (pct >= 0.6) return AppTheme.cyan;
    if (pct >= 0.4) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? _autoColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (score / max).clamp(0, 1),
              strokeWidth: size * 0.1,
              strokeCap: StrokeCap.round,
              backgroundColor: isDark ? AppTheme.border : AppTheme.light,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w800, height: 1),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: TextStyle(fontSize: size * 0.12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A labeled percentage bar: "Label  NN%" above a thin rounded track.
class MetricBar extends StatelessWidget {
  const MetricBar({super.key, required this.label, required this.value, this.max = 100, this.color});

  final String label;
  final int value;
  final int max;
  final Color? color;

  Color _autoColor() {
    final pct = value / max;
    if (pct >= 0.8) return AppTheme.successColor;
    if (pct >= 0.6) return AppTheme.cyan;
    return AppTheme.warningColor;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? _autoColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('$value', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: barColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0, 1),
            minHeight: 6,
            backgroundColor: isDark ? AppTheme.border : AppTheme.light,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

enum IssueSeverity { info, warning, danger, success }

/// A row combining a severity icon, a title, and an explanatory line —
/// the standard shape for analyzer findings across the app.
class IssueRow extends StatelessWidget {
  const IssueRow({
    super.key,
    required this.title,
    required this.detail,
    this.severity = IssueSeverity.warning,
    this.trailing,
  });

  final String title;
  final String detail;
  final IssueSeverity severity;
  final Widget? trailing;

  (IconData, Color) _visual() => switch (severity) {
    IssueSeverity.success => (Icons.check_circle_outline, AppTheme.successColor),
    IssueSeverity.warning => (Icons.warning_amber_rounded, AppTheme.warningColor),
    IssueSeverity.danger => (Icons.error_outline, AppTheme.dangerColor),
    IssueSeverity.info => (Icons.info_outline, AppTheme.cyan),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// A row of equal-weight segmented tabs (All / CVs / Resumes / ...).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface2 : AppTheme.light,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == i ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected == i
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard screen app bar: a back-button tile, title, optional
/// subtitle, and an optional trailing action.
class CvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CvAppBar({super.key, required this.title, this.subtitle, this.actions, this.showBack = true});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 4 : 20,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _BackTile(onTap: () => Navigator.maybePop(context)),
            )
          : null,
      leadingWidth: showBack ? 56 : 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
        ],
      ),
      actions: actions == null
          ? null
          : [...actions!, const SizedBox(width: 8)],
    );
  }
}

class _BackTile extends StatelessWidget {
  const _BackTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface2 : AppTheme.light,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(Icons.arrow_back, size: 19),
      ),
    );
  }
}

/// A square icon-tile action button for app bars (settings gear, clock,
/// refresh, etc), matching the back-button tile's shape.
class CvAppBarAction extends StatelessWidget {
  const CvAppBarAction({super.key, required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface2 : AppTheme.light,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(icon, size: 19)),
            if (badge != null && badge! > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.dangerColor, borderRadius: BorderRadius.circular(8)),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The 5-tab bottom navigation: Home, My CVs, a raised Create button,
/// Assistant, Profile. `currentIndex` is -1 when the screen above isn't
/// one of the five tab destinations.
class CvBottomNav extends StatelessWidget {
  const CvBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    const routes = ['/home', '/my-resumes', '/document-type', '/ai-assistant', '/profile'];
    Navigator.pushNamedAndRemoveUntil(context, routes[index], (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.white,
        border: Border(top: BorderSide(color: isDark ? AppTheme.border : AppTheme.light)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tab(context, 0, Icons.home_rounded, 'Home'),
            _tab(context, 1, Icons.description_rounded, 'My CVs'),
            _createTab(context),
            _tab(context, 3, Icons.chat_bubble_rounded, 'Assistant'),
            _tab(context, 4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final active = currentIndex == index;
    final color = active ? AppTheme.primary : Theme.of(context).textTheme.bodySmall?.color;
    return InkWell(
      onTap: () => _go(context, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _createTab(BuildContext context) {
    return InkWell(
      onTap: () => _go(context, 2),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 3),
          Text(
            'Create',
            style: TextStyle(
              fontSize: 11,
              fontWeight: currentIndex == 2 ? FontWeight.w700 : FontWeight.w500,
              color: currentIndex == 2 ? AppTheme.primary : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
