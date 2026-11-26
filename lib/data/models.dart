import 'package:flutter/foundation.dart';

enum MealSlot {
  breakfast('breakfast', '早餐'),
  lunch('lunch', '午餐'),
  dinner('dinner', '晚餐'),
  snack('snack', '加餐');

  const MealSlot(this.id, this.label);

  final String id;
  final String label;

  static MealSlot fromId(String id) => MealSlot.values.firstWhere(
        (slot) => slot.id == id,
        orElse: () => MealSlot.snack,
      );
}

/// 身体资料。**没有性别字段**：这个应用只服务女性，BMR 固定用 Mifflin-St Jeor
/// 的女式，问一句「男/女」只会多一次点击、多一个可能填错的字段。
///
/// 也**没有目标字段**：不问减脂/增重，不问目标体重和每周速率。这个应用只做
/// 测量和统计——今天吃了多少、消耗大约多少，不加计划值去评判。
@immutable
class Profile {
  const Profile({
    required this.birthYear,
    required this.heightCm,
    required this.activityLevel,
    this.periodTracking = true,
    this.aiNarration = true,
  });

  final int birthYear;
  final double heightCm;

  /// sedentary / light / moderate / active
  final String activityLevel;

  final bool periodTracking;
  final bool aiNarration;

  Profile copyWith({
    int? birthYear,
    double? heightCm,
    String? activityLevel,
    bool? periodTracking,
    bool? aiNarration,
  }) {
    return Profile(
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      periodTracking: periodTracking ?? this.periodTracking,
      aiNarration: aiNarration ?? this.aiNarration,
    );
  }
}

@immutable
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.localDate,
    required this.measuredAt,
    required this.weightKg,
    this.bodyFatPct,
  });

  final int id;

  /// 'YYYY-MM-DD'，设备本地日期，由 [measuredAt] 推出（不再单独指定）
  final String localDate;
  final int measuredAt;
  final double weightKg;
  final double? bodyFatPct;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(measuredAt);
}

/// 一天一条：同一天的多次称重取均值，作为趋势的输入。
@immutable
class DailyWeight {
  const DailyWeight({
    required this.localDate,
    required this.kg,
    required this.entries,
  });

  final String localDate;
  final double kg;
  final List<WeightEntry> entries;

  DateTime get date => DateTime.parse(localDate);
}

@immutable
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    this.alias,
    this.pinyin,
    this.defaultPortionG = 100,
    this.portionLabel = '份',
    this.isCustom = false,
  });

  final int id;
  final String name;
  final String? alias;
  final String? pinyin;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double defaultPortionG;
  final String portionLabel;
  final bool isCustom;
}

@immutable
class LoggedFood {
  const LoggedFood({
    required this.foodName,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.id = 0,
    this.foodId = 0,
    this.mealId = 0,
  });

  final int id;
  final int foodId;
  final int mealId;
  final String foodName;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
}

@immutable
class MealSection {
  const MealSection({required this.slot, required this.items});

  final MealSlot slot;
  final List<LoggedFood> items;

  double get kcal => items.fold(0.0, (sum, item) => sum + item.kcal);
  double get proteinG => items.fold(0.0, (sum, item) => sum + item.proteinG);
}

/// 当天的估算快照。落库后在同一天内保持稳定，历史和「今天」不会因为算法或
/// 新补录的数据而改写当天的结论。
///
/// 只有实测口径：BMR、估算消耗、三餐参考克数。没有预算、缺口这类计划值。
@immutable
class DayTarget {
  const DayTarget({
    required this.localDate,
    required this.bmr,
    required this.tdee,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.algoVersion,
  });

  final String localDate;
  final double bmr;
  final double tdee;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String algoVersion;

  /// 今日消耗是用「能量平衡反解」校正过的（不只是公式）。
  ///
  /// 记在 [algoVersion] 里而不是加一列：老库里的 `v1` 天然就是「没校正」。
  ///
  /// 界面不显示它：同一张卡上「每日消耗」只是一个数字，讲清来源反而更难懂。
  bool get tdeeAdaptive => algoVersion.contains('adaptive');
}

@immutable
class Insight {
  const Insight({
    required this.code,
    required this.severity,
    required this.text,
    this.evidence = const {},
  });

  /// 规则码，用于同日去重
  final String code;

  /// info / warn / action
  final String severity;
  final String text;
  final Map<String, Object?> evidence;
}
