import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular "days until rent due" indicator (doc §4.4). Color shifts
/// blue → amber → red as the due date approaches or passes.
class DueRing extends StatelessWidget {
  /// Days remaining; negative means overdue.
  final int daysLeft;
  final double size;

  const DueRing({super.key, required this.daysLeft, this.size = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color;
    final String number;
    final String label;

    if (daysLeft < 0) {
      color = isDark ? AppColors.dangerDark : AppColors.danger;
      number = '${-daysLeft}';
      label = 'days overdue';
    } else if (daysLeft <= 3) {
      color = isDark ? AppColors.warningDark : AppColors.warning;
      number = '$daysLeft';
      label = 'days until due';
    } else {
      color = isDark ? AppColors.primaryDark : AppColors.primary;
      number = '$daysLeft';
      label = 'days until due';
    }

    final progress = ((30 - daysLeft) / 30).clamp(0.0, 1.0);

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
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
