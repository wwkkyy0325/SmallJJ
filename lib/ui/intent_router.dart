import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/energy.dart';
import '../domain/food_parse.dart';
import '../platform/app_intents.dart';
import 'app_model.dart';
import 'format.dart';
import 'sheets.dart';

/// 把一条链接翻译成「对数据做的事」。
///
/// 设计原则：**链接里带了数值就直接落库**，不再弹表单、不用键盘；
/// 只有缺参数时才退回表单（此时已经帮用户选好时段/餐次）。
/// 每次写入都留一次撤销机会，语音识别错了不至于没法挽回。
class IntentRouter {
  IntentRouter({required this.model, required this.onTab});

  final AppModel model;

  /// 切换底部 Tab（0 今天 / 1 体重 / 2 饮食 / 3 我的）
  final void Function(int index) onTab;

  ({String label, VoidCallback run})? _undo;

  Future<void> handle(BuildContext context, SmalljjLink link) async {
    if (!model.onboarded) return;
    switch (link.type) {
      case 'weight':
        await _weight(context, link);
      case 'food':
        await _food(context, link);
      case 'period':
        await _period(context, link);
      case 'query':
        _query(context, link);
      case 'today':
        onTab(0);
      case 'undo':
        _undoNow(context);
    }
  }

  // ── 体重 ────────────────────────────────────────────────────────────────

  Future<void> _weight(BuildContext context, SmalljjLink link) async {
    final date = _dateOf(link.firstOf(['date', 'day', '日期'])) ?? model.todayKey;
    final slot = _slotOf(link.firstOf(['slot', 'when', '时段'])) ?? _guessSlot();
    final kg = _kgOf(link.firstOf(['kg', 'weight', 'value', 'w', '体重']));

    if (kg == null) {
      // 没给数值：打开弹层，时段已经选好，用户只补一个数字。
      onTab(0);
      await showWeightSheet(context, model, slot: slot, localDate: date);
      return;
    }
    if (kg < 25 || kg > 300) {
      _snack(context, '体重 ${kgLabel(kg)} kg 不在 25–300 之间，没有记录');
      AppIntents.speak('没有记录，体重数值不合理');
      return;
    }

    final previous = model.repo.weightOn(date, slot);
    model.saveWeight(slot: slot, kg: kg, localDate: date);
    _undo = (
      label: '体重 ${slot.label}',
      run: () {
        if (previous == null) {
          model.deleteWeight(date, slot);
        } else {
          model.saveWeight(
            slot: slot,
            kg: previous.weightKg,
            localDate: date,
          );
        }
      },
    );

    final dayLabel = date == model.todayKey ? '今天' : _monthDayOfKey(date);
    final change = previous == null
        ? ''
        : '（原 ${kgLabel(previous.weightKg)}）';
    onTab(0);
    _snack(context, '已记 $dayLabel${slot.label} ${kgLabel(kg)} kg$change', undo: true);
    AppIntents.speak('已记${slot.label}体重 ${kgLabel(kg)} 公斤');
  }

  // ── 饮食 ────────────────────────────────────────────────────────────────

  Future<void> _food(BuildContext context, SmalljjLink link) async {
    final meal = _mealOf(link.firstOf(['meal', 'slot', '餐'])) ?? _guessMeal();
    final text = link.firstOf(['text', 'q', 'food', '内容', 'what']);
    onTab(2);

    if (text == null) {
      await showFoodSheet(context, model, slot: meal);
      return;
    }

    final mentions = parseFoodText(text);
    final added = <LoggedFood>[];
    final missed = <String>[];
    for (final mention in mentions) {
      final food = _matchFood(mention.name);
      if (food == null) {
        missed.add(mention.name);
        continue;
      }
      final grams = mention
          .gramsWith(food.defaultPortionG)
          .clamp(1, 2000)
          .toDouble();
      added.add(
        model.repo.addMealItem(
          localDate: model.todayKey,
          slot: meal,
          food: food,
          grams: grams,
        ),
      );
    }

    if (added.isEmpty) {
      // 库里没有这些食物：把原话带进弹层，用户少打一遍字。
      await showFoodSheet(context, model, slot: meal, initialText: text);
      return;
    }

    model.reload();
    final kcal = added.fold<double>(0, (sum, item) => sum + item.kcal).round();
    _undo = (
      label: '${meal.label}饮食',
      run: () {
        for (final item in added) {
          model.repo.removeMealItem(item.id);
        }
        model.reload();
      },
    );
    final detail = added
        .map((item) => '${item.foodName} ${item.grams.round()}g')
        .join('、');
    final tail = missed.isEmpty ? '' : ' · 没认出来：${missed.join('、')}';
    _snack(
      context,
      '${meal.label} +${added.length} 项 $kcal kcal：$detail$tail',
      undo: true,
    );
    AppIntents.speak('已记${meal.label}${added.length}项，$kcal 千卡');
  }

