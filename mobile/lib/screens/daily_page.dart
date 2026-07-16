import 'package:flutter/material.dart';

import '../app_state.dart';
import '../date_utils.dart';
import '../models.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets/day_note_editor.dart';
import '../widgets/heatmap.dart';
import '../widgets/log_entry_sheet.dart';
import '../widgets/month_calendar.dart';
import '../widgets/today_progress_chart.dart';
import '../widgets/trend_chart.dart';

class DailyPage extends StatefulWidget {
  final AppState appState;
  const DailyPage({super.key, required this.appState});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  String _selectedDate = todayKey();
  bool _calendarOpen = false;

  void _goToYesterday() {
    setState(() => _selectedDate = toDateKey(addDays(keyToDate(todayKey()), -1)));
  }

  void _goToToday() {
    setState(() => _selectedDate = todayKey());
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final selectedDate = _selectedDate;
    final isToday = selectedDate == todayKey();
    final selectedEntries = appState.entries.where((e) => e.date == selectedDate).toList();
    final dimensionProgress = buildDimensionProgress(appState.dimensions, selectedEntries);
    final activeTasks = appState.tasks.where((t) => t.status == TaskStatus.active).toList();
    final completedIds = completedTaskIdsForDate(appState.taskCompletions, selectedDate);
    final heatmapDays = buildHeatmap(appState.entries);
    final trendData = buildTrend(appState.entries);
    final streak = currentStreak(appState.entries);
    final weeklyPct = weeklyProgressPct(appState.entries, appState.dimensions);
    final activeDates = activeDateKeys(appState.entries, appState.taskCompletions, appState.dayNotes);
    final matchingDayNotes = appState.dayNotes.where((n) => n.date == selectedDate);
    final selectedDayNote = matchingDayNotes.isEmpty ? '' : matchingDayNotes.first.note;

    return RefreshIndicator(
      onRefresh: appState.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDayHeading(selectedDate), style: _sectionTitle),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: isToday ? _goToYesterday : _goToToday,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.slate700),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isToday ? 'Yesterday' : 'Today',
                      style: const TextStyle(color: AppColors.slate300, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _calendarOpen = !_calendarOpen),
                    tooltip: 'Toggle calendar',
                    style: IconButton.styleFrom(
                      backgroundColor: _calendarOpen ? AppColors.slate800 : null,
                      side: const BorderSide(color: AppColors.slate700),
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: _calendarOpen ? AppColors.violet400 : AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_calendarOpen) ...[
            const SizedBox(height: 12),
            MonthCalendar(
              selectedDate: selectedDate,
              onSelect: (date) => setState(() => _selectedDate = date),
              activeDates: activeDates,
            ),
          ],
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
                onPressed: () => showLogEntrySheet(context: context, appState: appState, date: selectedDate),
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
                onTap: () => showLogEntrySheet(
                  context: context,
                  appState: appState,
                  date: selectedDate,
                  initialDimensionId: p.dimension.id,
                ),
              ),
            ),

          const SizedBox(height: 24),
          Text('Day note', style: _sectionTitle),
          const SizedBox(height: 8),
          DayNoteEditor(
            date: selectedDate,
            note: selectedDayNote,
            onSave: appState.saveDayNote,
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
                onChanged: (completed) => appState.toggleTaskCompletion(t.id, completed, selectedDate),
              ),
            ),

          const SizedBox(height: 24),
          Text('Consistency', style: _sectionTitle),
          const SizedBox(height: 12),
          _Card(child: Heatmap(days: heatmapDays)),

          const SizedBox(height: 24),
          Text('30-day trend', style: _sectionTitle),
          const SizedBox(height: 12),
          _Card(child: TrendChart(data: trendData)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              if (progress.loggedToday && (progress.entry!.note.isNotEmpty)) ...[
                const SizedBox(height: 6),
                Text(
                  progress.entry!.note,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                ),
              ],
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
