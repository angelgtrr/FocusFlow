import 'date_utils.dart';
import 'models.dart';

class HeatmapDay {
  final String date;
  final double? avgScore;
  HeatmapDay({required this.date, required this.avgScore});
}

List<HeatmapDay> buildHeatmap(List<Entry> entries, {int weeks = 12}) {
  final byDate = <String, List<int>>{};
  for (final e in entries) {
    (byDate[e.date] ??= []).add(e.score);
  }

  final end = startOfDay(DateTime.now());
  var cursor = startOfWeek(end).subtract(Duration(days: (weeks - 1) * 7));

  final days = <HeatmapDay>[];
  while (!cursor.isAfter(end)) {
    final key = toDateKey(cursor);
    final scores = byDate[key];
    days.add(
      HeatmapDay(
        date: key,
        avgScore: scores == null ? null : scores.reduce((a, b) => a + b) / scores.length,
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return days;
}

int currentStreak(List<Entry> entries) {
  final daysWithProgress = entries.where((e) => e.score >= 1).map((e) => e.date).toSet();
  var streak = 0;
  var cursor = startOfDay(DateTime.now());

  if (!daysWithProgress.contains(toDateKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  while (daysWithProgress.contains(toDateKey(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int weeklyProgressPct(List<Entry> entries, List<Dimension> dimensions) {
  if (dimensions.isEmpty) return 0;
  final start = startOfWeek(DateTime.now());
  final startKey = toDateKey(start);
  final endKey = todayKey();
  final weekEntries = entries.where((e) => e.date.compareTo(startKey) >= 0 && e.date.compareTo(endKey) <= 0);

  final daysSoFar = DateTime.now().weekday % 7 + 1; // Sun=0 -> 1 day so far, matches web
  final possible = dimensions.length * daysSoFar * 4;
  if (possible == 0) return 0;
  final achieved = weekEntries.fold<int>(0, (sum, e) => sum + e.score);
  return ((achieved / possible) * 100).round();
}

class DimensionProgress {
  final Dimension dimension;
  final Entry? entry;
  bool get loggedToday => entry != null;
  DimensionProgress({required this.dimension, required this.entry});
}

List<DimensionProgress> buildDimensionProgress(List<Dimension> dimensions, List<Entry> todaysEntries) {
  final byDim = {for (final e in todaysEntries) e.dimensionId: e};
  return dimensions.map((d) => DimensionProgress(dimension: d, entry: byDim[d.id])).toList();
}

Set<int> completedTaskIdsForDate(List<TaskCompletion> completions, String date) {
  return completions.where((c) => c.date == date).map((c) => c.taskId).toSet();
}

Set<String> activeDateKeys(List<Entry> entries, List<TaskCompletion> taskCompletions) {
  final keys = <String>{};
  for (final e in entries) {
    keys.add(e.date);
  }
  for (final c in taskCompletions) {
    keys.add(c.date);
  }
  return keys;
}
