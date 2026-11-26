import 'dart:math' as math;

import '../data/models.dart';

/// 纯能量计算：不碰数据库、不碰界面，全部可以单测。

/// 1 kg 脂肪 ≈ 7700 kcal。国际通用近似值，够个人规划用。
const double kcalPerKgBodyMass = 7700;

/// 年龄按「今天年份 − 出生年」算，误差最多一岁，对 BMR 影响 < 1%。
int ageFromBirthYear(int birthYear, {required int year}) => year - birthYear;

/// Mifflin-St Jeor（1990）女性式：10W + 6.25H − 5A − 161。
///
/// 这个应用只服务女性，男式（+5）不再需要：少一个参数，就少一次「该传 true
/// 还是 false」的误用。数值本身仍是同一篇论文的原始公式，没有改动。
double bmrFemale({
  required double weightKg,
  required double heightCm,
  required int ageYears,
}) {
  return 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161;
}

/// 活动系数（FAO/WHO 体力活动水平的常用近似）。
double palFor(String activityLevel) => switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      _ => 1.375,
    };

double bmi({required double weightKg, required double heightCm}) {
  final m = heightCm / 100;
  return weightKg / (m * m);
}

/// 一次称重的体重取哪一天：以本地日期为准。
String dateKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime local) => DateTime(local.year, local.month, local.day);

int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

/// 目标速率 → 每日缺口（负值代表盈余）。
double deficitFromRate(double kgPerWeek) => kgPerWeek * kcalPerKgBodyMass / 7;

/// 女性摄入下限。低于它长期执行会掉肌肉、掉代谢；这是保守阈值，
/// 不是医学结论，界面上会明示「已按下限钳制」。
const double intakeFloorFemale = 1200;

class EnergyPlan {
  const EnergyPlan({
    required this.bmr,
    required this.tdee,
    required this.intakeBudget,
    required this.deficitKcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.note,
    this.adaptiveWeight = 0,
  });

  final double bmr;
  final double tdee;
  final double intakeBudget;
  final double deficitKcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  /// 被钳制时给出人话原因，空串表示按公式直接算出来的。
  final String note;

  /// 0 = 全用公式，1 = 全用自适应；仅在自适应生效时 > 0。
  final double adaptiveWeight;

  bool get clamped => note.isNotEmpty;
}

/// 计算当天预算。
///
/// - [adaptiveTdee] 来自历史能量平衡反解，有值时优先，公式 TDEE 只做锚点。
/// - 缺口上限 25% TDEE；摄入不低于 [intakeFloor]；BMI < 18.5 强制不减肥。
EnergyPlan planEnergy({
  required Profile profile,
  required double weightKg,
  required int year,
  double? adaptiveTdee,
}) {
  final age = ageFromBirthYear(profile.birthYear, year: year);
  final bmr = bmrFemale(
    weightKg: weightKg,
    heightCm: profile.heightCm,
    ageYears: age,
  );
  final formulaTdee = bmr * palFor(profile.activityLevel);
  final tdee = adaptiveTdee ?? formulaTdee;

  var mode = profile.goalMode;
  final notes = <String>[];
  final currentBmi = bmi(weightKg: weightKg, heightCm: profile.heightCm);
  if (mode == 'lose' && currentBmi < 18.5) {
    mode = 'maintain';
    notes.add('BMI ${currentBmi.toStringAsFixed(1)} 偏低，已关闭减脂缺口');
  }

  var deficit = switch (mode) {
    'lose' => deficitFromRate(profile.goalRateKgWeek),
    'gain' => -deficitFromRate(profile.goalRateKgWeek),
    _ => 0.0,
  };

  final cap = tdee * 0.25;
  if (deficit > cap) {
    deficit = cap;
    notes.add('缺口按 TDEE 的 25% 封顶');
  }
  if (deficit < -500) {
    deficit = -500;
    notes.add('盈余按 500 kcal/天 封顶');
  }

  var budget = tdee - deficit;
  const floor = intakeFloorFemale;
  if (budget < floor) {
    budget = floor;
    deficit = tdee - floor;
    if (deficit < 0) deficit = 0;
    notes.add('摄入按下限 ${floor.round()} kcal 钳制');
  }

  // 宏量：蛋白优先，脂肪给最低必需，其余给碳水。
  final kbju = weightKg;
  final proteinPerKg = switch (mode) {
    'lose' => 1.6,
    'gain' => 1.6,
    _ => 1.2,
  };
  var proteinG = kbju * proteinPerKg;
  final maxProteinKcal = budget * 0.35;
  if (proteinG * 4 > maxProteinKcal) {
    proteinG = maxProteinKcal / 4;
  }
  final fatG = (weightKg * 0.8).clamp(30.0, budget * 0.35 / 9);
  var carbG = (budget - proteinG * 4 - fatG * 9) / 4;
  if (carbG < 0) carbG = 0;

  return EnergyPlan(
    bmr: bmr,
    tdee: tdee,
    intakeBudget: budget,
    deficitKcal: deficit,
    proteinG: proteinG,
    carbG: carbG,
    fatG: fatG,
    note: notes.join('；'),
    adaptiveWeight: adaptiveTdee == null ? 0 : 1,
  );
}

