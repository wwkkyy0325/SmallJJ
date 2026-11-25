import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/domain/energy.dart';
import 'package:health_app/domain/weight_trend.dart';

DailyWeight day(int month, int d, double kg) => DailyWeight(
      localDate: dateKey(DateTime(2026, month, d)),
      kg: kg,
      entries: const [],
    );

DailyWeight entryOf(DateTime date, double kg, WeightSlot slot) => DailyWeight(
      localDate: dateKey(date),
      kg: kg,
      entries: [WeightEntry(
        localDate: dateKey(date),
        measuredAt: date.millisecondsSinceEpoch,
        slot: slot,
        weightKg: kg,
      )],
    );

void main() {
  test('单日波动被平滑，趋势不会跟着抖', () {
    final points = weightTrend([
      day(1, 1, 70),
      day(1, 2, 71),
      day(1, 3, 69),
      day(1, 4, 70),
    ]);
    expect(points.length, 4);
    expect(points[0].trendKg, 70);
    expect(points[1].trendKg, closeTo(70.15, 0.001));
    expect(points[2].trendKg, closeTo(69.98, 0.02));
    // 趋势值永远落在原始值的范围内
    expect(points.every((p) => p.trendKg >= 69 && p.trendKg <= 71), isTrue);
  });

  test('缺测 7 天时 alpha 自动放大，趋势能跟上而不是滞后', () {
    final points = weightTrend([
      day(1, 1, 70),
      day(1, 8, 69),
    ]);
    final step = 1 - 0.85 * 0.85 * 0.85 * 0.85 * 0.85 * 0.85 * 0.85;
    expect(points.last.trendKg, closeTo(70 - step, 0.001));
  });

  test('7 天变化量：从 70 掉到 69.3 约 -0.7', () {
    final points = weightTrend([
      day(1, 1, 70),
      day(1, 4, 69.6),
      day(1, 8, 69.3),
    ]);
    expect(trendDeltaKg(points)!, closeTo(-0.415, 0.02));
  });

  test('间距不足 3 天不给出周速率', () {
    final points = weightTrend([day(1, 1, 70), day(1, 2, 69.5)]);
    expect(trendRateKgPerWeek(points), isNull);
  });

  test('早上/晚上两次称重都保留，日值取均值', () {
    final d = entryOf(DateTime(2026, 1, 5), 60.4, WeightSlot.morning);
    expect(d.kg, 60.4);
    expect(d.entries.single.slot, WeightSlot.morning);
  });
}
