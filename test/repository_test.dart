import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';

HealthRepository buildRepo({DateTime? at}) {
  final db = openTestDatabase();
  final repo = HealthRepository(db, clock: () => at ?? DateTime(2026, 1, 15, 15));
  repo.saveProfile(const Profile(
    birthYear: 1996,
    heightCm: 165,
    activityLevel: 'light',
  ));
  return repo;
}

void main() {
  test('种子食物入库，中文名能搜到', () {
    final repo = buildRepo();
    final results = repo.searchFoods('米饭');
    expect(results, isNotEmpty);
    expect(results.first.name, '米饭');
    expect(repo.searchFoods('jidan').first.name, '鸡蛋');
    expect(repo.searchFoods('西红柿').first.name, '番茄');
  });

  test('资料表没有性别列：v3 迁移把旧库里的 sex 拆掉了', () {
    final db = openTestDatabase();
    final columns =
        db.select('PRAGMA table_info(profile)').map((r) => r['name']).toList();
    expect(columns, isNot(contains('sex')));
    // 其余列原样保留，经期开关默认开
    expect(columns, containsAll(['birth_year', 'height_cm', 'period_tracking']));
  });

  test('同一分钟再记是两条，改的只有带上 id 那条', () {
    final repo = buildRepo();
    final id = repo.saveWeight(
      at: DateTime(2026, 1, 15, 8, 30),
      weightKg: 60.2,
    );
    repo.saveWeight(at: DateTime(2026, 1, 15, 8, 30), weightKg: 60.4);
    expect(repo.weightEntries().length, 2);
    // 改已有那条：时间也跟着改
    repo.saveWeight(
      at: DateTime(2026, 1, 15, 9, 5),
      weightKg: 60.6,
      id: id,
    );
    expect(repo.weightEntries().length, 2);
    final edited = repo
        .weightEntriesOn('2026-01-15')
        .firstWhere((entry) => entry.id == id);
    expect(edited.id, id);
    expect(edited.weightKg, 60.6);
    expect(edited.date.hour, 9);
  });

  test('落库的体重统一成两位小数', () {
    final repo = buildRepo();
    repo.saveWeight(at: DateTime(2026, 1, 15, 8), weightKg: 60.427);
    repo.saveWeight(
      at: DateTime(2026, 1, 15, 21),
      weightKg: 70 - 3 * 0.1, // 69.70000000000002
    );
    final day = repo.weightEntriesOn('2026-01-15');
    expect(day.first.weightKg, 60.43);
    expect(day.last.weightKg, 69.7);
  });

  test('同一天记两次，日值取均值', () {
    final repo = buildRepo();
    repo.saveWeight(at: DateTime(2026, 1, 15, 8), weightKg: 60.0);
    repo.saveWeight(at: DateTime(2026, 1, 15, 21), weightKg: 61.0);
    final daily = repo.dailyWeights();
    expect(daily.single.kg, closeTo(60.5, 0.001));
    expect(daily.single.entries.length, 2);
  });

  test('记录食物：热量 = 每 100 g × 克数，落库后不再变', () {
    final repo = buildRepo();
    final rice = repo.searchFoods('米饭').first;
    repo.addMealItem(
      localDate: '2026-01-15',
      slot: MealSlot.lunch,
      food: rice,
      grams: 150,
    );
    expect(repo.intakeForDate('2026-01-15'), closeTo(174, 0.5));
    final sections = repo.mealsFor('2026-01-15');
    expect(sections.length, 4);
    expect(sections.firstWhere((s) => s.slot == MealSlot.lunch).items.length, 1);
  });

  test('删除一条食物后当日热量回落', () {
    final repo = buildRepo();
    final egg = repo.searchFoods('鸡蛋').first;
    final logged = repo.addMealItem(
      localDate: '2026-01-15',
      slot: MealSlot.breakfast,
      food: egg,
      grams: 50,
    );
    expect(repo.intakeForDate('2026-01-15'), greaterThan(0));
    repo.removeMealItem(logged.id);
    expect(repo.intakeForDate('2026-01-15'), 0);
  });

  test('当日估算落库后不再被改资料改写', () {
    final repo = buildRepo();
    repo.saveWeight(at: DateTime(2026, 1, 15, 8), weightKg: 60);
    final before = repo.targetFor('2026-01-15');
    repo.saveProfile(const Profile(
      birthYear: 1996,
      heightCm: 165,
      activityLevel: 'moderate',
    ));
    final after = repo.targetFor('2026-01-15');
    expect(after.tdee, before.tdee);
    expect(after.proteinG, before.proteinG);
    // 明确要求重算时才变
    final recomputed = repo.targetFor('2026-01-15', recompute: true);
    expect(recomputed.tdee, greaterThan(before.tdee));
  });

  test('经期开始日去重并给出周期统计', () {
    final repo = buildRepo();
    repo.addCycleStart('2025-12-01');
    repo.addCycleStart('2025-12-29');
    repo.addCycleStart('2026-01-26');
    repo.addCycleStart('2026-01-26');
    final stats = repo.cycleStats();
    expect(repo.cycleStarts().length, 3);
    expect(stats.cycleLengths, [28, 28]);
    expect(stats.nextStart, DateTime(2026, 2, 23));
  });

  test('空数据时给出「今天还没记录饮食」的行动项', () {
    final repo = buildRepo();
    final insights = repo.insights();
    expect(insights.first.severity, 'action');
    expect(insights.first.code, 'intake_empty');
  });

  test('吃得比估算消耗多时给中性提示并带证据数字', () {
    final repo = buildRepo();
    repo.saveWeight(at: DateTime(2026, 1, 15, 8), weightKg: 60);
    final target = repo.targetFor('2026-01-15');
    final cake = repo.searchFoods('奶油蛋糕').first;
    // 用足量把热量顶过估算消耗
    final grams = (target.tdee + 200) / cake.kcalPer100g * 100;
    repo.addMealItem(
      localDate: '2026-01-15',
      slot: MealSlot.dinner,
      food: cake,
      grams: grams,
    );
    final insights = repo.insights();
    final over = insights.where((i) => i.code == 'intake_over');
    expect(over, isNotEmpty);
    // 口径是「吃的 vs 估算消耗」，不再是「吃的 vs 预算」
    expect(over.first.severity, 'info');
    expect(over.first.evidence['tdee'], isA<int>());
    expect(over.first.evidence['intake'], isA<int>());
  });

  test('7 天有体重但摄入缺失时不给自适应 TDEE', () {
    final repo = buildRepo();
    for (var i = 0; i < 14; i++) {
      repo.saveWeight(
        at: DateTime(2026, 1, i + 1, 8),
        weightKg: 70 - i * 0.1,
      );
    }
    expect(repo.adaptiveTdee(asOf: '2026-01-15'), isNull);
  });

  test('数据量统计与 JSON 导出可用', () {
    final repo = buildRepo();
    repo.saveWeight(at: DateTime(2026, 1, 15, 8), weightKg: 60);
    final counts = repo.tableCounts();
    expect(counts['weight_entry'], 1);
    expect(counts['food_item'], greaterThan(50));
    expect(repo.exportJsonString(), contains('weight_entry'));
  });
}
