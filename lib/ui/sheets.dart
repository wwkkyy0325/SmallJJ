import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../domain/food_parse.dart';
import '../theme/tokens.dart';
import 'app_model.dart';
import 'format.dart';

/// 记体重：早/晚/任意三档，同一天同一档再记即覆盖。
Future<void> showWeightSheet(
  BuildContext context,
  AppModel model, {
  required WeightSlot slot,
  String? localDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _WeightSheet(
        model: model,
        initialSlot: slot,
        localDate: localDate ?? model.todayKey,
      ),
    ),
  );
}

class _WeightSheet extends StatefulWidget {
  const _WeightSheet({
    required this.model,
    required this.initialSlot,
    required this.localDate,
  });

  final AppModel model;
  final WeightSlot initialSlot;
  final String localDate;

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late WeightSlot _slot = widget.initialSlot;
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.model.repo.weightOn(widget.localDate, _slot);
    final last = widget.model.repo.latestWeightKg();
    _controller = TextEditingController(
      text: existing != null
          ? kgLabel(existing.weightKg)
          : last != null
          ? kgLabel(last)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bump(double delta) {
    final current = double.tryParse(_controller.text) ?? 0;
    if (current <= 0) return;
    _controller.text = kgLabel(current + delta);
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 25 || value > 300) {
      setState(() => _error = '请输入 25–300 之间的体重');
      return;
    }
    widget.model.saveWeight(
      slot: _slot,
      kg: value,
      localDate: widget.localDate,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.localDate == widget.model.todayKey;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isToday ? '记录体重' : '补记 ${widget.localDate}',
                    style: AppType.headline,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            SegmentedButton<WeightSlot>(
              segments: [
                for (final slot in WeightSlot.values)
                  ButtonSegment(value: slot, label: Text(slot.label)),
              ],
              selected: {_slot},
              onSelectionChanged: (value) {
                setState(() {
                  _slot = value.first;
                  final existing = widget.model.repo.weightOn(
                    widget.localDate,
                    _slot,
                  );
                  if (existing != null) {
                    _controller.text = kgLabel(existing.weightKg);
                  }
                });
              },
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: AppType.display,
              decoration: const InputDecoration(
                suffixText: 'kg',
                border: OutlineInputBorder(),
                hintText: '60.0',
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                _error!,
                style: AppType.bodySmall.copyWith(color: AppColor.heart),
              ),
            ],
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _bump(-0.1),
                  child: const Text('−0.1'),
                ),
                const SizedBox(width: AppSpace.xs),
                OutlinedButton(
                  onPressed: () => _bump(0.1),
                  child: const Text('+0.1'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.brandStrong,
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text('同一天同一时段再记会覆盖上一条。早上起床后、晚上睡前各一次最稳定。', style: AppType.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 记饮食：一句话解析 + 搜索 + 自建条目。
///
/// [initialText] 用于语音入口：小布把原话带进来，用户只需核对。
Future<void> showFoodSheet(
  BuildContext context,
  AppModel model, {
  required MealSlot slot,
  String? initialText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _FoodSheet(
        model: model,
        initialSlot: slot,
        initialText: initialText,
      ),
    ),
  );
}

class _FoodSheet extends StatefulWidget {
  const _FoodSheet({
    required this.model,
    required this.initialSlot,
    this.initialText,
  });

  final AppModel model;
  final MealSlot initialSlot;
  final String? initialText;

  @override
  State<_FoodSheet> createState() => _FoodSheetState();
}

class _FoodSheetState extends State<_FoodSheet> {
  late MealSlot _slot = widget.initialSlot;
  final _text = TextEditingController();
  final _grams = TextEditingController(text: '100');
  FoodItem? _selected;
  List<FoodMention> _mentions = const [];

  @override
  void initState() {
    super.initState();
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _text.text = text;
      _mentions = parseFoodText(text);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _grams.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {
      _mentions = parseFoodText(value);
    });
  }

  List<FoodItem> get _results {
    final mentions = _mentions;
    final query = mentions.isEmpty ? _text.text.trim() : mentions.last.name;
    return widget.model.repo.searchFoods(query, limit: 8);
  }

  void _pick(FoodItem food, double grams) {
    setState(() {
      _selected = food;
      _grams.text = grams.round().toString();
    });
  }

  void _add() {
    final food = _selected;
    final grams = double.tryParse(_grams.text.trim());
    if (food == null || grams == null || grams <= 0) return;
    widget.model.addFood(_slot, food, grams);
    _text.clear();
    setState(() {
      _mentions = const [];
      _selected = null;
      _grams.text = '100';
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('已记录 ${food.name} ${grams.round()} g')),
      );
  }

  Future<void> _createCustom() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建食物'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每 100 g 热量 (kcal)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (created != true) return;
    final kcalValue = double.tryParse(kcal.text.trim());
    if (name.text.trim().isEmpty || kcalValue == null) return;
    final id = widget.model.repo.addCustomFood(
      name: name.text.trim(),
      kcalPer100g: kcalValue,
    );
    final food = widget.model.repo.foodById(id);
    if (food != null && mounted) _pick(food, 100);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final kcal = selected == null
        ? 0.0
        : selected.kcalPer100g * (double.tryParse(_grams.text) ?? 0) / 100;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        // 键盘弹出时整块可滚动，避免 BOTTOM OVERFLOWED。
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('记录饮食', style: AppType.headline)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '关闭',
                  ),
                ],
              ),
              SegmentedButton<MealSlot>(
                segments: [
                  for (final meal in MealSlot.values)
                    ButtonSegment(value: meal, label: Text(meal.label)),
                ],
                selected: {_slot},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _slot = value.first),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _text,
                autofocus: true,
                onChanged: _onTextChanged,
                decoration: const InputDecoration(
                  labelText: '一句话记',
                  hintText: '两个鸡蛋一杯牛奶',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_mentions.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  children: [
                    for (final mention in _mentions)
                      ActionChip(
                        label: Text(
                          '${mention.name} ×${mention.quantity.toStringAsFixed(mention.quantity % 1 == 0 ? 0 : 1)}${mention.unit ?? ''}',
                        ),
                        onPressed: () {
                          final matches = widget.model.repo.searchFoods(
                            mention.name,
                            limit: 1,
                          );
                          if (matches.isEmpty) return;
                          _pick(
                            matches.first,
                            mention
                                .gramsWith(matches.first.defaultPortionG)
                                .roundToDouble(),
                          );
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 176,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final food = _results[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.kcalPer100g.round()} kcal/100g · '
                        '一份 ${food.defaultPortionG.round()} g'
                        '${food.isCustom ? ' · 自建' : ''}',
                        style: AppType.bodySmall,
                      ),
                      trailing: selected?.id == food.id
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColor.brand,
                            )
                          : null,
                      onTap: () => _pick(food, food.defaultPortionG),
                    );
                  },
                ),
              ),
              const Divider(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: selected == null
                        ? Text('选择一种食物，或直接搜索', style: AppType.bodySmall)
                        : Text(
                            '${selected.name} · ${kcal.round()} kcal',
                            style: AppType.title,
                          ),
                  ),
                  SizedBox(
                    width: 92,
                    child: TextField(
                      controller: _grams,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        suffixText: 'g',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  FilledButton(
                    onPressed: selected == null ? null : _add,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.brandStrong,
                      minimumSize: const Size(72, 48),
                    ),
                    child: const Text('添加'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _createCustom,
                  icon: const Icon(Icons.add_rounded, size: AppIcon.sm),
                  label: const Text('库里没有？新建一条'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 洞察详情：把规则用到的数字摆出来，不让人猜结论从哪来。
Future<void> showInsightDetail(BuildContext context, Insight insight) {
  final evidence = insight.evidence.entries
      .map((entry) => '${entry.key} = ${entry.value}')
      .join('\n');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('依据'),
      content: Text(
        insight.evidence.isEmpty
            ? '这条来自你的记录状态，没有额外数字。'
            : '$evidence\n\n文案仅由规则引擎生成，模型不参与数字计算。',
        style: AppType.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
