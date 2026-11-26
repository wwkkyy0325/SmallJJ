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
      text: '今天还没有饮食记录。记一条，消耗对比才算得出来。',
    ));
  }

  // 2. 今天吃得比估算消耗多
  if (f.todayItemCount > 0 && f.todayIntake > f.tdee + 50) {
    final over = f.todayIntake - f.tdee;
    out.add(Insight(
      code: 'intake_over',
      severity: 'info',
      text: '今天吃的比估算消耗多 ${over.round()} kcal。单日波动说明不了什么，'
          '看一周的平均更准。',
      evidence: {'intake': f.todayIntake.round(), 'tdee': f.tdee.round()},
    ));
  }

  // 3. 摄入偏低：只在夜里说，而且只说数——白天没记全不是「吃得少」
  if (f.todayItemCount > 0 &&
      f.todayIntake < intakeFloorFemale &&
      f.today.hour >= 20) {
    out.add(Insight(
      code: 'intake_too_low',
      severity: 'info',
      text: '今天一共记到 ${f.todayIntake.round()} kcal，偏少。'
          '如果确实吃这么多，长期下来容易掉肌肉、代谢下降；'
          '如果只是没记全，补上当天更准。',
      evidence: {'intake': f.todayIntake.round()},
    ));
  }

  // 4. 一周变化幅度过大（只陈述，比对的是「常见幅度」而不是目标）
  final rate = f.weightTrendKgPerWeek;
  if (rate != null && rate.abs() > 1.0) {
    out.add(Insight(
      code: 'rate_extreme',
      severity: 'info',
      text: '一周变化 ${rate.toStringAsFixed(2)} kg，偏大。'
          '多数是水分和糖原，看四周的趋势更准。',
      evidence: {'rate': rate},
    ));
  }

  // 5. 蛋白偏低（和按体重给的参考量比，不是必须达到的目标）
  if (f.intakeLoggedDays7 >= 3 && f.proteinAvg7d > 0) {
    final ratio = f.proteinAvg7d / f.proteinTargetG;
    if (ratio < 0.8) {
      out.add(Insight(
        code: 'protein_low',
        severity: 'info',
        text: '近 7 天蛋白平均 ${f.proteinAvg7d.round()} g，按体重约 '
            '${f.proteinTargetG.round()} g 是常见参考量。',
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
      text: 'BMI ${bmiValue.toStringAsFixed(1)}，偏低。',
      evidence: {'bmi': double.parse(bmiValue.toStringAsFixed(1))},
    ));
  }

  // 9. 连续记录
  if (f.streakDays >= 7) {
    out.add(Insight(
      code: 'streak',
      severity: 'info',
      text: '已连续记录 ${f.streakDays} 天。数据越完整，估算越准。',
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
