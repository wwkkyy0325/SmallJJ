import 'package:flutter/foundation.dart';

/// 体重记录时段。早/晚是两次固定锚点，其余都归到「任意」，
/// 同一天同一时段只保留一条（写入用 upsert 覆盖）。
enum WeightSlot {
  morning('morning', '早上'),
  evening('evening', '晚上'),
  other('other', '任意');

  const WeightSlot(this.id, this.label);

  final String id;
  final String label;

  static WeightSlot fromId(String id) => WeightSlot.values.firstWhere(
        (slot) => slot.id == id,
        orElse: () => WeightSlot.other,
      );
}

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

@immutable
class Profile {
  const Profile({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.activityLevel,
    required this.goalMode,
    required this.goalRateKgWeek,
    this.goalWeightKg,
    this.periodTracking = false,
    this.aiNarration = true,
  });

  /// 'female' / 'male'，只用于 BMR 公式
  final String sex;
  final int birthYear;
  final double heightCm;

  /// sedentary / light / moderate / active
  final String activityLevel;

  /// lose / maintain / gain
  final String goalMode;
  final double goalRateKgWeek;
  final double? goalWeightKg;
  final bool periodTracking;
  final bool aiNarration;

  bool get isFemale => sex == 'female';

  Profile copyWith({
    String? sex,
    int? birthYear,
    double? heightCm,
    String? activityLevel,
    String? goalMode,
    double? goalRateKgWeek,
    double? goalWeightKg,
    bool? periodTracking,
    bool? aiNarration,
  }) {
    return Profile(
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      goalMode: goalMode ?? this.goalMode,
      goalRateKgWeek: goalRateKgWeek ?? this.goalRateKgWeek,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      periodTracking: periodTracking ?? this.periodTracking,
      aiNarration: aiNarration ?? this.aiNarration,
    );
  }
}

@immutable
class WeightEntry {
  const WeightEntry({
    required this.localDate,
    required this.measuredAt,
    required this.slot,
    required this.weightKg,
    this.bodyFatPct,
  });

  /// 'YYYY-MM-DD'，设备本地日期
  final String localDate;
  final int measuredAt;
  final WeightSlot slot;
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
    this.morningKg,
    this.eveningKg,
  });

  final String localDate;
  final double kg;
  final double? morningKg;
  final double? eveningKg;
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

/// 每日预算快照。落库后在同一天内保持稳定，历史和「今天」不会因为
/// 算法或新补录的数据而改写当天的结论。
@immutable
class DayTarget {
  const DayTarget({
    required this.localDate,
    required this.bmr,
    required this.tdee,
    required this.intakeBudget,
    required this.deficitKcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.algoVersion,
    this.note,
  });

  final String localDate;
  final double bmr;
  final double tdee;
  final double intakeBudget;
  final double deficitKcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String algoVersion;
  final String? note;

  double get intakeCap => intakeBudget;
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
