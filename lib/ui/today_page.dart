import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'common/pressable.dart';
import 'common/surface_card.dart';
import 'app_model.dart';
import 'format.dart';
import 'sheets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.model,
    required this.onOpenTrend,
    required this.onOpenProfile,
    super.key,
  });

  final AppModel model;
  final VoidCallback onOpenTrend;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final target = model.target;
    final facts = model.facts;
    final profile = model.profile;
    if (target == null || facts == null || profile == null) {
      return const Center(child: Text('还没有资料'));
    }
    final remaining = target.intakeBudget - facts.todayIntake;
    final intakeRatio = (facts.todayIntake / target.intakeBudget)
        .clamp(0.0, 1.0)
        .toDouble();
    final over = facts.todayIntake > target.intakeBudget;
    final otherToday = model.repo.weightOn(model.todayKey, WeightSlot.other);

    return RefreshIndicator(
      onRefresh: () async => model.reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullDateLabel(model.now), style: AppType.bodySmall),
                    const SizedBox(height: AppSpace.xxs),
                    Text('今天', style: AppType.display),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenProfile,
                icon: const Icon(Icons.person_outline_rounded),
                tooltip: '我的',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // ── 热量 ────────────────────────────────────────────────
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        over ? '超出预算' : '今天还能吃',
                        style: AppType.label,
                      ),
                    ),
                    Text(
                      '预算 ${kcalLabel(target.intakeBudget)} kcal',
                      style: AppType.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      kcalLabel(remaining.abs()),
                      style: AppType.ringNumber.copyWith(
                        color: over ? AppColor.heart : AppColor.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text('kcal', style: AppType.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillAll,
                  child: LinearProgressIndicator(
                    value: intakeRatio,
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
                    _Stat(label: '已摄入', value: kcalLabel(facts.todayIntake)),
                    _Stat(label: '每日消耗', value: kcalLabel(target.tdee)),
                    _Stat(label: '缺口', value: kcalLabel(target.deficitKcal)),
                  ],
                ),
                if (target.note != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: AppIcon.sm,
                        color: AppColor.amber,
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Expanded(
                        child: Text(target.note!, style: AppType.bodySmall),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ── 体重 ────────────────────────────────────────────────
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: '体重',
                  trailing: TextButton(
                    onPressed: onOpenTrend,
                    child: const Text('趋势'),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: _WeightSlotTile(
                        slot: WeightSlot.morning,
                        entry: model.morningEntry,
                        onTap: () => showWeightSheet(
                          context,
                          model,
                          slot: WeightSlot.morning,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _WeightSlotTile(
                        slot: WeightSlot.evening,
                        entry: model.eveningEntry,
                        onTap: () => showWeightSheet(
                          context,
                          model,
                          slot: WeightSlot.evening,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                if (otherToday != null) ...[
                  _OtherWeightRow(
                    entry: otherToday,
                    onTap: () =>
                        showWeightSheet(context, model, slot: WeightSlot.other),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                Row(
                  children: [
                    TextButton(
                      onPressed: () => showWeightSheet(
                        context,
                        model,
                        slot: WeightSlot.other,
                      ),
                      child: const Text('任意时刻记一笔'),
                    ),
                    const Spacer(),
                    Text(
                      '趋势 ${signed(model.trend.isEmpty ? 0 : model.trend.last.trendKg - (model.trend.first.trendKg), digits: 1)} kg',
                      style: AppType.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ── 分析 ────────────────────────────────────────────────
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: '健康分析', caption: '规则引擎在本地算，不联网、不上传'),
                const SizedBox(height: AppSpace.sm),
                if (model.insights.isEmpty)
                  Text('今天没有需要提醒的事。', style: AppType.body)
                else
                  for (final insight in model.insights.take(4))
                    _InsightTile(
                      insight: insight,
                      onTap: () => showInsightDetail(context, insight),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            '数据全部存在本机，卸载即消失。',
            style: AppType.micro,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.label),
          const SizedBox(height: AppSpace.xxs),
          Text(value, style: AppType.stat),
        ],
      ),
    );
  }
}

class _WeightSlotTile extends StatelessWidget {
  const _WeightSlotTile({
    required this.slot,
    required this.entry,
    required this.onTap,
  });

  final WeightSlot slot;
  final WeightEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = entry != null;
    return Pressable(
      onTap: onTap,
      radius: AppRadius.mdAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: has ? AppColor.brandSoft : AppColor.surfaceMuted,
          borderRadius: AppRadius.mdAll,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.label, style: AppType.label),
            const SizedBox(height: AppSpace.xxs),
            Text(
              has ? '${kgLabel(entry!.weightKg)} kg' : '记录',
              style: has ? AppType.metric : AppType.title,
            ),
          ],
        ),
      ),
    );
  }
}

/// 今天已记的「任意时刻」那一条。同一时段覆盖式写入，所以最多一条。
class _OtherWeightRow extends StatelessWidget {
  const _OtherWeightRow({required this.entry, required this.onTap});

  final WeightEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      radius: AppRadius.mdAll,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surfaceMuted,
          borderRadius: AppRadius.mdAll,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Text('任意 · ${clockLabel(entry.date)}', style: AppType.label),
            const Spacer(),
            Text('${kgLabel(entry.weightKg)} kg', style: AppType.metric),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight, required this.onTap});

  final Insight insight;
  final VoidCallback onTap;

  Color get _color => switch (insight.severity) {
    'action' => AppColor.brandStrong,
    'warn' => AppColor.heart,
    _ => AppColor.inkMuted,
  };

  IconData get _icon => switch (insight.severity) {
    'action' => Icons.bolt_rounded,
    'warn' => Icons.error_outline_rounded,
    _ => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      radius: AppRadius.smAll,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: AppIcon.md, color: _color),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(insight.text, style: AppType.body)),
        ],
      ),
    );
  }
}
