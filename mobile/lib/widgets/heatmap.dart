import 'package:flutter/material.dart';

import '../stats.dart';
import '../theme.dart';

class Heatmap extends StatelessWidget {
  final List<HeatmapDay> days;
  const Heatmap({super.key, required this.days});

  Color _colorFor(double? avgScore) {
    if (avgScore == null) return AppColors.slate900;
    final bucket = avgScore.round().clamp(0, 4);
    return scoreColors[bucket];
  }

  @override
  Widget build(BuildContext context) {
    final weeks = <List<HeatmapDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: [
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: [
                      for (final day in week)
                        Tooltip(
                          message: '${day.date}: ${day.avgScore == null ? 'no entry' : day.avgScore!.toStringAsFixed(1)}',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _colorFor(day.avgScore),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Less', style: TextStyle(color: AppColors.slate500, fontSize: 11)),
            const SizedBox(width: 4),
            for (final c in scoreColors)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
              ),
            const SizedBox(width: 4),
            const Text('More', style: TextStyle(color: AppColors.slate500, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