  FoodItem? _matchFood(String raw) {
    final name = raw.replaceAll(RegExp(r'[和与及的了]'), '').trim();
    if (name.isEmpty) return null;
    final results = model.repo.searchFoods(name, limit: 20);
    if (results.isEmpty) return null;
    for (final food in results) {
      if (food.name == name) return food;
    }
    for (final food in results) {
      if (food.name.contains(name) || name.contains(food.name)) return food;
    }
    return results.first;
  }

  // ── 经期 ────────────────────────────────────────────────────────────────

  Future<void> _period(BuildContext context, SmalljjLink link) async {
    final action = (link.firstOf(['action', 'do']) ?? 'start').toLowerCase();
    if (action == 'status' || action == 'query' || action == '问') {
      _snack(context, _cycleSentence(), seconds: 7);
      AppIntents.speak(_cycleSentence());
      return;
    }
    final date = _dateOf(link.firstOf(['date', 'day', '日期'])) ?? model.todayKey;
    model.addCycleStart(date);
    final starts = model.repo.cycleStarts();
    final created = starts
        .where((event) => dateKey(event.date) == date)
        .map((event) => event.id)
        .toList();
    if (created.isNotEmpty) {
      final id = created.last;
      _undo = (label: '经期开始', run: () => model.removeCycleEvent(id));
    }
    onTab(3);
    _snack(context, '已记 ${_monthDayOfKey(date)} 经期开始', undo: true);
  }

  String _cycleSentence() {
    final cycle = model.cycle;
    if (cycle.windowStart == null || cycle.windowEnd == null) {
      return '还需要至少两个周期才能预测下次时间';
    }
    final median = cycle.medianCycleDays;
    final sd = (cycle.sd ?? 0).toStringAsFixed(1);
    return '下次预计 ${_monthDay(cycle.windowStart!)} 到 '
        '${_monthDay(cycle.windowEnd!)}，周期中位 $median 天，波动 ±$sd 天';
  }

  // ── 查询（只播报，不写数据）─────────────────────────────────────────────

  void _query(BuildContext context, SmalljjLink link) {
    final what = (link.firstOf(['what', 'q', '问']) ?? 'all').toLowerCase();
    final parts = <String>[];
    if (what == 'all' || what == 'budget' || what == '吃') {
      parts.add(_budgetSentence());
    }
    if (what == 'all' || what == 'weight' || what == '体重') {
      parts.add(_weightSentence());
    }
    if (what == 'all' || what == 'cycle' || what == '经期') {
      parts.add(_cycleSentence());
    }
    if (parts.isEmpty) parts.add(_budgetSentence());
    final text = parts.join('；');
    onTab(0);
    _snack(context, text, seconds: 8);
    AppIntents.speak(text);
  }

  String _budgetSentence() {
    final target = model.target;
    final intake = model.repo.intakeForDate(model.todayKey);
    if (target == null) {
      return '还没有今天的预算，先补完资料';
    }
    final left = (target.intakeBudget - intake).round();
    return '今天预算 ${kcalLabel(target.intakeBudget)} 千卡，'
        '已吃 ${intake.round()}，${left >= 0 ? '还可吃 $left' : '超了 ${-left}'}';
  }

