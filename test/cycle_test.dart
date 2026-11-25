import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/domain/cycle.dart';

List<DateTime> starts(List<int> dayOffsets) {
  final base = DateTime(2026, 1, 1);
  return [for (final d in dayOffsets) base.add(Duration(days: d))];
}

void main() {
  test('三个 28 天周期 → 中位 28、下次在 28 天后', () {
    final stats = analyseCycles(starts([0, 28, 56]));
    expect(stats.cycleLengths, [28, 28]);
    expect(stats.medianCycleDays, 28);
    expect(stats.sd, closeTo(0, 0.001));
    expect(stats.confidence, 'medium');
    expect(stats.nextStart, DateTime(2026, 3, 26));
    expect(stats.windowStart, DateTime(2026, 3, 25));
    expect(stats.windowEnd, DateTime(2026, 3, 27));
  });

  test('中位数不被单次异常带跑', () {
    final stats = analyseCycles(starts([0, 28, 57, 86, 130]));
    expect(stats.cycleLengths, [28, 29, 29, 44]);
    expect(stats.medianCycleDays, 29);
    expect(stats.confidence, 'low');
  });

  test('间隔在 15–60 天之外直接丢弃（记错的开始日）', () {
    final stats = analyseCycles(starts([0, 5, 33]));
    expect(stats.cycleLengths, [28]);
  });

  test('只有一次开始日：能算周期第几天，但没有预测', () {
    final stats = analyseCycles(starts([0]));
    expect(stats.hasPrediction, isFalse);
    expect(cycleDayOf(stats, DateTime(2026, 1, 10)), 10);
  });

  test('样本少时不给「较准」', () {
    final stats = analyseCycles(starts([0, 28]));
    expect(stats.confidence, isNot('high'));
  });

  test('预测窗口包含经期当天', () {
    final stats = analyseCycles(starts([0, 28, 56]));
    expect(stats.inWindow(DateTime(2026, 3, 26)), isTrue);
    expect(stats.inWindow(DateTime(2026, 3, 10)), isFalse);
  });
}
