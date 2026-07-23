import 'package:flutter/material.dart';

import '../date_utils.dart';
import '../theme.dart';

class MonthCalendar extends StatefulWidget {
  final String selectedDate;
  final ValueChanged<String> onSelect;
  final Set<String> activeDates;

  const MonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    required this.activeDates,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = keyToDate(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      final selected = keyToDate(widget.selectedDate);
      if (selected.year != _viewMonth.year || selected.month != _viewMonth.month) {
        setState(() => _viewMonth = selected);
      }
    }
  }

  void _stepDay(int n) {
    widget.onSelect(toDateKey(addDays(keyToDate(widget.selectedDate), n)));
  }

  static const _weekdayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final today = todayKey();
    final grid = buildMonthGrid(_viewMonth);
    final monthLabel = '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _dayStepButton('← Day', () => _stepDay(-1))),
              const SizedBox(width: 8),
              Expanded(child: _dayStepButton('Today', () => widget.onSelect(today))),
              const SizedBox(width: 8),
              Expanded(
                child: _dayStepButton(
                  'Day →',
                  widget.selectedDate.compareTo(today) >= 0 ? null : () => _stepDay(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _viewMonth = addMonths(_viewMonth, -1)),
                icon: const Icon(Icons.chevron_left, color: AppColors.slate400, size: 20),
                tooltip: 'Previous month',
              ),
              Text(monthLabel, style: const TextStyle(color: AppColors.slate200, fontSize: 14, fontWeight: FontWeight.w500)),
              IconButton(
                onPressed: () => setState(() => _viewMonth = addMonths(_viewMonth, 1)),
                icon: const Icon(Icons.chevron_right, color: AppColors.slate400, size: 20),
                tooltip: 'Next month',
              ),
            ],
          ),
          Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          ..._chunk(grid, 7).map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: week.map((day) => Expanded(child: _dayCell(day, today))).toList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayStepButton(String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: onPressed == null ? AppColors.slate800 : AppColors.slate700),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(color: onPressed == null ? AppColors.slate600 : AppColors.slate300, fontSize: 12),
      ),
    );
  }

  Widget _dayCell(MonthGridDay day, String today) {
    final isFuture = day.key.compareTo(today) > 0;
    final isSelected = day.key == widget.selectedDate;
    final isToday = day.key == today;
    final hasActivity = widget.activeDates.contains(day.key) && !isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: isSelected ? AppColors.violet600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isFuture ? null : () => widget.onSelect(day.key),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected ? Border.all(color: AppColors.violet500) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFuture
                          ? AppColors.slate700
                          : isSelected
                              ? Colors.white
                              : day.inMonth
                                  ? AppColors.slate200
                                  : AppColors.slate600,
                    ),
                  ),
                  if (hasActivity)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: AppColors.emerald400, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<List<T>> _chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      chunks.add(items.sublist(i, i + size > items.length ? items.length : i + size));
    }
    return chunks;
  }
}