  String _weightSentence() {
    final latest = model.repo.weightOnOrBefore(model.todayKey);
    if (latest == null) return '还没有体重记录';
    final change = _currentTrendChange();
    final head = '最近体重 ${kgLabel(latest)} 公斤';
    return change == null ? head : '$head，趋势 $change';
  }

  String? _currentTrendChange() {
    final trend = model.trend;
    if (trend.length < 2) return null;
    final last = trend.last;
    final weekAgo = last.date.subtract(const Duration(days: 7));
    final base = trend.where((p) => !p.date.isAfter(weekAgo)).toList();
    if (base.isEmpty) return null;
    final delta = last.trendKg - base.last.trendKg;
    return '${signed(delta)} 公斤/周';
  }

  // ── 撤销 ────────────────────────────────────────────────────────────────

  void _undoNow(BuildContext context) {
    final entry = _undo;
    if (entry == null) {
      _snack(context, '没有可撤销的语音记录');
      AppIntents.speak('没有可撤销的记录');
      return;
    }
    entry.run();
    _undo = null;
    _snack(context, '已撤销：${entry.label}');
    AppIntents.speak('已撤销');
  }

  bool takeUndo() {
    final entry = _undo;
    if (entry == null) return false;
    entry.run();
    _undo = null;
    return true;
  }

  // ── 参数解析 ────────────────────────────────────────────────────────────

  WeightSlot? _slotOf(String? raw) {
    if (raw == null) return null;
    final value = raw.toLowerCase();
    if (value == 'morning' || value == 'am' || value == '早上' || value == '早' ||
        value == '早晨') {
      return WeightSlot.morning;
    }
    if (value == 'evening' || value == 'pm' || value == '晚上' || value == '晚' ||
        value == '睡前') {
      return WeightSlot.evening;
    }
    if (value == 'other' || value == 'any' || value == '任意' || value == '现在') {
      return WeightSlot.other;
    }
    return null;
  }

  WeightSlot _guessSlot() {
    final hour = model.now.hour;
    if (hour < 11) return WeightSlot.morning;
    if (hour >= 17) return WeightSlot.evening;
    return WeightSlot.other;
  }

  MealSlot? _mealOf(String? raw) {
    if (raw == null) return null;
    final value = raw.toLowerCase();
    if (value == 'breakfast' || value == '早餐' || value == '早饭') {
      return MealSlot.breakfast;
    }
    if (value == 'lunch' || value == '午餐' || value == '午饭' || value == '中午') {
      return MealSlot.lunch;
    }
    if (value == 'dinner' || value == '晚餐' || value == '晚饭' || value == '晚上') {
      return MealSlot.dinner;
    }
    if (value == 'snack' || value == '加餐' || value == '零食' || value == '夜宵') {
      return MealSlot.snack;
    }
    return null;
  }

  MealSlot _guessMeal() {
    final hour = model.now.hour;
    if (hour < 10) return MealSlot.breakfast;
    if (hour < 15) return MealSlot.lunch;
    if (hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }

  double? _kgOf(String? raw) {
    if (raw == null) return null;
    var text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    text = text
        .replaceAll('公斤', '')
        .replaceAll('千克', '')
        .replaceAll('kg', '');
    if (text.endsWith('斤')) {
      final jin = double.tryParse(text.substring(0, text.length - 1));
      return jin == null ? null : jin / 2;
    }
    return double.tryParse(text);
  }

  String? _dateOf(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return dateKey(parsed);
  }

  String _monthDay(DateTime date) => monthDayLabel(date);

  String _monthDayOfKey(String key) {
    final date = DateTime.tryParse(key);
    return date == null ? key : monthDayLabel(date);
  }

  // ── 顶部提示 ────────────────────────────────────────────────────────────

  void _snack(
    BuildContext context,
    String text, {
    bool undo = false,
    int seconds = 5,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(seconds: seconds),
        action: undo
            ? SnackBarAction(
                label: '撤销',
                onPressed: () {
                  if (!takeUndo()) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('已撤销')),
                  );
                },
              )
            : null,
      ),
    );
  }
}
