import 'package:flutter/material.dart';

import '../models.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets/trend_chart.dart';

/// Full-screen 30-day trend for a single dimension, pushed on top of the
/// daily page (with the standard back-button AppBar) when a dimension row
/// is tapped.
class DimensionTrendPage extends StatelessWidget {
  final Dimension dimension;
  final List<Entry> entries;
  const DimensionTrendPage({super.key, required this.dimension, required this.entries});

  @override
  Widget build(BuildContext context) {
    final dimensionEntries = entries.where((e) => e.dimensionId == dimension.id).toList();
    final trendData = buildTrend(dimensionEntries);
    final color = dimensionColor(dimension.name);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(dimension.name, style: TextStyle(color: color, fontSize: 13)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '30-DAY TREND',
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate900.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate800),
            ),
            child: TrendChart(data: trendData),
          ),
        ],
      ),
    );
  }
}
