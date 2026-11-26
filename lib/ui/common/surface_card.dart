import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 卡片：白底、16 圆角、唯一一层投影。全站卡片都走这里。
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color = AppColor.surface,
    this.radius = AppRadius.lgAll,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: AppShadow.card,
        border: Border.all(color: AppColor.line.withValues(alpha: 0.6)),
      ),
      // 卡片内的 ListTile / SwitchListTile 需要有 Material 祖先，
      // 否则会命中「ink splash 被 DecoratedBox 挡住」的断言。
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 区块标题：左侧标题 + 可选的右侧动作。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.trailing,
    this.caption,
    super.key,
  });

  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppType.section),
              if (caption != null) ...[
                const SizedBox(height: AppSpace.xxs),
                Text(caption!, style: AppType.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// 指标徽章：一个图标 + 一层浅底，颜色取自指标色。
class MetricBadge extends StatelessWidget {
  const MetricBadge({
    required this.icon,
    required this.tint,
    this.size = 36,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, size: size * 0.52, color: tint),
    );
  }
}

/// 进度条：轨道 + 填充。整站的「一条比例」都走这里。
///
/// 只有一种颜色（品牌渐变），没有「超支翻红」，也没有预算刻度：这条不是
/// 评价，是比例。应用不做计划，见 `docs/本轮实现与取舍.md`「不再有目标、
/// 预算、缺口」。
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.value,
    this.height = 6,
    super.key,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppMotion.respect(context, AppMotion.slow),
        curve: AppMotion.enter,
        builder: (context, v, _) => LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: height,
                  width: width,
                  color: AppColor.surfaceMuted,
                ),
                Container(
                  height: height,
                  width: width * v,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.brand, AppColor.brandStrong],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
