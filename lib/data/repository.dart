import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../domain/analysis.dart';
import '../domain/cycle.dart';
import '../domain/energy.dart';
import '../domain/weight_trend.dart';
import '../domain/weight_input.dart';
import 'models.dart';

/// 唯一的数据入口。页面只调这里的方法，不写 SQL、不自己算能量。
class HealthRepository {
  HealthRepository(this.db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Database db;
  final DateTime Function() _clock;

  DateTime get now => _clock();
  String get todayKey => dateKey(now);

  // ── profile ────────────────────────────────────────────────────────────
  Profile? profile() {
    final rows = db.select('SELECT * FROM profile WHERE id = 1');
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Profile(
      birthYear: r['birth_year'] as int,
      heightCm: (r['height_cm'] as num).toDouble(),
      activityLevel: r['activity_level'] as String,
      goalMode: r['goal_mode'] as String,
      goalRateKgWeek: (r['goal_rate_kg_week'] as num).toDouble(),
      goalWeightKg: (r['goal_weight_kg'] as num?)?.toDouble(),
      periodTracking: (r['period_tracking'] as int) == 1,
      aiNarration: (r['ai_narration'] as int) == 1,
    );
  }

  void saveProfile(Profile p) {
    db.execute(
      'INSERT INTO profile (id, birth_year, height_cm, activity_level, '
      'goal_mode, goal_weight_kg, goal_rate_kg_week, period_tracking, '
      'ai_narration, updated_at) '
      'VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'birth_year=excluded.birth_year, height_cm=excluded.height_cm, '
      'activity_level=excluded.activity_level, goal_mode=excluded.goal_mode, '
      'goal_weight_kg=excluded.goal_weight_kg, '
      'goal_rate_kg_week=excluded.goal_rate_kg_week, '
      'period_tracking=excluded.period_tracking, '
      'ai_narration=excluded.ai_narration, updated_at=excluded.updated_at',
      [
        p.birthYear,
        p.heightCm,
        p.activityLevel,
        p.goalMode,
        p.goalWeightKg,
        p.goalRateKgWeek,
        p.periodTracking ? 1 : 0,
        p.aiNarration ? 1 : 0,
        now.millisecondsSinceEpoch,
      ],
    );
  }

  // ── 体重 ───────────────────────────────────────────────────────────────
  /// 记一次体重：只认「什么时候称的 + 多少 kg」。
  ///
  /// 传 [id] 表示改已有那条，否则新增一条。`local_date` 由称重时间推出，
  /// 不再由调用方指定，避免「时间改了、日期没改」这种账。
  /// 落库的值统一成两位小数，后面的均值/趋势不会带着浮点尾巴。
  int saveWeight({
    required DateTime at,
    required double weightKg,
    double? bodyFatPct,
    int? id,
    String? note,
  }) {
    final ts = at.millisecondsSinceEpoch;
    final kg = normalizeKg(weightKg);
    final localDate = dateKey(at);
    if (id != null) {
      db.execute(
        'UPDATE weight_entry SET local_date = ?, measured_at = ?, '
        'weight_kg = ?, body_fat_pct = ?, note = ?, updated_at = ? '
        'WHERE id = ?',
        [localDate, ts, kg, bodyFatPct, note, now.millisecondsSinceEpoch, id],
      );
      return id;
    }
    db.execute(
      'INSERT INTO weight_entry (local_date, measured_at, weight_kg, '
      'body_fat_pct, note, created_at, updated_at) VALUES (?,?,?,?,?,?,?)',
      [localDate, ts, kg, bodyFatPct, note, ts, ts],
    );
    return db.lastInsertRowId;
  }

  void deleteWeight(int id) {
    db.execute('DELETE FROM weight_entry WHERE id = ?', [id]);
  }

  WeightEntry _mapWeight(Row r) => WeightEntry(
        id: r['id'] as int,
        localDate: r['local_date'] as String,
        measuredAt: r['measured_at'] as int,
        weightKg: (r['weight_kg'] as num).toDouble(),
        bodyFatPct: (r['body_fat_pct'] as num?)?.toDouble(),
      );

  /// 某一天的全部记录，按时间正序。
  List<WeightEntry> weightEntriesOn(String localDate) {
    final rows = db.select(
      'SELECT * FROM weight_entry WHERE local_date = ? ORDER BY measured_at',
      [localDate],
    );
    return [for (final row in rows) _mapWeight(row)];
  }

  /// 按时间倒序的全部原始记录。
  List<WeightEntry> weightEntries({int limit = 200}) {
    final rows = db.select(
      'SELECT * FROM weight_entry ORDER BY measured_at DESC LIMIT ?',
      [limit],
    );
    return rows.map(_mapWeight).toList();
  }

  /// 一天一条（同一天多次取均值），正序，给趋势/图表用。
  List<DailyWeight> dailyWeights({int days = 180}) {
    final from = dateKey(dateOnly(now).subtract(Duration(days: days)));
    final rows = db.select(
      'SELECT * FROM weight_entry WHERE local_date >= ? '
      'ORDER BY local_date, measured_at',
      [from],
    );
    final grouped = <String, List<WeightEntry>>{};
    for (final row in rows) {
      final entry = _mapWeight(row);
      grouped.putIfAbsent(entry.localDate, () => []).add(entry);
    }
    final keys = grouped.keys.toList()..sort();
    return [
      for (final key in keys)
        DailyWeight(
          localDate: key,
          kg: grouped[key]!.fold(0.0, (s, e) => s + e.weightKg) /
              grouped[key]!.length,
          entries: grouped[key]!,
        ),
    ];
  }

  double? weightOnOrBefore(String localDate) {
    final rows = db.select(
      'SELECT weight_kg FROM weight_entry WHERE local_date <= ? '
      'ORDER BY local_date DESC, measured_at DESC LIMIT 1',
      [localDate],
    );
    if (rows.isEmpty) return null;
    return (rows.first['weight_kg'] as num).toDouble();
  }

  double? latestWeightKg() => weightOnOrBefore(todayKey);

  int daysSinceWeightLog() {
    final rows = db.select(
      'SELECT local_date FROM weight_entry ORDER BY local_date DESC LIMIT 1',
    );
    if (rows.isEmpty) return 999;
    return daysBetween(DateTime.parse(rows.first['local_date'] as String), now);
  }

  // ── 食物库 ─────────────────────────────────────────────────────────────
  List<FoodItem> searchFoods(String query, {int limit = 30}) {
    final q = query.trim();
    if (q.isEmpty) {
      final rows = db.select(
        'SELECT f.*, COUNT(mi.id) AS used FROM food_item f '
        'LEFT JOIN meal_item mi ON mi.food_id = f.id '
        'GROUP BY f.id ORDER BY used DESC, f.is_custom DESC, f.name LIMIT ?',
        [limit],
      );
      return rows.map(_mapFood).toList();
    }
    final like = '%${q.replaceAll('%', '').replaceAll('_', '')}%';
    final rows = db.select(
      'SELECT * FROM food_item WHERE name = ? OR name LIKE ? OR '
      'IFNULL(alias, \'\') LIKE ? OR IFNULL(pinyin, \'\') LIKE ? '
      'ORDER BY (name = ?) DESC, is_custom DESC, LENGTH(name), name LIMIT ?',
      [q, like, like, like, q, limit],
    );
    return rows.map(_mapFood).toList();
  }

  FoodItem? foodById(int id) {
    final rows = db.select('SELECT * FROM food_item WHERE id = ?', [id]);
    return rows.isEmpty ? null : _mapFood(rows.first);
  }

  FoodItem _mapFood(Row r) => FoodItem(
        id: r['id'] as int,
        name: r['name'] as String,
        alias: r['alias'] as String?,
        pinyin: r['pinyin'] as String?,
        kcalPer100g: (r['kcal_per_100g'] as num).toDouble(),
        proteinPer100g: (r['protein_per_100g'] as num).toDouble(),
        carbPer100g: (r['carb_per_100g'] as num).toDouble(),
        fatPer100g: (r['fat_per_100g'] as num).toDouble(),
        defaultPortionG: (r['default_portion_g'] as num).toDouble(),
        portionLabel: r['portion_label'] as String,
        isCustom: (r['is_custom'] as int) == 1,
      );

  /// 用户自建条目：食物库不准时这是唯一的纠错途径。
  int addCustomFood({
    required String name,
    required double kcalPer100g,
    double proteinPer100g = 0,
    double carbPer100g = 0,
    double fatPer100g = 0,
    double defaultPortionG = 100,
    String portionLabel = '份',
  }) {
    db.execute(
      'INSERT INTO food_item (name, alias, pinyin, kcal_per_100g, '
      'protein_per_100g, carb_per_100g, fat_per_100g, default_portion_g, '
      'portion_label, is_custom, created_at) VALUES (?,?,?,?,?,?,?,?,?,1,?)',
      [
        name,
        null,
        null,
        kcalPer100g,
        proteinPer100g,
        carbPer100g,
        fatPer100g,
        defaultPortionG,
        portionLabel,
        now.millisecondsSinceEpoch,
      ],
    );
    return db.lastInsertRowId;
  }

  // ── 饮食 ───────────────────────────────────────────────────────────────
  int _ensureMeal(String localDate, MealSlot slot) {
    db.execute(
      'INSERT OR IGNORE INTO meal_entry (local_date, meal, created_at) '
      'VALUES (?,?,?)',
      [localDate, slot.id, now.millisecondsSinceEpoch],
    );
    return db.select(
      'SELECT id FROM meal_entry WHERE local_date = ? AND meal = ?',
      [localDate, slot.id],
    ).first['id'] as int;
  }

 /// 记录一条食物：热量按「每 100 g × 克数」当场算好并落库，
  /// 以后食物库数值改了也不会篡改历史。
  LoggedFood addMealItem({
    required String localDate,
    required MealSlot slot,
    required FoodItem food,
    required double grams,
  }) {
    final mealId = _ensureMeal(localDate, slot);
    final ratio = grams / 100;
    final kcal = food.kcalPer100g * ratio;
    final protein = food.proteinPer100g * ratio;
    final carb = food.carbPer100g * ratio;
    final fat = food.fatPer100g * ratio;
    db.execute(
      'INSERT INTO meal_item (meal_id, food_id, food_name, grams, kcal, '
      'protein_g, carb_g, fat_g, created_at) VALUES (?,?,?,?,?,?,?,?,?)',
      [
        mealId,
        food.id,
        food.name,
        grams,
        kcal,
        protein,
        carb,
        fat,
        now.millisecondsSinceEpoch,
      ],
    );
    return LoggedFood(
      id: db.lastInsertRowId,
      foodId: food.id,
      mealId: mealId,
      foodName: food.name,
      grams: grams,
      kcal: kcal,
      proteinG: protein,
      carbG: carb,
      fatG: fat,
    );
  }

  void removeMealItem(int id) {
    db.execute('DELETE FROM meal_item WHERE id = ?', [id]);
  }

  List<MealSection> mealsFor(String localDate) {
    final rows = db.select(
      'SELECT mi.* FROM meal_item mi JOIN meal_entry me ON me.id = mi.meal_id '
      'WHERE me.local_date = ? ORDER BY mi.id',
      [localDate],
    );
    final byMeal = <MealSlot, List<LoggedFood>>{};
    for (final r in rows) {
      final mealId = r['meal_id'] as int;
      final meal = db.select(
        'SELECT meal FROM meal_entry WHERE id = ?',
        [mealId],
      ).first['meal'] as String;
      final slot = MealSlot.fromId(meal);
      byMeal.putIfAbsent(slot, () => []).add(
            LoggedFood(
              id: r['id'] as int,
              foodId: r['food_id'] as int,
              mealId: mealId,
              foodName: r['food_name'] as String,
              grams: (r['grams'] as num).toDouble(),
              kcal: (r['kcal'] as num).toDouble(),
              proteinG: (r['protein_g'] as num).toDouble(),
              carbG: (r['carb_g'] as num).toDouble(),
              fatG: (r['fat_g'] as num).toDouble(),
            ),
          );
    }
    return [
      for (final slot in MealSlot.values)
        MealSection(slot: slot, items: byMeal[slot] ?? const []),
    ];
  }

  double intakeForDate(String localDate) {
    final rows = db.select(
      'SELECT COALESCE(SUM(mi.kcal), 0) AS kcal FROM meal_item mi '
      'JOIN meal_entry me ON me.id = mi.meal_id WHERE me.local_date = ?',
      [localDate],
    );
    return (rows.first['kcal'] as num).toDouble();
  }

  double proteinForDate(String localDate) {
    final rows = db.select(
      'SELECT COALESCE(SUM(mi.protein_g), 0) AS p FROM meal_item mi '
      'JOIN meal_entry me ON me.id = mi.meal_id WHERE me.local_date = ?',
      [localDate],
    );
    return (rows.first['p'] as num).toDouble();
  }

  int itemCountForDate(String localDate) {
    final rows = db.select(
      'SELECT COUNT(*) AS c FROM meal_item mi '
      'JOIN meal_entry me ON me.id = mi.meal_id WHERE me.local_date = ?',
      [localDate],
    );
    return rows.first['c'] as int;
  }

  // ── 每日预算 ───────────────────────────────────────────────────────────
  DayTarget? storedTarget(String localDate) {
    final rows =
        db.select('SELECT * FROM day_target WHERE local_date = ?', [localDate]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return DayTarget(
      localDate: r['local_date'] as String,
      bmr: (r['bmr'] as num).toDouble(),
      tdee: (r['tdee'] as num).toDouble(),
      intakeBudget: (r['intake_budget'] as num).toDouble(),
      deficitKcal: (r['deficit_kcal'] as num).toDouble(),
      proteinG: (r['protein_g'] as num).toDouble(),
      carbG: (r['carb_g'] as num).toDouble(),
      fatG: (r['fat_g'] as num).toDouble(),
      algoVersion: r['algo_version'] as String,
      note: r['note'] as String?,
    );
  }

  /// 当天预算只算一次并落库。历史页面因此不会被新算法改写。
  DayTarget targetFor(String localDate, {bool recompute = false}) {
    if (!recompute) {
      final stored = storedTarget(localDate);
      if (stored != null) return stored;
    }
    final p = profile();
    if (p == null) {
      throw StateError('还没有用户资料，先完成引导');
    }
    final weight = weightOnOrBefore(localDate) ?? p.goalWeightKg ?? 60;
    final plan = planEnergy(
      profile: p,
      weightKg: weight,
      year: DateTime.parse(localDate).year,
      adaptiveTdee: adaptiveTdee(asOf: localDate),
    );
    final target = DayTarget(
      localDate: localDate,
      bmr: plan.bmr,
      tdee: plan.tdee,
      intakeBudget: plan.intakeBudget,
      deficitKcal: plan.deficitKcal,
      proteinG: plan.proteinG,
      carbG: plan.carbG,
      fatG: plan.fatG,
      algoVersion: 'v1',
      note: plan.note.isEmpty ? null : plan.note,
    );
    db.execute(
      'INSERT OR REPLACE INTO day_target (local_date, bmr, tdee, '
      'intake_budget, deficit_kcal, protein_g, carb_g, fat_g, algo_version, '
      'note, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
      [
        target.localDate,
        target.bmr,
        target.tdee,
        target.intakeBudget,
        target.deficitKcal,
        target.proteinG,
        target.carbG,
        target.fatG,
        target.algoVersion,
        target.note,
        now.millisecondsSinceEpoch,
      ],
    );
    return target;
  }

  /// 自适应 TDEE：数据不够就返回 null，界面继续显示公式值。
  double? adaptiveTdee({String? asOf}) {
    final p = profile();
    if (p == null) return null;
    final date = asOf ?? todayKey;
    final weights = dailyWeights(days: 40)
        .where((d) => d.localDate.compareTo(date) <= 0)
        .toList();
    final weight = weightOnOrBefore(date);
    if (weight == null || weights.length < 5) return null;
    final bmr = bmrFemale(
      weightKg: weight,
      heightCm: p.heightCm,
      ageYears: ageFromBirthYear(p.birthYear, year: DateTime.parse(date).year),
    );
    final formula = bmr * palFor(p.activityLevel);
    final previous = db.select(
      'SELECT tdee FROM day_target WHERE local_date < ? '
      'ORDER BY local_date DESC LIMIT 1',
      [date],
    );
    return adaptiveTdeeFromBalance(
      weights: weights,
      intakeForDate: intakeForDate,
      formulaTdee: formula,
      previousAdaptive:
          previous.isEmpty ? null : (previous.first['tdee'] as num).toDouble(),
    );
  }

  // ── 经期 ───────────────────────────────────────────────────────────────
  List<({int id, DateTime date})> cycleStarts() {
    final rows = db.select(
      "SELECT id, local_date FROM cycle_event WHERE kind = 'start' "
      'ORDER BY local_date',
    );
    return [
      for (final r in rows)
        (id: r['id'] as int, date: DateTime.parse(r['local_date'] as String)),
    ];
  }

  void addCycleStart(String localDate) {
    db.execute(
      "INSERT OR IGNORE INTO cycle_event (local_date, kind, created_at) "
      "VALUES (?, 'start', ?)",
      [localDate, now.millisecondsSinceEpoch],
    );
  }

  void removeCycleEvent(int id) {
    db.execute('DELETE FROM cycle_event WHERE id = ?', [id]);
  }

  CycleStats cycleStats() =>
      analyseCycles(cycleStarts().map((e) => e.date).toList());

  // ── 汇总 ───────────────────────────────────────────────────────────────
  List<DailyWeight> last30Days() => dailyWeights(days: 30);

  List<TrendPoint> trendPoints() => weightTrend(dailyWeights(days: 120));

  int _streakDays() {
    var streak = 0;
    var day = dateOnly(now);
    for (var i = 0; i < 400; i++) {
      final key = dateKey(day);
      final hasWeight = db
          .select('SELECT 1 FROM weight_entry WHERE local_date = ? LIMIT 1', [key])
          .isNotEmpty;
      final hasMeal = db
          .select('SELECT 1 FROM meal_entry WHERE local_date = ? LIMIT 1', [key])
          .isNotEmpty;
      if (!hasWeight && !hasMeal) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  HealthFacts factsFor([DateTime? at]) {
    final p = profile();
    if (p == null) {
      throw StateError('还没有用户资料，先完成引导');
    }
    final current = at ?? now;
    final key = dateKey(current);
    final target = targetFor(key);
    final weights = dailyWeights(days: 60);
    final trend = weightTrend(weights);
    final rate = trendRateKgPerWeek(trend);

    var proteinSum = 0.0;
    var intakeDays = 0;
    for (var i = 0; i < 7; i++) {
      final day = dateKey(dateOnly(current).subtract(Duration(days: i)));
      final count = itemCountForDate(day);
      if (count > 0) {
        intakeDays++;
        proteinSum += proteinForDate(day);
      }
    }

    final cycle = cycleStats();
    final daysUntil = cycle.daysUntilNext(current);
    return HealthFacts(
      today: current,
      profile: p,
      tdee: target.tdee,
      intakeBudget: target.intakeBudget,
      deficitKcal: target.deficitKcal,
      proteinTargetG: target.proteinG,
      todayIntake: intakeForDate(key),
      todayItemCount: itemCountForDate(key),
      proteinAvg7d: intakeDays == 0 ? 0 : proteinSum / intakeDays,
      intakeLoggedDays7: intakeDays,
      daysSinceWeightLog: daysSinceWeightLog(),
      currentWeightKg: latestWeightKg(),
      weightTrendKgPerWeek: rate,
      streakDays: _streakDays(),
      cycle: cycle,
      daysUntilPeriod: daysUntil,
      cycleDay: cycleDayOf(cycle, current),
      inPeriodWindow: cycle.inWindow(current),
    );
  }

  List<Insight> insights({DateTime? at}) => runAnalysis(factsFor(at));

  /// 给「我的」页做自检用的行数统计。
  Map<String, int> tableCounts() {
    int count(String table) =>
        db.select('SELECT COUNT(*) AS c FROM $table').first['c'] as int;
    return {
      'weight_entry': count('weight_entry'),
      'meal_item': count('meal_item'),
      'food_item': count('food_item'),
      'cycle_event': count('cycle_event'),
      'day_target': count('day_target'),
    };
  }

  Map<String, dynamic> exportJson() {
    Map<String, dynamic> rowsOf(String sql) => {'rows': db.select(sql).map((r) => r.values).toList()};
    return {
      'exported_at': now.toIso8601String(),
      'profile': rowsOf('SELECT * FROM profile'),
      'weight_entry': rowsOf('SELECT * FROM weight_entry'),
      'meal_entry': rowsOf('SELECT * FROM meal_entry'),
      'meal_item': rowsOf('SELECT * FROM meal_item'),
      'cycle_event': rowsOf('SELECT * FROM cycle_event'),
      'day_target': rowsOf('SELECT * FROM day_target'),
    };
  }

  String exportJsonString() => const JsonEncoder.withIndent('  ')
      .convert(exportJson());
}
