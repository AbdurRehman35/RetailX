import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LowStockBadge extends StatelessWidget {
  const LowStockBadge({super.key, required this.isLow});

  final bool isLow;

  @override
  Widget build(BuildContext context) {
    if (!isLow) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Low stock',
        style: TextStyle(
          color: AppTheme.warning,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
