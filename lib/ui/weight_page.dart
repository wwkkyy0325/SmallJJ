import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/weight_trend.dart';
import '../theme/tokens.dart';
import 'common/surface_card.dart';
import 'app_model.dart';
import 'format.dart';
import 'sheets.dart';

class WeightPage extends StatelessWidget {
  const WeightPage({required this.model, super.key});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final trend = model.trend;
    final target = model.target;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text('体重', style: AppType.display)),
            FilledButton.icon(
              onPressed: () => showWeightSheet(context, model),
              icon: const Icon(Icons.add_rounded, size: AppIcon.sm),
              label: const Text('记一笔'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.md,
            AppSpace.md,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('最近 30 天', style: AppType.label),
                  const Spacer(),
                  _LegendDot(color: AppColor.brand, label: '趋势'),
                  const SizedBox(width: AppSpace.sm),
                  _LegendDot(color: AppColor.inkFaint, label: '原始'),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 190,
                child: trend.isEmpty
                    ? Center(
                        child: Text('还没有体重记录', style: AppType.bodySmall),
                      )
                    : CustomPaint(
                        painter: _WeightChartPainter(
                          points: trend.length > 30
                              ? trend.sublist(trend.length - 30)
                              : trend,
                          goalKg: model.profile?.goalWeightKg,
                        ),
                        size: Size.infinite,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          child: Row(
            children: [
              _Summary(
                label: '当前',
                value: model.entries.isEmpty
                    ? '—'
                    : kgLabel(model.entries.first.weightKg),
                unit: 'kg',
              ),
              _Summary(
                label: '7 天变化',
                value: model.facts?.weightTrendKgPerWeek == null
                    ? '—'
                    : signed(model.facts!.weightTrendKgPerWeek!, digits: 2),
                unit: 'kg/周',
              ),
              _Summary(
                label: '目标',
                value: model.profile?.goalWeightKg == null
                    ? '—'
                    : kgLabel(model.profile!.goalWeightKg!),
                unit: 'kg',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('记录', style: AppType.section),
        const SizedBox(height: AppSpace.xs),
        if (model.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Text(
              '称完随手记一笔就好，时间自动取现在，两天一次也能画出趋势。',
              style: AppType.bodySmall,
            ),
          )
        else
          for (final entry in model.entries)
            Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpace.lg),
                color: AppColor.heart,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColor.onBrand),
              ),
              onDismissed: (_) => model.deleteWeight(entry.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${relativeDay(entry.date, model.now)} ${clockLabel(entry.date)}',
                  style: AppType.title,
                ),
                trailing: Text(
                  '${kgLabel(entry.weightKg)} kg',
                  style: AppType.metric,
                ),
                onTap: () => showWeightSheet(context, model, entry: entry),
              ),
            ),
        if (target != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.md),
            child: Text(
              '预算按 ${kcalLabel(target.tdee)} kcal 的日常消耗计算，'
              '这个数字会用你的体重和摄入逐步校准。',
              style: AppType.micro,
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.label),
          const SizedBox(height: AppSpace.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppType.metric),
              const SizedBox(width: 2),
              Text(unit, style: AppType.micro),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.xxs),
        Text(label, style: AppType.micro),
      ],
    );
  }
}

/// 折线 + 原始点。刻意不画柱状：体重不是「每天完成任务」。
class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.points, this.goalKg});

  final List<TrendPoint> points;
  final double? goalKg;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 34.0;
    const bottom = 18.0;
    const top = 6.0;
    final chartWidth = size.width - left - 6;
    final chartHeight = size.height - top - bottom;

    final values = <double>[
      for (final p in points) ...[p.trendKg, if (p.rawKg != null) p.rawKg!],
      ?goalKg,
    ];
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if (maxV - minV < 1.2) {
      final mid = (maxV + minV) / 2;
      minV = mid - 0.6;
      maxV = mid + 0.6;
    }
    minV -= 0.3;
    maxV += 0.3;

    double x(int index) =>
        left + (points.length == 1 ? chartWidth / 2 : chartWidth * index / (points.length - 1));
    double y(double value) =>
        top + chartHeight * (1 - (value - minV) / (maxV - minV));

    final gridPaint = Paint()
      ..color = AppColor.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final value = minV + (maxV - minV) * i / 2;
      final gy = y(value);
      canvas.drawLine(Offset(left, gy), Offset(size.width - 6, gy), gridPaint);
      final label = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(2),
          style: AppType.micro.copyWith(fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, gy - label.height / 2));
    }

    if (goalKg != null) {
      final paint = Paint()
        ..color = AppColor.amber
        ..strokeWidth = 1.4;
      final gy = y(goalKg!);
      var dx = left;
      while (dx < size.width - 6) {
        canvas.drawLine(
          Offset(dx, gy),
          Offset(math.min(dx + 6, size.width - 6), gy),
          paint,
        );
        dx += 11;
      }
    }

    final rawPaint = Paint()..color = AppColor.inkFaint.withValues(alpha: 0.55);
    for (var i = 0; i < points.length; i++) {
      final raw = points[i].rawKg;
      if (raw == null) continue;
      canvas.drawCircle(Offset(x(i), y(raw)), 2.2, rawPaint);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(x(i), y(points[i].trendKg));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColor.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      if (i != points.length - 1) continue;
      canvas.drawCircle(
        Offset(x(i), y(points[i].trendKg)),
        3.4,
        Paint()..color = AppColor.brand,
      );
    }

    final first = points.first.date;
    final last = points.last.date;
    for (final entry in [(first, left, Alignment.centerLeft), (last, size.width - 6, Alignment.centerRight)]) {
      final painter = TextPainter(
        text: TextSpan(
          text: monthDayLabel(entry.$1),
          style: AppType.micro.copyWith(fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = entry.$3 == Alignment.centerRight
          ? entry.$2 - painter.width
          : entry.$2;
      painter.paint(canvas, Offset(dx, size.height - bottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.points != points || old.goalKg != goalKg;
}
