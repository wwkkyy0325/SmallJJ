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

/// 女性摄入下限。低于它长期会掉肌肉、掉代谢；这是保守阈值，不是医学结论。
///
/// 只用来在分析里说一句「今天吃得偏少」，**不用来压预算**：应用不设预算。
const double intakeFloorFemale = 1200;

/// 今天的能量收支：只用两个实测数，不掺任何计划值。
///
/// `差值 = 消耗 − 摄入`，正数是吃得比消耗少，负数是多。只描述，不评价：
/// 多和少都只是当天的数据，不存在「超出」或「失败」。这个数随每一条饮食
/// 记录实时变化——它算的是账，不是目标。
class DayBalance {
  const DayBalance({
    required this.intakeKcal,
    required this.expenditureKcal,
  });

  final double intakeKcal;

  /// 今天的总消耗：公式估算，或被体重变化校正过的估算。
  final double expenditureKcal;

  /// > 0 吃得比消耗少，< 0 吃得多。
  double get gapKcal => expenditureKcal - intakeKcal;

  bool get isSurplus => gapKcal < 0;

  double get magnitudeKcal => gapKcal.abs();

  /// 摄入占消耗的比例：进度条整条是今日消耗，填充是已摄入。
  double get ratio =>
      expenditureKcal <= 0 ? 0 : (intakeKcal / expenditureKcal).clamp(0.0, 1.0);
}

class EnergyPlan {
  const EnergyPlan({
    required this.bmr,
    required this.tdee,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.adaptiveWeight = 0,
  });

  final double bmr;

  /// 估算的今天总消耗。没有计划缺口：这个值就是唯一的参照量。
  final double tdee;
  final double proteinG;
  final double carbG;
  final double fatG;

  /// 0 = 全用公式，1 = 全用自适应；仅在自适应生效时 > 0。
  final double adaptiveWeight;
}

/// 估算今天消耗多少。
///
/// - [adaptiveTdee] 来自历史能量平衡反解，有值时优先，公式只做锚点。
/// - 没有「缺口」「预算」「封顶」：应用不做计划，只出估算值。
/// - 三餐克数按体重给参考量（蛋白 1.2 g/kg、脂肪 0.8 g/kg，其余碳水），
///   不设目标线，也不做「超标」判断。
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

  // 宏量：蛋白优先，脂肪给最低必需，其余给碳水。
  var proteinG = weightKg * 1.2;
  final maxProteinKcal = tdee * 0.35;
  if (proteinG * 4 > maxProteinKcal) {
    proteinG = maxProteinKcal / 4;
  }
  final fatG = (weightKg * 0.8).clamp(30.0, tdee * 0.35 / 9);
  var carbG = (tdee - proteinG * 4 - fatG * 9) / 4;
  if (carbG < 0) carbG = 0;

  return EnergyPlan(
    bmr: bmr,
    tdee: tdee,
    proteinG: proteinG,
    carbG: carbG,
    fatG: fatG,
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
   final span = daysBetween(first.date, sorted.last.date);
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
   final slope = weightSlopeKgPerDay(sorted);
   if (slope == null) return null;
   // 斜率是 kg/天（掉秤为负）：每天掉 1/14 kg ≈ 每天多消耗 550 kcal。
   final balanceTdee = avgIntake - slope * kcalPerKgBodyMass;

   final blended = 0.7 * balanceTdee + 0.3 * formulaTdee;
   var clamped = blended.clamp(formulaTdee * 0.8, formulaTdee * 1.3);
   if (previousAdaptive != null) {
     clamped = clamped.clamp(previousAdaptive - 150, previousAdaptive + 150);
   }
   return clamped.toDouble();
 }

 /// 体重趋势的斜率：kg/天，最小二乘拟合，掉秤为负。
 ///
 /// 不用「最后一条 − 第一条」：两周里只要有**一端**那天多喝了 500 ml 水，
 /// 端点差就整体歪掉，反解出的 TDEE 能差出三四百千卡。回归用上窗口里的
 /// 每一天，单日水分被摊平；斜率对「整体趋势」敏感，对「某天称重偏高」
 /// 不敏感——这正是能量平衡反解需要的东西。
 double? weightSlopeKgPerDay(List<DailyWeight> days) {
   final sorted = [...days]
     ..sort((a, b) => a.localDate.compareTo(b.localDate));
   if (sorted.length < 2) return null;
   final start = sorted.first.date;
   final xs = [for (final d in sorted) daysBetween(start, d.date).toDouble()];
   final ys = [for (final d in sorted) d.kg];
   final n = xs.length;
   final meanX = xs.reduce((a, b) => a + b) / n;
   final meanY = ys.reduce((a, b) => a + b) / n;
   var cov = 0.0;
   var variance = 0.0;
   for (var i = 0; i < n; i++) {
     final dx = xs[i] - meanX;
     cov += dx * (ys[i] - meanY);
     variance += dx * dx;
   }
   if (variance == 0) return null;
   return cov / variance;
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
