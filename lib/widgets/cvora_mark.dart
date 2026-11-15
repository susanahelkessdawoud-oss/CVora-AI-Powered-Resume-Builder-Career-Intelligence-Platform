import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The CVora brand mark: a navy "C" ring whose opening holds a warm gold
/// "aura" glow — CV + Aura, rendered as vector geometry so it stays crisp
/// at any size (app bar, splash hero, app icon preview) without shipping
/// a raster asset per density.
///
/// Set [animate] to true for a slow breathing glow (used on the splash
/// screen); elsewhere it renders a static mid-intensity glow.
class CvoraMark extends StatefulWidget {
  const CvoraMark({super.key, this.size = 96, this.animate = false, this.ringColor});

  final double size;
  final bool animate;
  final Color? ringColor;

  @override
  State<CvoraMark> createState() => _CvoraMarkState();
}

class _CvoraMarkState extends State<CvoraMark> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.ringColor ?? AppTheme.navy;
    if (_controller == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _CvoraMarkPainter(glowPhase: 0.5, ringColor: ringColor)),
      );
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CvoraMarkPainter(glowPhase: _controller!.value, ringColor: ringColor),
          ),
        );
      },
    );
  }
}

class _CvoraMarkPainter extends CustomPainter {
  _CvoraMarkPainter({required this.glowPhase, required this.ringColor});

  /// 0..1, breathes the aura glow's size/intensity. 0.5 = resting state.
  final double glowPhase;
  final Color ringColor;

  static const Color auraCore = Color(0xFFFFF3D6);
  static const Color auraMid = Color(0xFFFFD98A);
  static const Color auraEdge = Color(0xFFF2A93B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final rOut = s * 0.39;
    final rIn = s * 0.234;
    const gapHalfAngle = 35 * 3.1415926535 / 180;

    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: rOut));
    final inner = Path()..addOval(Rect.fromCircle(center: center, radius: rIn));
    final donut = Path.combine(PathOperation.difference, outer, inner);

    final wedge = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: rOut * 1.2), -gapHalfAngle, gapHalfAngle * 2, false)
      ..close();

    final ringPath = Path.combine(PathOperation.difference, donut, wedge);

    // Breathing factor: eases between 0.88 and 1.12 across the animation.
    final breathe = 0.88 + 0.24 * (0.5 - (glowPhase - 0.5).abs()) * 2;

    final orbCenter = center + Offset((rIn + rOut) / 2 * 0.72, 0);
    final haloRadius = s * 0.25 * breathe;
    final coreRadius = s * 0.093 * breathe;

    // 1) outer soft halo, behind the ring
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [auraEdge.withValues(alpha: 0.5 * breathe), auraEdge.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: orbCenter, radius: haloRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(orbCenter, haloRadius, haloPaint);

    // 2) the ring itself
    final ringPaint = Paint()..color = ringColor;
    canvas.drawPath(ringPath, ringPaint);

    // 3) the glowing core, on top, nested in the gap
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: const [auraCore, auraMid, auraEdge, auraEdge],
        stops: const [0, 0.45, 0.85, 1],
      ).createShader(Rect.fromCircle(center: orbCenter, radius: coreRadius));
    canvas.drawCircle(orbCenter, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant _CvoraMarkPainter oldDelegate) =>
      oldDelegate.glowPhase != glowPhase || oldDelegate.ringColor != ringColor;
}
