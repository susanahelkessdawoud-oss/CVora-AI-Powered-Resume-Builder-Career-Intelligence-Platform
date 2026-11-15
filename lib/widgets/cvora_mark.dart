import 'package:flutter/material.dart';

/// The CVora brand mark: a CV document wrapped in a blue-to-purple
/// orbit ring, with a sparkle accent — "build, optimize, grow".
///
/// Set [animate] to true for a slow breathing scale (used on the splash
/// screen); elsewhere it renders static.
class CvoraMark extends StatefulWidget {
  const CvoraMark({super.key, this.size = 96, this.animate = false});

  final double size;
  final bool animate;

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

  Widget _image() => Image.asset(
    'assets/branding/cvora_mark.png',
    width: widget.size,
    height: widget.size,
    fit: BoxFit.contain,
  );

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return _image();
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final scale = 0.94 + 0.06 * _controller!.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: _image(),
    );
  }
}
