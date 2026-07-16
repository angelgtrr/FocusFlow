import 'package:flutter/material.dart';

import '../stats.dart';
import '../theme.dart';

/// Line chart of average score over time, mirroring the web app's
/// TrendChart (recharts LineChart over buildTrend data).
class TrendChart extends StatefulWidget {
  final List<TrendPoint> data;
  const TrendChart({super.key, required this.data});

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  void _updateSelection(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;
    const leftPad = 28.0;
    const rightPad = 8.0;
    final plotWidth = (size.width - leftPad - rightPad).clamp(1, double.infinity);
    final t = ((localPosition.dx - leftPad) / plotWidth).clamp(0.0, 1.0);
    final index = (t * (widget.data.length - 1)).round().clamp(0, widget.data.length - 1);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Text(
        'No entries yet.',
        style: TextStyle(color: AppColors.slate500, fontSize: 13),
      );
    }

    final selected = _selectedIndex != null ? widget.data[_selectedIndex!] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
          child: selected == null
              ? null
              : Text(
                  '${selected.date}: ${selected.avgScore.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.slate300, fontSize: 12),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 200,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanDown: (d) => _updateSelection(d.localPosition, size),
                onPanUpdate: (d) => _updateSelection(d.localPosition, size),
                onPanEnd: (_) => setState(() => _selectedIndex = null),
                onTapUp: (_) => setState(() => _selectedIndex = null),
                child: CustomPaint(
                  painter: _TrendChartPainter(data: widget.data, selectedIndex: _selectedIndex),
                  size: size,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<TrendPoint> data;
  final int? selectedIndex;
  _TrendChartPainter({required this.data, required this.selectedIndex});

  static const _leftPad = 28.0;
  static const _rightPad = 8.0;
  static const _bottomPad = 18.0;
  static const _topPad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = _leftPad;
    final plotRight = size.width - _rightPad;
    final plotTop = _topPad;
    final plotBottom = size.height - _bottomPad;
    final plotWidth = plotRight - plotLeft;
    final plotHeight = plotBottom - plotTop;

    double xFor(int i) => data.length <= 1 ? plotLeft : plotLeft + plotWidth * i / (data.length - 1);
    double yFor(double score) => plotBottom - plotHeight * (score.clamp(0, 4) / 4);

    final gridPaint = Paint()
      ..color = AppColors.slate800
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(color: AppColors.slate500, fontSize: 11);

    for (var score = 0; score <= 4; score++) {
      final y = yFor(score.toDouble());
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '$score', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plotLeft - tp.width - 6, y - tp.height / 2));
    }

    // A handful of evenly spaced x-axis date labels (mirrors minTickGap on web).
    final labelCount = (plotWidth / 50).floor().clamp(2, 6);
    final step = ((data.length - 1) / (labelCount - 1)).ceil().clamp(1, data.length);
    for (var i = 0; i < data.length; i += step) {
      final x = xFor(i);
      final tp = TextPainter(
        text: TextSpan(text: data[i].date.substring(5), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plotBottom + 4));
    }

    final linePaint = Paint()
      ..color = AppColors.violet400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final point = Offset(xFor(i), yFor(data[i].avgScore));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    if (selectedIndex != null) {
      final i = selectedIndex!;
      final point = Offset(xFor(i), yFor(data[i].avgScore));
      canvas.drawLine(Offset(point.dx, plotTop), Offset(point.dx, plotBottom), gridPaint);
      canvas.drawCircle(point, 4, Paint()..color = AppColors.violet400);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = AppColors.slate950
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
  }
}
