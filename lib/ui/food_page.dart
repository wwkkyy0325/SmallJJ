import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'common/surface_card.dart';
import 'app_model.dart';
import 'format.dart';
import 'sheets.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({required this.model, super.key});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final target = model.target;
    final intake = model.facts?.todayIntake ?? 0;
    final expenditure = target?.tdee ?? 0;
    final ratio =
        expenditure == 0 ? 0.0 : (intake / expenditure).clamp(0.0, 1.0);

    final protein = model.meals.fold<double>(0, (s, m) => s + m.proteinG);
    final carb = model.meals.fold<double>(
        0, (s, m) => s + m.items.fold<double>(0, (a, i) => a + i.carbG));
    final fat = model.meals.fold<double>(
        0, (s, m) => s + m.items.fold<double>(0, (a, i) => a + i.fatG));
    // 三条宏量只显示「今天吃了多少、占多少热量」，不设目标线。
    final macroKcal = protein * 4 + carb * 4 + fat * 9;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text('饮食', style: AppType.display)),
            Text(monthDayLabel(model.now), style: AppType.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(kcalLabel(intake), style: AppType.ringNumber),
                  const SizedBox(width: AppSpace.xxs),
                  Text('kcal', style: AppType.bodySmall),
                  const Spacer(),
                  Text(
                    '估算消耗 ${kcalLabel(expenditure)}',
                    style: AppType.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              ProgressBar(value: ratio, height: AppMeter.height),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  _Macro(
                    label: '蛋白',
                    grams: protein,
                    kcal: protein * 4,
                    total: macroKcal,
                    color: AppColor.brand,
                  ),
                  _Macro(
                    label: '碳水',
                    grams: carb,
                    kcal: carb * 4,
                    total: macroKcal,
                    color: AppColor.amber,
                  ),
                  _Macro(
                    label: '脂肪',
                    grams: fat,
                    kcal: fat * 9,
                    total: macroKcal,
                    color: AppColor.water,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final section in model.meals) ...[
          _MealCard(
            section: section,
            onAdd: () => showFoodSheet(context, model, slot: section.slot),
            onRemove: model.removeFood,
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        const SizedBox(height: AppSpace.xs),
        Text(
          '热量按「食物库每 100 g × 克数」计算。库里的数值是常见参考值，'
          '不准就在添加页新建一条自己的。',
          style: AppType.bodySmall,
        ),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.grams,
    required this.kcal,
    required this.total,
    required this.color,
  });

  final String label;
  final double grams;
  final double kcal;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0.0 : (kcal / total).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.label),
          const SizedBox(height: AppSpace.xxs),
          Text(
            '${grams.round()} g · ${(share * 100).round()}%',
            style: AppType.bodySmall.copyWith(color: AppColor.ink),
          ),
          const SizedBox(height: AppSpace.xxs),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: share,
              minHeight: 4,
              backgroundColor: AppColor.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.section,
    required this.onAdd,
    required this.onRemove,
  });

  final MealSection section;
  final VoidCallback onAdd;
  final void Function(int id) onRemove;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(section.slot.label, style: AppType.title),
              const SizedBox(width: AppSpace.xs),
              Text(
                section.items.isEmpty ? '' : '${kcalLabel(section.kcal)} kcal',
                style: AppType.bodySmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: '添加食物',
                color: AppColor.brandStrong,
              ),
            ],
          ),
          if (section.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text('还没记录', style: AppType.bodySmall),
            )
          else
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xxs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.foodName} · ${item.grams.round()} g',
                        style: AppType.body,
                      ),
                    ),
                    Text('${kcalLabel(item.kcal)} kcal',
                        style: AppType.bodySmall),
                    IconButton(
                      onPressed: () => onRemove(item.id),
                      icon: const Icon(Icons.close_rounded, size: AppIcon.sm),
                      visualDensity: VisualDensity.compact,
                      tooltip: '删除',
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
