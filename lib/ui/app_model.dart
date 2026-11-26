import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../domain/analysis.dart';
import '../domain/cycle.dart';
import '../domain/weight_trend.dart';

/// 界面的唯一数据源：所有页面读它、改完数据后 reload()。
/// 数据库操作是同步的（本地 SQLite，毫秒级），不需要异步加载态。
class AppModel extends ChangeNotifier {
  AppModel(this.repo) {
    reload();
  }

  final HealthRepository repo;

  Profile? profile;
  HealthFacts? facts;
  DayTarget? target;
  List<Insight> insights = const [];
  List<MealSection> meals = const [];
  List<TrendPoint> trend = const [];
  List<WeightEntry> entries = const [];
  CycleStats cycle = const CycleStats(cycleLengths: []);
  Map<String, int> counts = const {};

  String get todayKey => repo.todayKey;
  DateTime get now => repo.now;
  bool get onboarded => profile != null;

  void reload() {
    profile = repo.profile();
    if (profile == null) {
      notifyListeners();
      return;
    }
    final key = repo.todayKey;
    target = repo.targetFor(key);
    facts = repo.factsFor();
    insights = repo.insights();
    meals = repo.mealsFor(key);
    trend = repo.trendPoints();
    entries = repo.weightEntries(limit: 60);
    cycle = repo.cycleStats();
    counts = repo.tableCounts();
    notifyListeners();
  }

  void completeOnboarding({
    required Profile draft,
    required double weightKg,
  }) {
    repo.saveProfile(draft);
    repo.saveWeight(at: now, weightKg: weightKg);
    reload();
  }

  void saveProfile(Profile p) {
    repo.saveProfile(p);
    // 资料变了，今天的预算要跟着变；历史快照不动。
    repo.targetFor(todayKey, recompute: true);
    reload();
  }

  int saveWeight({
    required DateTime at,
    required double kg,
    int? id,
    double? bodyFat,
  }) {
    final saved = repo.saveWeight(
      at: at,
      weightKg: kg,
      bodyFatPct: bodyFat,
      id: id,
    );
    // 体重变了，当天的预算要跟着重算（历史快照不动）。
    repo.targetFor(repoDateKey(at), recompute: true);
    reload();
    return saved;
  }

  void deleteWeight(int id) {
    repo.deleteWeight(id);
    reload();
  }

  void addFood(MealSlot slot, FoodItem food, double grams) {
    repo.addMealItem(
      localDate: todayKey,
      slot: slot,
      food: food,
      grams: grams,
    );
    reload();
  }

  void removeFood(int mealItemId) {
    repo.removeMealItem(mealItemId);
    reload();
  }

  void addCycleStart(String localDate) {
    repo.addCycleStart(localDate);
    reload();
  }

  void removeCycleEvent(int id) {
    repo.removeCycleEvent(id);
    reload();
  }

  /// 调试用：一次塞入 21 天体重、今天的几餐、最近 3 个周期。
  /// 只在 debug 构建里可见（见 profile_page）。
  void seedDemoData() {
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 20; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final morning = 61.2 - (20 - i) * 0.06;
      repo.saveWeight(
        at: day.add(const Duration(hours: 7, minutes: 40)),
        weightKg: double.parse(morning.toStringAsFixed(1)),
      );
      if (i % 3 == 0) {
        repo.saveWeight(
          at: day.add(const Duration(hours: 21, minutes: 10)),
          weightKg: double.parse((morning + 0.7).toStringAsFixed(1)),
        );
      }
    }
    final eggs = repo.searchFoods('鸡蛋').first;
    final milk = repo.searchFoods('牛奶').first;
    final rice = repo.searchFoods('米饭').first;
    repo.addMealItem(
      localDate: todayKey,
      slot: MealSlot.breakfast,
      food: eggs,
      grams: 100,
    );
    repo.addMealItem(
      localDate: todayKey,
      slot: MealSlot.breakfast,
      food: milk,
      grams: 250,
    );
    repo.addMealItem(
      localDate: todayKey,
      slot: MealSlot.lunch,
      food: rice,
      grams: 150,
    );
    repo.addCycleStart(repoDateKey(today.subtract(const Duration(days: 84))));
    repo.addCycleStart(repoDateKey(today.subtract(const Duration(days: 56))));
    repo.addCycleStart(repoDateKey(today.subtract(const Duration(days: 28))));
    reload();
  }
}

String repoDateKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';
