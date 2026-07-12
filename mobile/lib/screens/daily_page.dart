import 'package:flutter/material.dart';

import '../app_state.dart';
import '../date_utils.dart';
import '../models.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets/heatmap.dart';
import '../widgets/log_entry_sheet.dart';
import '../widgets/today_progress_chart.dart';

class DailyPage extends StatelessWidget {
  final AppState appState;
  const DailyPage({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final today = todayKey();
    final todaysEntries = appState.entries.where((e) => e.date == today).toList();
    final dimensionProgress = buildDimensionProgress(appState.dimensions, todaysEntries);
    final activeTasks = appState.tasks.where((t) => t.status == TaskStatus.active).toList();
    final completedIds = completedTaskIdsForDate(appState.taskCompletions, today);
    final heatmapDays = buildHeatmap(appState.entries);
    final streak = currentStreak(appState.entries);
    final weeklyPct = weeklyProgressPct(appState.entries, appState.dimensions);

    return RefreshIndicator(
      onRefresh: appState.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(formatDayHeading(today), style: _sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatChip(label: 'Streak', value: '$streak ${streak == 1 ? 'day' : 'days'}')),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'This week', value: '$weeklyPct%')),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Tasks',
                  value: '${activeTasks.where((t) => completedIds.contains(t.id)).length}/${activeTasks.length}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text('Today\'s progress', style: _sectionTitle),
          const SizedBox(height: 12),
          _Card(child: TodayProgressChart(progress: dimensionProgress)),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dimensions', style: _sectionTitle),
              TextButton.icon(
                onPressed: () => showLogEntrySheet(context: context, appState: appState),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dimensionProgress.isEmpty)
            const Text(
              'No dimensions yet. Head to the Dimensions tab to add one.',
              style: TextStyle(color: AppColors.slate500, fontSize: 13),
            )
          else
            ...dimensionProgress.map(
              (p) => _DimensionProgressTile(
                progress: p,
                onTap: () => showLogEntrySheet(context: context, appState: appState, initialDimensionId: p.dimension.id),
              ),
            ),

          const SizedBox(height: 24),
          Text('Tasks', style: _sectionTitle),
          const SizedBox(height: 8),
          if (activeTasks.isEmpty)
            const Text(
              'No active tasks. Head to the Tasks tab to create one.',
              style: TextStyle(color: AppColors.slate500, fontSize: 13),
            )
          else
            ...activeTasks.map(
              (t) => _TaskCheckTile(
                task: t,
                completed: completedIds.contains(t.id),
                onChanged: (completed) => appState.toggleTaskCompletion(t.id, completed),
              ),
            ),

          const SizedBox(height: 24),
          Text('Consistency', style: _sectionTitle),
          const SizedBox(height: 12),
          _Card(child: Heatmap(days: heatmapDays)),
        ],
      ),
    );
  }
}

const _sectionTitle = TextStyle(
  color: AppColors.slate400,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.8,
);

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate800),
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.slate500, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.slate100, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DimensionProgressTile extends StatelessWidget {
  final DimensionProgress progress;
  final VoidCallback onTap;
  const _DimensionProgressTile({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = progress.dimension;
    final color = dimensionColor(d.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.slate900.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate800),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(d.name, style: TextStyle(color: color, fontSize: 12)),
              ),
              const Spacer(),
              if (progress.loggedToday)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: scoreColors[progress.entry!.score], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scoreLabels[progress.entry!.score],
                      style: const TextStyle(color: AppColors.slate300, fontSize: 12),
                    ),
                  ],
                )
              else
                const Text('Not logged', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.slate600, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCheckTile extends StatelessWidget {
  final Task task;
  final bool completed;
  final ValueChanged<bool> onChanged;
  const _TaskCheckTile({required this.task, required this.completed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = task.dimensionName != null ? dimensionColor(task.dimensionName!) : noDimensionColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate800),
        ),
        child: CheckboxListTile(
          value: completed,
          onChanged: (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.violet600,
          title: Text(
            task.title,
            style: TextStyle(
              color: completed ? AppColors.slate500 : AppColors.slate200,
              decoration: completed ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                task.dimensionName ?? 'No dimension',
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