/// 能量平衡反解 TDEE：一段时间里「吃进去的 − 体重变化折算的」就是消耗。
///
/// 需要至少 [minDays] 天的摄入记录和至少 5 天体重记录；
/// 数据不够就返回 null，界面继续用公式值，不硬猜。
/// 结果与公式值按 7:3 混合，并与上一次的值相差不超过 ±150 kcal/天。
double? adaptiveTdeeFromBalance({
  required List<DailyWeight> weights,
  required double Function(String localDate) intakeForDate,
  required double formulaTdee,
  double? previousAdaptive,
  int minDays = 10,
}) {
  if (weights.length < 5) return null;
  final sorted = [...weights]..sort((a, b) => a.localDate.compareTo(b.localDate));
  final first = sorted.first;
  final last = sorted.last;
  final span = daysBetween(first.date, last.date);
  if (span < minDays) return null;

  var sum = 0.0;
  var logged = 0;
  for (var i = 0; i < span; i++) {
    final day = first.date.add(Duration(days: i));
    final kcal = intakeForDate(dateKey(day));
    if (kcal > 0) {
      sum += kcal;
      logged++;
    }
  }
  // 记录天数太少时均值不可信（把漏记当成断食会把 TDEE 估低）。
  if (logged < minDays * 0.7) return null;

  final avgIntake = sum / logged;
  final lostKg = first.kg - last.kg;
  final balanceTdee = avgIntake + lostKg * kcalPerKgBodyMass / span;

  final blended = 0.7 * balanceTdee + 0.3 * formulaTdee;
  var clamped = blended.clamp(formulaTdee * 0.8, formulaTdee * 1.3);
  if (previousAdaptive != null) {
    clamped = clamped.clamp(previousAdaptive - 150, previousAdaptive + 150);
  }
  return clamped.toDouble();
}

/// 运动消耗：MET × 体重(kg) × 小时。MET 值来自 Compendium of Physical Activities。
double metCalories({
  required double met,
  required double weightKg,
  required int minutes,
}) =>
    met * weightKg * (minutes / 60);

double round1(double v) => (v * 10).round() / 10;
double round0(double v) => v.roundToDouble();

/// 取若干天日均摄入；没有记录返回 0。
double averageIntake(List<double> dailyKcal) {
  final logged = dailyKcal.where((v) => v > 0).toList();
  if (logged.isEmpty) return 0;
  return logged.reduce((a, b) => a + b) / logged.length;
}

/// 把数组的极值裁掉，用于周期长度统计（避免一次异常把均值带跑）。
({double mean, double sd, double median}) describe(List<double> values) {
  if (values.isEmpty) return (mean: 0, sd: 0, median: 0);
  final sorted = [...values]..sort();
  final mean = sorted.reduce((a, b) => a + b) / sorted.length;
  final variance =
      sorted.map((v) => math.pow(v - mean, 2).toDouble()).reduce((a, b) => a + b) /
          sorted.length;
  final mid = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
  return (mean: mean, sd: math.sqrt(variance), median: median);
}
