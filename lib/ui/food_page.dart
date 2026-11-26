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
    final budget = target?.intakeBudget ?? 0;
    final ratio = budget == 0 ? 0.0 : (intake / budget).clamp(0.0, 1.0);
    final over = intake > budget;

    final protein = model.meals.fold<double>(0, (s, m) => s + m.proteinG);
    final carb = model.meals.fold<double>(
        0, (s, m) => s + m.items.fold<double>(0, (a, i) => a + i.carbG));
    final fat = model.meals.fold<double>(
        0, (s, m) => s + m.items.fold<double>(0, (a, i) => a + i.fatG));

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
                  Text(
                    '/ ${kcalLabel(budget)} kcal',
                    style: AppType.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    over ? '超出 ${kcalLabel(intake - budget)}' : '还剩 ${kcalLabel(budget - intake)}',
                    style: AppType.label.copyWith(
                      color: over ? AppColor.heart : AppColor.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: AppColor.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation(
                    over ? AppColor.heart : AppColor.brand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  _Macro(
                    label: '蛋白',
                    value: protein,
                    target: target?.proteinG ?? 0,
                    color: AppColor.brand,
                  ),
                  _Macro(
                    label: '碳水',
                    value: carb,
                    target: target?.carbG ?? 0,
                    color: AppColor.amber,
                  ),
                  _Macro(
                    label: '脂肪',
                    value: fat,
                    target: target?.fatG ?? 0,
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
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.label),
          const SizedBox(height: AppSpace.xxs),
          Text(
            '${value.round()} / ${target.round()} g',
            style: AppType.bodySmall.copyWith(color: AppColor.ink),
          ),
          const SizedBox(height: AppSpace.xxs),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: ratio,
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
