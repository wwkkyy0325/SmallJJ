import '../data/models.dart';
import 'cycle.dart';
import 'energy.dart';

/// 「AI 健康分析」的底座：**规则先算出事实，语言只是把事实说出来**。
///
/// 每条洞察都带 evidence（被引用的数字），界面可以展开看依据；
/// 不做任何没有数据支撑的建议，也不产出体重/疾病的诊断结论。
class HealthFacts {
  const HealthFacts({
    required this.today,
    required this.profile,
    required this.tdee,
    required this.intakeBudget,
    required this.deficitKcal,
    required this.proteinTargetG,
    required this.todayIntake,
    required this.todayItemCount,
    required this.proteinAvg7d,
    required this.intakeLoggedDays7,
    required this.daysSinceWeightLog,
    required this.currentWeightKg,
    required this.weightTrendKgPerWeek,
    required this.streakDays,
    this.cycle,
    this.daysUntilPeriod,
    this.cycleDay,
    this.inPeriodWindow = false,
  });

  final DateTime today;
  final Profile profile;
  final double tdee;
  final double intakeBudget;
  final double deficitKcal;
  final double proteinTargetG;
  final double todayIntake;
  final int todayItemCount;
  final double proteinAvg7d;
  final int intakeLoggedDays7;
  final int daysSinceWeightLog;
  final double? currentWeightKg;
  final double? weightTrendKgPerWeek;
  final int streakDays;
  final CycleStats? cycle;
  final int? daysUntilPeriod;
  final int? cycleDay;
  final bool inPeriodWindow;

  double get remainingKcal => intakeBudget - todayIntake;
  double? get bmiValue => currentWeightKg == null
      ? null
      : bmi(weightKg: currentWeightKg!, heightCm: profile.heightCm);
}

const _severityRank = {'action': 0, 'warn': 1, 'info': 2};

