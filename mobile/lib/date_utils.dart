String toDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String todayKey() => toDateKey(DateTime.now());

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
