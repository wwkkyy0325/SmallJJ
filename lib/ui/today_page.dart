import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'common/pressable.dart';
import 'common/surface_card.dart';
import 'common/weight_entry.dart';
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

          // ── 热量：首屏第一张卡，今天还能吃多少 ──────────────────
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

          // ── 体重填写：第二张卡，填数字回车即记 ──────────────────
          _WeightFillCard(model: model, onOpenTrend: onOpenTrend),
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

/// 首屏第二张卡的体重填写：时间 + 体重 两颗胶囊 + 保存，和「记体重」弹层是同一个控件。
class _WeightFillCard extends StatelessWidget {
  const _WeightFillCard({required this.model, required this.onOpenTrend});

  final AppModel model;
  final VoidCallback onOpenTrend;

  @override
  Widget build(BuildContext context) {
    final last = model.entries.isEmpty ? null : model.entries.first;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '体重',
            caption: '点一下选时间和体重',
            trailing: TextButton(
              onPressed: onOpenTrend,
              child: const Text('趋势'),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          WeightEntryForm(model: model),
          // 两行摘要一直占位：记了第一条之后卡片不会突然长高，
          // 上面的热量卡和按钮也就不会往下跳。
          const SizedBox(height: AppSpace.sm),
          Text(
            last == null
                ? '还没有记录'
                : '最近 ${kgLabel(last.weightKg)} kg · '
                      '${relativeDay(last.date, model.now)} '
                      '${clockLabel(last.date)}',
            style: AppType.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            model.trend.length > 1
                ? '趋势 ${signed(model.trend.last.trendKg - model.trend.first.trendKg, digits: 2)} kg'
                : '趋势：两条记录之后显示',
            style: AppType.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
