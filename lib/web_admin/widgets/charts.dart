import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A bar series inside a [GroupedBarChart]: one color, one value per label.
class BarSeries {
  const BarSeries({
    required this.name,
    required this.color,
    required this.values,
  });

  final String name;
  final Color color;
  final List<double> values;
}

/// Grouped vertical bar chart with gridlines and value labels.
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.labels,
    required this.series,
    this.height = 240,
    this.ySuffix = '',
  });

  final List<String> labels;
  final List<BarSeries> series;
  final double height;
  final String ySuffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _GroupedBarPainter(
          labels: labels,
          series: series,
          ySuffix: ySuffix,
          labelStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _GroupedBarPainter extends CustomPainter {
  _GroupedBarPainter({
    required this.labels,
    required this.series,
    required this.ySuffix,
    required this.labelStyle,
    required this.gridColor,
  });

  final List<String> labels;
  final List<BarSeries> series;
  final String ySuffix;
  final TextStyle labelStyle;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty || series.isEmpty) return;

    const topPad = 22.0;
    const bottomPad = 28.0;
    const leftPad = 46.0;
    final rightPad = 8.0;
    final plotWidth = size.width - leftPad - rightPad;
    final plotHeight = size.height - topPad - bottomPad;

    final maxValue = series
        .expand((s) => s.values)
        .fold<double>(0, (m, v) => math.max(m, v));
    final divisor = maxValue <= 0
        ? 1
        : math.pow(10, (maxValue.toString().length - 1)).toDouble();
    final niceMax = ((maxValue / divisor).ceil() * divisor)
        .clamp(divisor, double.infinity);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final gridLabel = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textAlign: TextAlign.right,
    );

    for (var i = 0; i <= 4; i++) {
      final y = topPad + plotHeight * (i / 4);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        grid,
      );
      final value = niceMax * (1 - i / 4);
      gridLabel.text = TextSpan(
        text: _compact(value) + ySuffix,
        style: labelStyle,
      );
      gridLabel.layout(maxWidth: leftPad - 6);
      gridLabel.paint(canvas, Offset(0, y - gridLabel.height / 2));
    }

    final groupWidth = plotWidth / labels.length;
    final barWidth = groupWidth / (series.length + 1) * 0.8;
    final barGap = groupWidth / series.length;

    for (var g = 0; g < labels.length; g++) {
      for (var s = 0; s < series.length; s++) {
        final value = series[s].values[g];
        final barHeight = (value / niceMax) * plotHeight;
        final centerX = leftPad + groupWidth * g + groupWidth / 2;
        final left = centerX -
            groupWidth / 2 +
            barGap * s +
            (barGap - barWidth) / 2;
        final rect = Rect.fromLTWH(
          left,
          topPad + plotHeight - barHeight,
          barWidth,
          barHeight,
        );
        if (barHeight > 0) {
          final path = Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                rect,
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(4),
              ),
            );
          canvas.drawPath(path, Paint()..color = series[s].color);
        }
      }

      final label = TextPainter(
        text: TextSpan(text: labels[g], style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        textAlign: TextAlign.center,
      )..layout(maxWidth: groupWidth);
      label.paint(
        canvas,
        Offset(
          leftPad + groupWidth * g + (groupWidth - label.width) / 2,
          size.height - bottomPad + 6,
        ),
      );
    }
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _GroupedBarPainter old) =>
      old.labels != labels ||
      old.series != series ||
      old.ySuffix != ySuffix ||
      old.gridColor != gridColor;
}

/// Simple area/line chart for time-series data.
class AreaChart extends StatelessWidget {
  const AreaChart({
    super.key,
    required this.values,
    this.color,
    this.height = 200,
  });

  final List<double> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _AreaPainter(
          values: values,
          color: color ?? theme.colorScheme.primary,
          gridColor: theme.colorScheme.outlineVariant,
          canvasColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.canvasColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;
  final Color canvasColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.length < 2) return;

    const topPad = 8.0;
    const bottomPad = 6.0;
    final leftPad = 0.0;
    final rightPad = 0.0;
    final plotWidth = size.width - leftPad - rightPad;
    final plotHeight = size.height - topPad - bottomPad;

    final maxValue = values.fold<double>(0, (m, v) => math.max(m, v));
    final divisor =
        maxValue <= 0 ? 1 : math.pow(10, (maxValue.toString().length - 1)).toDouble();
    final niceMax =
        ((maxValue / divisor).ceil() * divisor).clamp(divisor, double.infinity);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = topPad + plotHeight * (i / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), grid);
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          leftPad + (values.length == 1 ? plotWidth / 2 : plotWidth * i / (values.length - 1)),
          topPad + plotHeight - (values[i] / niceMax) * plotHeight,
        ),
    ];

    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPath = Path()
      ..moveTo(points.first.dx, topPad + plotHeight)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, topPad + plotHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, plotHeight)),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, line);
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) =>
      old.values != values || old.color != color || old.canvasColor != canvasColor;
}

/// Horizontal proportional bars with labels — used for distribution views
/// (subscription statuses, members per plan, ...) rendered as plain widgets.
class ProportionalBars extends StatelessWidget {
  const ProportionalBars({
    super.key,
    required this.items,
    this.emptyLabel = 'لا توجد بيانات',
  });

  /// (label, count, color)
  final List<({String label, double value, Color color})> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = items.fold<double>(0, (sum, i) => sum + i.value);

    if (total <= 0) {
      return Center(
        child: Text(
          emptyLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final legend = Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.label} (${item.value == item.value.roundToDouble() ? item.value.toInt().toString() : item.value.toStringAsFixed(1)})',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        legend,
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    flex: (item.value / total * 1000).round(),
                    child: Container(color: item.color),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}