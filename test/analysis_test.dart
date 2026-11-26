import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/domain/analysis.dart';

const _profile = Profile(
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
);

HealthFacts _facts({required DateTime today, required double intake}) {
  return HealthFacts(
    today: today,
    profile: _profile,
    tdee: 1900,
    proteinTargetG: 72,
    todayIntake: intake,
    todayItemCount: 2,
    proteinAvg7d: 70,
    intakeLoggedDays7: 6,
    daysSinceWeightLog: 0,
    currentWeightKg: 60,
    weightTrendKgPerWeek: 0.1,
    streakDays: 3,
  );
}

void main() {
  group('摄入偏低这条提醒', () {
    // 白天只记了个早餐，是「还没记完」，不是「吃得少」。
    test('17:23 只记到 279 kcal：不说话', () {
      final out = runAnalysis(
        _facts(today: DateTime(2026, 11, 26, 17, 23), intake: 279),
      );
      expect(out.where((i) => i.code == 'intake_too_low'), isEmpty);
    });

    test('21:00 仍只记到 279 kcal：给一条中性提示，不用红标', () {
      final out = runAnalysis(
        _facts(today: DateTime(2026, 11, 26, 21), intake: 279),
      );
      final low = out.where((i) => i.code == 'intake_too_low').toList();
      expect(low, hasLength(1));
      expect(low.single.severity, 'info');
      // 两种可能都说出来：真吃得少、或者只是没记全
      expect(low.single.text, contains('没记全'));
      expect(low.single.evidence['intake'], 279);
    });

    test('吃够了（≥1200 kcal）不报', () {
      final out = runAnalysis(
        _facts(today: DateTime(2026, 11, 26, 21), intake: 1500),
      );
      expect(out.where((i) => i.code == 'intake_too_low'), isEmpty);
    });
  });
}
