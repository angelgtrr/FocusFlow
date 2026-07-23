import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../date_utils.dart';
import '../hourglass.dart';
import '../theme.dart';

/// Hourglass that visualizes the day's progress from midnight to midnight,
/// with a continuously flowing stream so it never looks static even when
/// the water level itself barely moves from one second to the next. At
/// midnight it plays a half-turn flip and restarts for the new day.
class HourglassProgress extends StatefulWidget {
  final void Function(String previousDateKey, String newDateKey)? onDayRollover;

  const HourglassProgress({super.key, this.onDayRollover});

  @override
  State<HourglassProgress> createState() => _HourglassProgressState();
}

class _HourglassProgressState extends State<HourglassProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;
  late double _progress;
  late String _dateKey;
  double _turns = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progress = hourglassDayProgress();
    _dateKey = todayKey();
    _flowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newDateKey = todayKey();
      if (newDateKey != _dateKey) {
        final previousDateKey = _dateKey;
        setState(() {
          _dateKey = newDateKey;
          _turns += 0.5;
          _progress = hourglassDayProgress();
        });
        widget.onDayRollover?.call(previousDateKey, newDateKey);
      } else {
        setState(() => _progress = hourglassDayProgress());
      }
    });
  }

  @override
  void dispose() {
    _flowController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeInOutCubic,
          child: SizedBox(
            height: 160,
            width: 120,
            child: AnimatedBuilder(
              animation: _flowController,
              builder: (context, _) => CustomPaint(
                painter: _HourglassPainter(progress: _progress, flowPhase: _flowController.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(hourglassRemainingLabel(_progress), style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
      ],
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress;
  final double flowPhase;
  _HourglassPainter({required this.progress, required this.flowPhase});

  static const double top = 12, neck = 80, bottom = 148, left = 15, right = 105;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 166);

    final topClip = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(60, neck)
      ..close();
    final bottomClip = Path()
      ..moveTo(left, bottom)
      ..lineTo(right, bottom)
      ..lineTo(60, neck)
      ..close();

    // Each bulb is a triangle, so cross-section width — and therefore drawn
    // area — scales with the square of the distance from the neck (apex).
    // A surface that moves linearly with `progress` would drain area fast
    // near the wide top and barely move near the narrow neck. To make the
    // drawn area (i.e. the volume the eye reads) drain at a constant rate,
    // the distance from the neck must scale with sqrt(1 - progress) instead.
    final bulbHeight = neck - top; // == bottom - neck, bulbs are congruent
    final distanceFromNeck = bulbHeight * math.sqrt(1 - progress);
    final topSurfaceY = neck - distanceFromNeck;
    final bottomSurfaceY = neck + distanceFromNeck;

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      ).createShader(const Rect.fromLTWH(left, top, right - left, bottom - top));

    canvas.save();
    canvas.clipPath(topClip);
    canvas.drawPath(_wavePath(topSurfaceY, left - 10, right + 10, flowPhase), waterPaint);
    canvas.restore();

    canvas.save();
    canvas.clipPath(bottomClip);
    canvas.drawPath(_wavePath(bottomSurfaceY, left - 10, right + 10, flowPhase), waterPaint);
    canvas.restore();

    final capPaint = Paint()..color = AppColors.slate600;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8, 4, 104, 6), const Radius.circular(2)),
      capPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8, 156, 104, 6), const Radius.circular(2)),
      capPaint,
    );

    final streamTop = neck - 2;
    final streamBottom = math.max(bottomSurfaceY, neck - 2);
    if (progress < 1 && streamBottom > streamTop) {
      final streamPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      const dashLen = 4.0, gapLen = 4.0;
      var y = streamTop - flowPhase * (dashLen + gapLen);
      while (y < streamBottom) {
        final segStart = y.clamp(streamTop, streamBottom);
        final segEnd = (y + dashLen).clamp(streamTop, streamBottom);
        if (segEnd > segStart) {
          canvas.drawLine(Offset(60, segStart), Offset(60, segEnd), streamPaint);
        }
        y += dashLen + gapLen;
      }
    }

    final outlinePaint = Paint()
      ..color = AppColors.slate400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final outline = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(60, neck)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..lineTo(60, neck)
      ..close();
    canvas.drawPath(outline, outlinePaint);

    canvas.restore();
  }

  // Builds a wavy horizontal strip closed far below `y` so it reads as a
  // water body with a rippling surface once clipped to the bulb triangle.
  Path _wavePath(double y, double xStart, double xEnd, double phase) {
    const amplitude = 2.5;
    const wavelength = 18.0;
    final offset = phase * wavelength;
    var x = xStart - wavelength + (offset % wavelength);
    final path = Path()..moveTo(x, y);
    var up = true;
    while (x < xEnd) {
      final nx = x + wavelength / 2;
      final cy = up ? y - amplitude : y + amplitude;
      path.quadraticBezierTo(x + wavelength / 4, cy, nx, y);
      x = nx;
      up = !up;
    }
    path.lineTo(xEnd, 200);
    path.lineTo(xStart, 200);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.flowPhase != flowPhase;
}
