String toDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String todayKey() => toDateKey(DateTime.now());

DateTime keyToDate(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime addDays(DateTime date, int n) => date.add(Duration(days: n));

DateTime addMonths(DateTime date, int n) {
  final total = date.month - 1 + n;
  final year = date.year + total ~/ 12;
  final month = total % 12 + 1;
  return DateTime(year, month, date.day);
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime startOfWeek(DateTime date) {
  final d = startOfDay(date);
  // DateTime.weekday: Mon=1..Sun=7. Web treats Sunday as start of week (JS getDay(): Sun=0).
  final offset = d.weekday % 7; // Sun -> 0, Mon -> 1, ... Sat -> 6
  return d.subtract(Duration(days: offset));
}

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatDayHeading(String dateKey) {
  final parts = dateKey.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  final includeYear = date.year != DateTime.now().year;
  final weekday = _weekdayNames[date.weekday - 1];
  final month = _monthNames[date.month - 1];
  return '$weekday, $month ${date.day}${includeYear ? ', ${date.year}' : ''}';
}

class DateOccurrence {
  final String occurrenceKey;
  final int daysUntil;
  DateOccurrence({required this.occurrenceKey, required this.daysUntil});
}

DateOccurrence nextOccurrence(String dateKey, String recurring) {
  final today = startOfDay(DateTime.now());
  final original = keyToDate(dateKey);

  if (recurring != 'yearly') {
    final daysUntil = original.difference(today).inDays;
    return DateOccurrence(occurrenceKey: dateKey, daysUntil: daysUntil);
  }

  var occurrence = DateTime(today.year, original.month, original.day);
  if (occurrence.isBefore(today)) {
    occurrence = DateTime(today.year + 1, original.month, original.day);
  }
  final daysUntil = occurrence.difference(today).inDays;
  return DateOccurrence(occurrenceKey: toDateKey(occurrence), daysUntil: daysUntil);
}

class MonthGridDay {
  final String key;
  final DateTime date;
  final bool inMonth;
  MonthGridDay({required this.key, required this.date, required this.inMonth});
}

List<MonthGridDay> buildMonthGrid(DateTime monthDate) {
  final firstOfMonth = DateTime(monthDate.year, monthDate.month, 1);
  final lastOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
  final start = startOfWeek(firstOfMonth);
  final end = startOfWeek(lastOfMonth).add(const Duration(days: 6));

  final days = <MonthGridDay>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    days.add(
      MonthGridDay(key: toDateKey(cursor), date: cursor, inMonth: cursor.month == monthDate.month),
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return days;
}
