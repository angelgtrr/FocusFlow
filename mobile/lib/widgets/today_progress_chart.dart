import 'package:flutter/material.dart';

import '../stats.dart';
import '../theme.dart';

/// Bar chart of today's score per dimension (0-4), mirroring the
/// "graph bars with current day's progress" requirement.
class TodayProgressChart extends StatelessWidget {
  final List<DimensionProgress> progress;
  static const double maxBarHeight = 96;

  const TodayProgressChart({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) {
      return const Text(
        'No dimensions yet. Add one in the Dimensions tab.',
        style: TextStyle(color: AppColors.slate500, fontSize: 13),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in progress)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.loggedToday ? '${p.entry!.score}' : '–',
                    style: const TextStyle(
                      color: AppColors.slate300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: p.loggedToday
                        ? (maxBarHeight * (p.entry!.score / 4)).clamp(6, maxBarHeight)
                        : 6,
                    decoration: BoxDecoration(
                      color: p.loggedToday ? scoreColors[p.entry!.score] : AppColors.slate800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 56,
                    child: Text(
                      p.dimension.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dimensionColor(p.dimension.name), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
