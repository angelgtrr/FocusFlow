/// Shared day-progress math for the in-app hourglass widget and the Android
/// status bar notification icon, so both agree on the same fill level.
library;

/// Fraction of the day elapsed since local midnight, 0 at 00:00 to 1 at 24:00.
double hourglassDayProgress([DateTime? at]) {
  final now = at ?? DateTime.now();
  final minutes = now.hour * 60 + now.minute + now.second / 60;
  const dayMinutes = 24 * 60;
  return (minutes / dayMinutes).clamp(0.0, 1.0);
}

String hourglassRemainingLabel(double progress) {
  if (progress >= 1) return 'Day complete';
  final now = DateTime.now();
  final endOfDay = DateTime(now.year, now.month, now.day + 1);
  final diff = endOfDay.difference(now);
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  return '${h}h ${m}m left today';
}

/// Name of the bundled `res/drawable/ic_hourglass_NNN.xml` vector icon
/// closest to `progress`, in 5% steps (000, 005, ..., 100).
String hourglassIconName(double progress) {
  final bucket = ((progress.clamp(0.0, 1.0) * 20).round() * 5).clamp(0, 100);
  return 'ic_hourglass_${bucket.toString().padLeft(3, '0')}';
}
