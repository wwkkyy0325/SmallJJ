import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'surface_card.dart';

/// 加载态：真实的进度指示 + 一句在等什么的说明。
class LoadingView extends StatelessWidget {
  const LoadingView({this.label = '正在读取今日数据…', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppSpace.xl,
              height: AppSpace.xl,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColor.brand,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(label, style: AppType.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 错误态：说清发生了什么，并给一个能重试的按钮。
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricBadge(icon: Icons.cloud_off_rounded, tint: AppColor.heart),
          const SizedBox(height: AppSpace.md),
          Text('没能取到今天的健康数据', style: AppType.title),
          const SizedBox(height: AppSpace.xs),
          Text(message, style: AppType.bodySmall),
          const SizedBox(height: AppSpace.md),
          FilledButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}

/// 空态：不是“没东西”，而是“下一步做什么”。
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricBadge(icon: icon, tint: AppColor.brand, size: 44),
          const SizedBox(height: AppSpace.md),
          Text(title, style: AppType.title),
          const SizedBox(height: AppSpace.xs),
          Text(body, style: AppType.bodySmall),
          if (action != null) ...[
            const SizedBox(height: AppSpace.md),
            action!,
          ],
        ],
      ),
    );
  }
}
