import 'package:flutter/material.dart';

// Mirrors the web app's slate/violet Tailwind palette.
class AppColors {
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);

  static const violet600 = Color(0xFF7C3AED);
  static const violet500 = Color(0xFF8B5CF6);
  static const violet400 = Color(0xFFA78BFA);
  static const violet300 = Color(0xFFC4B5FD);

  static const rose900 = Color(0xFF881337);
  static const rose500 = Color(0xFFF43F5E);
  static const rose400 = Color(0xFFFB7185);

  static const amber700 = Color(0xFFB45309);
  static const amber500 = Color(0xFFF59E0B);

  static const emerald700 = Color(0xFF047857);
  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const emerald300 = Color(0xFF6EE7B7);

  static const sky300 = Color(0xFF7DD3FC);
  static const fuchsia300 = Color(0xFFF0ABFC);
  static const cyan300 = Color(0xFF67E8F9);
  static const orange300 = Color(0xFFFDBA74);
}

// Score 0-4 -> fill color (mirrors SCORE_COLORS in constants.ts)
const List<Color> scoreColors = [
  AppColors.slate800,
  AppColors.rose900,
  AppColors.amber700,
  AppColors.emerald700,
  AppColors.emerald400,
];

/// Interpolated shade for a (possibly fractional) average score, so days
/// with a mix of dimension scores render a smooth in-between shade instead
/// of snapping to the nearest bucket. Mirrors scoreColorForAvg in constants.ts.
Color scoreColorForAvg(double? avgScore) {
  if (avgScore == null) return AppColors.slate900;
  final clamped = avgScore.clamp(0, 4).toDouble();
  final lower = clamped.floor();
  final upper = (lower + 1).clamp(0, 4);
  final t = clamped - lower;
  return Color.lerp(scoreColors[lower], scoreColors[upper], t)!;
}

// Score 0-4 -> accent color for selection rings (mirrors SCORE_RING_COLORS)
const List<Color> scoreRingColors = [
  AppColors.slate600,
  AppColors.rose500,
  AppColors.amber500,
  AppColors.emerald500,
  AppColors.emerald300,
];

const List<String> scoreLabels = [
  'No progress',
  'Low effort',
  'Medium progress',
  'Excellent progress',
  'Exceeded expectations',
];

const List<Color> dimensionPalette = [
  AppColors.violet400,
  AppColors.sky300,
  AppColors.amber500,
  AppColors.emerald400,
  AppColors.rose400,
  AppColors.fuchsia300,
  AppColors.cyan300,
  AppColors.orange300,
];

/// Deterministic per-dimension color, matching the web app's hash function
/// (sum of UTF-16 code units, base 31) so the two apps agree on colors.
Color dimensionColor(String name) {
  int hash = 0;
  for (final unit in name.codeUnits) {
    hash = (hash * 31 + unit) & 0xFFFFFFFF;
  }
  return dimensionPalette[hash % dimensionPalette.length];
}

const noDimensionColor = AppColors.slate500;

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.slate950,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.violet500,
      secondary: AppColors.violet400,
      surface: AppColors.slate900,
      error: AppColors.rose400,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.slate950,
      foregroundColor: AppColors.slate100,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.slate900,
      indicatorColor: AppColors.violet600.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.violet300 : AppColors.slate400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.violet300 : AppColors.slate400);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.violet500, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.slate600),
      labelStyle: const TextStyle(color: AppColors.slate500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.violet600.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.slate200,
      displayColor: AppColors.slate100,
    ),
    cardColor: AppColors.slate900,
    dividerColor: AppColors.slate800,
  );
}
