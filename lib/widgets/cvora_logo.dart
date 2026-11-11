import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Cvora mark drawn in code: a document with text lines and a small
/// sparkle, echoing the brand logo. No image asset required.
///
/// To use your exact PNG instead: put it at assets/images/logo.png, declare
/// `assets/images/` under `flutter:` in pubspec.yaml, and swap this widget
/// for `Image.asset('assets/images/logo.png', width: size, height: size)`.
class CvoraLogo extends StatelessWidget {
  final double size;
  const CvoraLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final unit = size / 96;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Document sheet
          Center(
            child: Container(
              width: size * 0.72,
              height: size * 0.9,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE7ECFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14 * unit),
                border: Border.all(
                    color: AppColors.navyText, width: 3.2 * unit),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 12 * unit, vertical: 16 * unit),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(unit, widthFactor: 1.0, color: AppColors.navyText),
                    SizedBox(height: 7 * unit),
                    _bar(unit, widthFactor: 0.85, color: AppColors.brand),
                    SizedBox(height: 7 * unit),
                    _bar(unit, widthFactor: 0.95, color: AppColors.navyText),
                  ],
                ),
              ),
            ),
          ),
          // Sparkle accent (top-right)
          Positioned(
            top: 0,
            right: size * 0.06,
            child: Icon(
              Icons.auto_awesome,
              size: 30 * unit,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double unit,
      {required double widthFactor, required Color color}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 6 * unit,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4 * unit),
        ),
      ),
    );
  }
}
