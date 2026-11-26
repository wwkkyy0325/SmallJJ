import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/domain/energy.dart';

const profile = Profile(
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
);

void main() {
  group('BMR / TDEE', () {
    test('Mifflin-St Jeor 女 60kg 165cm 30 岁 = 1320.25', () {
      expect(
        bmrFemale(weightKg: 60, heightCm: 165, ageYears: 30),
        closeTo(1320.25, 0.001),
      );
    });

    test('体重每多 1 kg，BMR 高 10 kcal', () {
      final light = bmrFemale(weightKg: 60, heightCm: 165, ageYears: 30);
      final heavy = bmrFemale(weightKg: 61, heightCm: 165, ageYears: 30);
      expect(heavy - light, closeTo(10, 0.001));
    });

    test('活动系数单调', () {
      expect(palFor('sedentary'), lessThan(palFor('light')));
      expect(palFor('light'), lessThan(palFor('moderate')));
      expect(palFor('moderate'), lessThan(palFor('active')));
    });
  });

  group('估算消耗', () {
    test('公式值 = BMR × 活动系数，没有预算和缺口', () {
      final plan = planEnergy(profile: profile, weightKg: 60, year: 2026);
      final bmr = bmrFemale(weightKg: 60, heightCm: 165, ageYears: 30);
      expect(plan.bmr, closeTo(bmr, 0.001));
      expect(plan.tdee, closeTo(bmr * palFor('light'), 0.001));
      expect(plan.adaptiveWeight, 0);
    });

    test('自适应值优先，公式只做锚点', () {
      final plan = planEnergy(
        profile: profile,
        weightKg: 60,
        year: 2026,
        adaptiveTdee: 2200,
      );
      expect(plan.tdee, 2200);
      expect(plan.adaptiveWeight, 1);
    });

    test('宏量热量之和不超过估算消耗', () {
      final plan = planEnergy(
        profile: profile,
        weightKg: 70,
        year: 2026,
        adaptiveTdee: 2200,
      );
      final kcal = plan.proteinG * 4 + plan.carbG * 4 + plan.fatG * 9;
      expect(kcal, lessThanOrEqualTo(plan.tdee + 0.5));
      expect(plan.proteinG, greaterThan(0));
      expect(plan.fatG, greaterThan(0));
    });

    test('BMI 偏低也不改估算值：没有计划，就没有要关掉的东西', () {
      final plan = planEnergy(profile: profile, weightKg: 48, year: 2026);
      final bmr = bmrFemale(weightKg: 48, heightCm: 165, ageYears: 30);
      expect(plan.tdee, closeTo(bmr * palFor('light'), 0.001));
    });
  });

  group('自适应 TDEE', () {
    List<DailyWeight> series({required int days, required double lossPerDay}) {
      final start = DateTime(2026, 1, 1);
      return [
        for (var i = 0; i < days; i++)
          DailyWeight(
            localDate: dateKey(start.add(Duration(days: i))),
            kg: 70 - lossPerDay * i,
            entries: const [],
          ),
      ];
    }

    test('14 天吃 1600、掉 1kg → 反解约 2049 kcal（公式 1815）', () {
      final result = adaptiveTdeeFromBalance(
        weights: series(days: 14, lossPerDay: 1 / 14),
        intakeForDate: (_) => 1600,
        formulaTdee: 1815.34,
      );
      expect(result, isNotNull);
      expect(result!, closeTo(2049.5, 1.5));
    });

    test('摄入记录不足一半时不给结果', () {
      var i = 0;
      final result = adaptiveTdeeFromBalance(
        weights: series(days: 14, lossPerDay: 1 / 14),
        intakeForDate: (_) => i++ % 4 == 0 ? 1600 : 0,
        formulaTdee: 1815.34,
      );
      expect(result, isNull);
    });

    test('体重记录不足 5 天时不给结果', () {
      expect(
        adaptiveTdeeFromBalance(
          weights: series(days: 4, lossPerDay: 0.1),
          intakeForDate: (_) => 1600,
          formulaTdee: 1815.34,
        ),
        isNull,
      );
    });

    test('与上一次的值相差不超过 150 kcal', () {
      final result = adaptiveTdeeFromBalance(
        weights: series(days: 14, lossPerDay: 2 / 14),
        intakeForDate: (_) => 3000,
        formulaTdee: 1815.34,
        previousAdaptive: 1900,
      )!;
      expect(result, closeTo(2050, 0.001));
    });

    test('完美线性的斜率就是端点差：-1/14 kg/天', () {
      final slope = weightSlopeKgPerDay(series(days: 14, lossPerDay: 1 / 14));
      expect(slope!, closeTo(-1 / 14, 1e-9));
    });

    test('最后一天多喝 1 kg 水，斜率几乎不动', () {
      final weights = series(days: 14, lossPerDay: 1 / 14);
      final spiked = [
        ...weights.take(13),
        DailyWeight(
          localDate: weights.last.localDate,
          kg: weights.last.kg + 1,
          entries: const [],
        ),
      ];
      expect(weightSlopeKgPerDay(spiked)!, closeTo(-1 / 14, 0.035));
    });

    test('端点那天水的重量不会把反解的 TDEE 带跑', () {
      // 旧算法用「最后一条 − 第一条」：最后一天重 1 kg 就等于这两周没掉秤，
      // 反解只有 1600（混合后 1664）。最小二乘只让一个点说话。
      final weights = series(days: 14, lossPerDay: 1 / 14);
      final spiked = [
        ...weights.take(13),
        DailyWeight(
          localDate: weights.last.localDate,
          kg: weights.last.kg + 1,
          entries: const [],
        ),
      ];
      final result = adaptiveTdeeFromBalance(
        weights: spiked,
        intakeForDate: (_) => 1600,
        formulaTdee: 1815.34,
      )!;
      expect(result, greaterThan(1850));
      expect(result, closeTo(1896, 25));
    });
  });

  group('今日收支（消耗 − 摄入）', () {
    test('没吃超：差值为正，条子按消耗算比例', () {
      const b = DayBalance(intakeKcal: 1410, expenditureKcal: 2050);
      expect(b.gapKcal, 640);
      expect(b.isSurplus, isFalse);
      expect(b.magnitudeKcal, 640);
      expect(b.ratio, closeTo(1410 / 2050, 1e-9));
    });

    test('吃超了：差值为负，条子满格，取值用绝对值', () {
      const b = DayBalance(intakeKcal: 2280, expenditureKcal: 2050);
      expect(b.gapKcal, -230);
      expect(b.isSurplus, isTrue);
      expect(b.magnitudeKcal, 230);
      expect(b.ratio, 1);
    });

    test('差值随当天摄入变，不是一个设置里的常数', () {
      const b = DayBalance(intakeKcal: 1410, expenditureKcal: 2050);
      expect(b.gapKcal, 2050 - 1410);
      expect(b.gapKcal, isNot(450));
    });
  });

  group('运动消耗', () {
    test('MET 7 × 60kg × 30min = 210 kcal', () {
      expect(metCalories(met: 7, weightKg: 60, minutes: 30), closeTo(210, 0.001));
    });
  });
}
