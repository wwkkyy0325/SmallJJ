import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/food_parse.dart';
import '../theme/tokens.dart';
import 'app_model.dart';
import 'common/app_dialog.dart';
import 'common/app_sheet.dart';
import 'common/weight_entry.dart';

/// 记体重：只有「时间 + 体重」两个值，时间是当前时间，点一下可以改。
/// 传 [entry] 表示改已有那一条。
Future<void> showWeightSheet(
  BuildContext context,
  AppModel model, {
  WeightEntry? entry,
  DateTime? at,
}) {
  return showAppSheet<void>(
    context,
    title: entry == null ? '记体重' : '改体重',
    // 高度按表单本身算出来：「记」和「改」、出错和没出错，弹层一样高、顶边在同一条线上。
    bodyHeight: WeightEntryForm.stackedHeight,
    // 键盘弹出或屏幕很矮时内容在弹层里滚动，弹层本身不跟着变。
    body: (_) => SingleChildScrollView(
      child: WeightEntryForm(
        model: model,
        entry: entry,
        at: at ?? entry?.date ?? model.now,
        allowDate: true,
        onSaved: () => Navigator.of(context).pop(),
      ),
    ),
  );
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
  return showAppSheet<void>(
    context,
    title: '记录饮食',
    bodyHeight: _FoodSheet.plannedHeight,
    body: (height) => _FoodSheet(
      model: model,
      initialSlot: slot,
      initialText: initialText,
      height: height,
    ),
  );
}

class _FoodSheet extends StatefulWidget {
  const _FoodSheet({
    required this.model,
    required this.initialSlot,
    required this.height,
    this.initialText,
  });

  /// 计划高度：搜索结果列表按它减去固定行数算出来，弹层不会因为
  /// 「一句话解析出几个食物」而变高变矮。
  static const double plannedHeight = 470;

  /// 固定行合计：餐次 / 一句话 / 解析结果 / 列表外的说明 / 底部一行 / 新建入口。
  static const double _fixed =
      48 + // 餐次分段
      AppSpace.sm +
      AppLayout.fieldHeight + // 一句话输入
      AppSpace.xs +
      44 + // 解析结果行（空着也占位）
      AppSpace.sm +
      AppSpace.xs +
      1 + // 分隔线
      AppSpace.xs +
      AppLayout.fieldHeight + // 所选食物 + 克数 + 添加
      AppSpace.xxs +
      AppLayout.tapMin; // 库里没有？新建一条

  final AppModel model;
  final MealSlot initialSlot;
  final String? initialText;

  /// 弹层真正给这一段的高度（可能比 [plannedHeight] 小）。
  final double height;

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
    final created = await showAppDialog<bool>(
      context,
      title: '新建食物',
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
        DialogAction(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: '保存',
          primary: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
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
    // 克数没填对（空、或者混进了非数字）时不给 0 kcal：那会让人以为食物没热量。
    // 这里算成 null，标签说「克数没填对」，「添加」也不亮——点不动比默默无反应清楚。
    final grams = double.tryParse(_grams.text.trim());
    final kcal = selected == null || grams == null || grams <= 0
        ? null
        : selected.kcalPer100g * grams / 100;
    // 列表吃掉固定行之外的全部高度：解析结果多一行、少一行都不影响弹层高度。
    final listHeight = (widget.height - _FoodSheet._fixed).clamp(88.0, 260.0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: SegmentedButton<MealSlot>(
              segments: [
                for (final meal in MealSlot.values)
                  ButtonSegment(value: meal, label: Text(meal.label)),
              ],
              selected: {_slot},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _slot = value.first),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: AppLayout.fieldHeight,
            child: TextField(
              controller: _text,
              autofocus: true,
              onChanged: _onTextChanged,
              decoration: const InputDecoration(
                labelText: '一句话记',
                hintText: '两个鸡蛋一杯牛奶',
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          // 解析结果固定占一行：横着滑，不换行，弹层不会因为它变高。
          SizedBox(height: 44, child: _mentionsRow()),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: listHeight,
            child: _results.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text('没搜到，换个说法或新建一条', style: AppType.bodySmall),
                  )
                : ListView.builder(
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
          const SizedBox(height: AppSpace.xs),
          const Divider(height: 1),
          const SizedBox(height: AppSpace.xs),
          SizedBox(
            height: AppLayout.fieldHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? '选择一种食物，或直接搜索'
                        : kcal == null
                        ? '${selected.name} · 克数没填对'
                        : '${selected.name} · ${kcal.round()} kcal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: selected == null
                        ? AppType.bodySmall
                        : AppType.title,
                  ),
                ),
                SizedBox(
                  width: 88,
                  height: AppLayout.fieldHeight,
                  child: TextField(
                    controller: _grams,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(suffixText: 'g'),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                SizedBox(
                  width: 84,
                  child: FilledButton(
                    // 按钮宽度是按两个字算死的，去掉默认左右内边距，
                    // 免得「添加」被挤成两行、上下裁掉。
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, AppLayout.fieldHeight),
                    ),
                    onPressed: kcal == null ? null : _add,
                    child: const Text('添加', maxLines: 1, softWrap: false),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: AppLayout.tapMin,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createCustom,
                icon: const Icon(Icons.add_rounded, size: AppIcon.sm),
                label: const Text('库里没有？新建一条'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mentionsRow() {
    if (_mentions.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('解析结果会出现在这一行', style: AppType.bodySmall),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _mentions.length,
      separatorBuilder: (context, index) => const SizedBox(width: AppSpace.xs),
      itemBuilder: (context, index) {
        final mention = _mentions[index];
        final quantity = mention.quantity.toStringAsFixed(
          mention.quantity % 1 == 0 ? 0 : 1,
        );
        return _MentionChip(
          label: '${mention.name} ×$quantity${mention.unit ?? ''}',
          onTap: () {
            final matches = widget.model.repo.searchFoods(
              mention.name,
              limit: 1,
            );
            if (matches.isEmpty) return;
            _pick(
              matches.first,
              mention.gramsWith(matches.first.defaultPortionG).roundToDouble(),
            );
          },
        );
      },
    );
  }
}

/// 解析结果的小标签：高度固定在一个 44 的行里，不参与换行。
class _MentionChip extends StatelessWidget {
  const _MentionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.pillAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xs,
            ),
            child: Text(label, style: AppType.bodySmall),
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
  return showAppDialog<void>(
    context,
    title: '依据',
    content: Text(
      insight.evidence.isEmpty
          ? '这条来自你的记录状态，没有额外数字。'
          : '$evidence\n\n文案仅由规则引擎生成，模型不参与数字计算。',
    ),
    actions: [
      DialogAction(
        label: '知道了',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
