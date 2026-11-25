import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/domain/energy.dart';

const profile = Profile(
  sex: 'female',
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
  goalMode: 'lose',
  goalRateKgWeek: 0.5,
);

void main() {
  group('BMR / TDEE', () {
    test('Mifflin-St Jeor 女 60kg 165cm 30 岁 = 1320.25', () {
      expect(
        bmrMifflinStJeor(
          female: true,
          weightKg: 60,
          heightCm: 165,
          ageYears: 30,
        ),
        closeTo(1320.25, 0.001),
      );
    });

    test('男性同参数比女性高 166', () {
      final female = bmrMifflinStJeor(
        female: true,
        weightKg: 60,
        heightCm: 165,
        ageYears: 30,
      );
      final male = bmrMifflinStJeor(
        female: false,
        weightKg: 60,
        heightCm: 165,
        ageYears: 30,
      );
      expect(male - female, closeTo(166, 0.001));
    });

    test('活动系数单调', () {
      expect(palFor('sedentary'), lessThan(palFor('light')));
      expect(palFor('light'), lessThan(palFor('moderate')));
      expect(palFor('moderate'), lessThan(palFor('active')));
    });
  });

  group('每日预算', () {
    test('缺口按 25% TDEE 封顶，且不低于摄入下限', () {
      final plan = planEnergy(
        profile: profile,
        weightKg: 60,
        year: 2026,
      );
      final tdee = plan.tdee;
      expect(plan.deficitKcal, lessThanOrEqualTo(tdee * 0.25 + 0.001));
      expect(plan.intakeBudget, greaterThanOrEqualTo(1200));
      expect(plan.intakeBudget + plan.deficitKcal, closeTo(tdee, 0.001));
      expect(plan.note, contains('25%'));
    });

    test('BMI < 18.5 强制关闭减脂缺口', () {
      final plan = planEnergy(profile: profile, weightKg: 48, year: 2026);
      expect(plan.deficitKcal, 0);
      expect(plan.note, contains('BMI'));
    });

    test('宏量热量之和不超过预算', () {
      final plan = planEnergy(
        profile: profile,
        weightKg: 70,
        year: 2026,
        adaptiveTdee: 2200,
      );
      final kcal = plan.proteinG * 4 + plan.carbG * 4 + plan.fatG * 9;
      expect(kcal, lessThanOrEqualTo(plan.intakeBudget + 0.5));
      expect(plan.proteinG, greaterThan(0));
      expect(plan.fatG, greaterThan(0));
    });

    test('维持模式缺口为 0', () {
      final plan = planEnergy(
        profile: profile.copyWith(goalMode: 'maintain'),
        weightKg: 60,
        year: 2026,
      );
      expect(plan.deficitKcal, 0);
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
  });

  group('运动消耗', () {
    test('MET 7 × 60kg × 30min = 210 kcal', () {
      expect(metCalories(met: 7, weightKg: 60, minutes: 30), closeTo(210, 0.001));
    });
  });
}
