import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Soft atmospheric background used on auth / splash surfaces.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.dark = false,
  });

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  AppTheme.primaryDeep,
                  AppTheme.primary,
                  AppTheme.primaryLight,
                ]
              : const [
                  Color(0xFFEFF6FB),
                  Color(0xFFF7FAFC),
                  Color(0xFFE8F5F2),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Blob(
              size: 220,
              color: (dark ? AppTheme.accent : AppTheme.primary)
                  .withValues(alpha: dark ? 0.22 : 0.08),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _Blob(
              size: 260,
              color: (dark ? Colors.white : AppTheme.accent)
                  .withValues(alpha: dark ? 0.06 : 0.1),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
