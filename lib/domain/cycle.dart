import 'dart:math' as math;

import 'energy.dart';

/// 经期预测。用最近若干个周期的中位数 + 标准差给区间，
/// 不做「精确到某一天」的承诺：正常人的周期本来就会飘几天。
class CycleStats {
  const CycleStats({
    required this.cycleLengths,
    this.medianCycleDays,
    this.sd,
    this.lastStart,
    this.nextStart,
    this.windowStart,
    this.windowEnd,
    this.confidence = 'none',
  });

  final List<int> cycleLengths;
  final int? medianCycleDays;
  final double? sd;
  final DateTime? lastStart;
  final DateTime? nextStart;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  /// high / medium / low / none
  final String confidence;

  bool get hasPrediction => nextStart != null;

  String get confidenceLabel => switch (confidence) {
        'high' => '较准',
        'medium' => '一般',
        'low' => '仅供参考',
        _ => '样本不足',
      };

  int? daysUntilNext(DateTime today) =>
      nextStart == null ? null : daysBetween(today, nextStart!);

  /// 今天是否落在预测窗口内
  bool inWindow(DateTime today) {
    final start = windowStart;
    final end = windowEnd;
    if (start == null || end == null) return false;
    final t = dateOnly(today);
    return !t.isBefore(dateOnly(start)) && !t.isAfter(dateOnly(end));
  }
}

/// [starts] 为各次经期开始日（任意顺序）。只用 15–60 天之间的相邻间隔，
/// 滤掉记错、产后、服药等异常区间。
CycleStats analyseCycles(
  List<DateTime> starts, {
  int maxCycles = 6,
}) {
  if (starts.isEmpty) {
    return const CycleStats(cycleLengths: []);
  }
  final sorted = starts.map(dateOnly).toList()
    ..sort((a, b) => a.compareTo(b));
  final lengths = <int>[];
  for (var i = 1; i < sorted.length; i++) {
    final gap = daysBetween(sorted[i - 1], sorted[i]);
    if (gap >= 15 && gap <= 60) lengths.add(gap);
  }
  final recent = lengths.length > maxCycles
      ? lengths.sublist(lengths.length - maxCycles)
      : lengths;
  final lastStart = sorted.last;

  if (recent.isEmpty) {
    return CycleStats(cycleLengths: const [], lastStart: lastStart);
  }

  final stats = describe(recent.map((v) => v.toDouble()).toList());
  final median = stats.median.round();
  final sd = stats.sd;
  // 样本量与波动一起决定可信度：2 次一样长也可能只是巧合。
  final confidence = recent.length >= 4 && sd <= 2.5
      ? 'high'
      : recent.length >= 2 && sd <= 4
          ? 'medium'
          : 'low';

  final next = lastStart.add(Duration(days: median));
  final spread = math.max(1, sd.round());
  return CycleStats(
    cycleLengths: recent,
    medianCycleDays: median,
    sd: sd,
    lastStart: lastStart,
    nextStart: next,
    windowStart: next.subtract(Duration(days: spread)),
    windowEnd: next.add(Duration(days: spread)),
    confidence: confidence,
  );
}

/// 当前处于周期的第几天（1 起）。没有开始日就返回 null。
int? cycleDayOf(CycleStats stats, DateTime today) {
  final start = stats.lastStart;
  if (start == null) return null;
  final d = daysBetween(start, today);
  if (d < 0 || d > 400) return null;
  return d + 1;
}
