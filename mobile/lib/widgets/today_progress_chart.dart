import 'package:flutter/material.dart';

import '../models.dart';
import '../stats.dart';
import '../theme.dart';

/// Horizontal bar chart of today's score per dimension (0-4), sorted
/// greatest to lowest. Tapping a row opens that dimension's 30-day trend.
class TodayProgressChart extends StatelessWidget {
  final List<DimensionProgress> progress;
  final ValueChanged<Dimension>? onSelectDimension;

  const TodayProgressChart({super.key, required this.progress, this.onSelectDimension});

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) {
      return const Text(
        'No dimensions yet. Add one in the Dimensions tab.',
        style: TextStyle(color: AppColors.slate500, fontSize: 13),
      );
    }

    final sorted = [...progress]
      ..sort((a, b) => (b.entry?.score ?? 0).compareTo(a.entry?.score ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onSelectDimension == null ? null : () => onSelectDimension!(p.dimension),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      p.dimension.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dimensionColor(p.dimension.name), fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.slate800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: p.loggedToday ? (p.entry!.score / 4).clamp(0.0, 1.0) : 0,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: p.loggedToday ? scoreColors[p.entry!.score] : AppColors.slate800,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text(
                      p.loggedToday ? '${p.entry!.score}' : '–',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.slate300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
