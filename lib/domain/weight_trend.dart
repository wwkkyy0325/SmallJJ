import 'dart:math' as math;

import '../data/models.dart';
import 'energy.dart';

/// 趋势曲线上的一点：raw 是当天原始值，trend 是平滑值。
class TrendPoint {
  const TrendPoint({required this.date, required this.trendKg, this.rawKg});

  final DateTime date;
  final double trendKg;
  final double? rawKg;
}

/// 指数加权移动平均。
///
/// 体重有 ±1 kg 的日内水分波动，直接连原始点画折线会被读成「失败」。
/// 缺测不是断线：间隔 n 天时等价于折叠 n 次，alpha 自动放大，
/// 既能跟上真实变化，也不会因为漏记几天就永远滞后。
List<TrendPoint> weightTrend(List<DailyWeight> days, {double alpha = 0.15}) {
  final sorted = [...days]..sort((a, b) => a.localDate.compareTo(b.localDate));
  final out = <TrendPoint>[];
  double? value;
  DateTime? previousDate;
  for (final day in sorted) {
    if (value == null) {
      value = day.kg;
    } else {
      final gap = math.max(1, daysBetween(previousDate!, day.date));
      final step = 1 - math.pow(1 - alpha, gap);
      value = value + step * (day.kg - value);
    }
    previousDate = day.date;
    out.add(TrendPoint(date: day.date, trendKg: value, rawKg: day.kg));
  }
  return out;
}

/// 最近 [days] 天趋势线的变化量（拿不到那么早的数据就用最早的一条）。
double? trendDeltaKg(List<TrendPoint> trend, {int days = 7}) {
  if (trend.length < 2) return null;
  final last = trend.last;
  final target = last.date.subtract(Duration(days: days));
  TrendPoint? baseline;
  for (final point in trend) {
    if (!point.date.isAfter(target)) baseline = point;
  }
  baseline ??= trend.first;
  final span = daysBetween(baseline.date, last.date);
  if (span <= 0) return null;
  return last.trendKg - baseline.trendKg;
}

/// 换算成 kg/周，看「一周大概变了多少」。
double? trendRateKgPerWeek(List<TrendPoint> trend, {int days = 7}) {
  if (trend.length < 2) return null;
  final last = trend.last;
  final target = last.date.subtract(Duration(days: days));
  TrendPoint? baseline;
  for (final point in trend) {
    if (!point.date.isAfter(target)) baseline = point;
  }
  baseline ??= trend.first;
  final span = daysBetween(baseline.date, last.date);
  if (span < 3) return null;
  return (last.trendKg - baseline.trendKg) / span * 7;
}