/// 规则集。顺序即优先级（同一严重度里先出现的先展示）。
List<Insight> runAnalysis(HealthFacts f) {
  final out = <Insight>[];

  // 1. 今天还没记录饮食
  if (f.todayItemCount == 0 && f.today.hour >= 11) {
    out.add(const Insight(
      code: 'intake_empty',
      severity: 'action',
      text: '今天还没有饮食记录。记一条，热量缺口才算得准。',
    ));
  }

  // 2. 今天超预算
  if (f.todayItemCount > 0 && f.todayIntake > f.intakeBudget + 50) {
    final over = f.todayIntake - f.intakeBudget;
    out.add(Insight(
      code: 'intake_over',
      severity: 'warn',
      text: '今天超出预算 ${over.round()} kcal。'
          '不用补偿性断食，明天按预算吃就行。',
      evidence: {'intake': f.todayIntake.round(), 'budget': f.intakeBudget.round()},
    ));
  }

  // 3. 摄入明显过低
  if (f.todayItemCount > 0 && f.todayIntake < intakeFloor(f.profile.isFemale)) {
    out.add(Insight(
      code: 'intake_too_low',
      severity: 'warn',
      text: '今天只记到 ${f.todayIntake.round()} kcal，低于摄入下限。'
          '长期吃这么少会掉肌肉、代谢下降。',
      evidence: {'intake': f.todayIntake.round()},
    ));
  }

  // 4. 体重速率 vs 目标速率
  final rate = f.weightTrendKgPerWeek;
  if (rate != null && f.profile.goalMode == 'lose') {
    final target = -f.profile.goalRateKgWeek;
    final diff = rate - target;
    if (diff.abs() <= 0.3) {
      out.add(Insight(
        code: 'rate_on_track',
        severity: 'info',
        text: '趋势 ${rate.toStringAsFixed(2)} kg/周，和目标 ${target.toStringAsFixed(2)} 一致，保持。',
        evidence: {'rate': rate, 'target': target},
      ));
    } else if (diff < -0.3) {
      out.add(Insight(
        code: 'rate_fast',
        severity: 'warn',
        text: '掉得比计划快（${rate.toStringAsFixed(2)} kg/周）。'
            '多数是水分和糖原，别把预算再往下压。',
        evidence: {'rate': rate, 'target': target},
      ));
    } else {
      out.add(Insight(
        code: 'rate_slow',
        severity: 'info',
        text: '趋势 ${rate.toStringAsFixed(2)} kg/周，比目标慢。'
            '先看这周记录是否齐全，再决定要不要动预算。',
        evidence: {'rate': rate, 'target': target},
      ));
    }
  }

  // 5. 蛋白不足
  if (f.intakeLoggedDays7 >= 3 && f.proteinAvg7d > 0) {
    final ratio = f.proteinAvg7d / f.proteinTargetG;
    if (ratio < 0.8) {
      out.add(Insight(
        code: 'protein_low',
        severity: 'info',
        text: '近 7 天蛋白平均 ${f.proteinAvg7d.round()} g，'
            '目标 ${f.proteinTargetG.round()} g。缺口期蛋白不够容易掉肌肉。',
        evidence: {'avg': f.proteinAvg7d.round(), 'target': f.proteinTargetG.round()},
      ));
    }
  }

  // 6. 体重记录中断
  if (f.daysSinceWeightLog >= 3) {
    out.add(Insight(
      code: 'weight_missing',
      severity: 'action',
      text: '已经 ${f.daysSinceWeightLog} 天没称重，趋势线会变钝。'
          '早上起床后称一次就够。',
      evidence: {'days': f.daysSinceWeightLog},
    ));
  }

  // 7. 经期
  final cycle = f.cycle;
  if (f.profile.periodTracking && cycle != null && cycle.hasPrediction) {
    if (f.inPeriodWindow && (f.daysUntilPeriod ?? 99) >= -3) {
      out.add(Insight(
        code: 'period_soon',
        severity: 'info',
        text: '按最近 ${cycle.cycleLengths.length} 个周期（中位 ${cycle.medianCycleDays} 天）推算，'
            '经期在 ${cycle.windowStart!.month}/${cycle.windowStart!.day}'
            '–${cycle.windowEnd!.month}/${cycle.windowEnd!.day} 之间。'
            '这几天体重会因水分上涨 0.5–1.5 kg，不代表长胖。',
        evidence: {
          'median': cycle.medianCycleDays,
          'sd': cycle.sd == null ? null : double.parse(cycle.sd!.toStringAsFixed(2)),
        },
      ));
    }
    if ((cycle.sd ?? 0) > 7) {
      out.add(Insight(
        code: 'period_irregular',
        severity: 'warn',
        text: '周期波动 ${cycle.sd!.toStringAsFixed(1)} 天，偏大。'
            '记录再多几个周期再看；如果持续不规律，建议就医而不是靠 App 判断。',
        evidence: {'sd': double.parse(cycle.sd!.toStringAsFixed(2))},
      ));
    }
  }

  // 8. BMI 边界（只提示，不诊断）
  final bmiValue = f.bmiValue;
  if (bmiValue != null && bmiValue < 18.5) {
    out.add(Insight(
      code: 'bmi_low',
      severity: 'warn',
      text: 'BMI ${bmiValue.toStringAsFixed(1)}，已偏低，减脂缺口默认关闭。',
      evidence: {'bmi': double.parse(bmiValue.toStringAsFixed(1))},
    ));
  }

  // 9. 连续记录
  if (f.streakDays >= 7) {
    out.add(Insight(
      code: 'streak',
      severity: 'info',
      text: '已连续记录 ${f.streakDays} 天。数据越完整，缺口和趋势越可信。',
      evidence: {'streak': f.streakDays},
    ));
  }

  out.sort((a, b) => (_severityRank[a.severity] ?? 9)
      .compareTo(_severityRank[b.severity] ?? 9));
  return out;
}

/// 首屏一句话结论（取最高优先级那条）。
String headline(List<Insight> insights, HealthFacts f) {
  if (insights.isEmpty) {
    return f.todayItemCount == 0 ? '先记一条今天的体重或饮食' : '今天的数据都很正常';
  }
  return insights.first.text;
}
