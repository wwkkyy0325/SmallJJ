import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';
import 'anchor_popover.dart';

/// 滚轮列：浮层里所有「选一个数」的列都用它。
///
/// 高度固定 [AppLayout.wheelRow] × 3 行：中间一行是当前值，上下各一行只作
/// 参照。行的边界和 [AppLayout.wheelRow] 对齐，所以边缘那一行不会被裁成半个字。
///
/// 用的是 CupertinoPicker 而不是 Material 的：Material 没有滚轮；
/// 而且这里要的是「滚到哪里就是哪里」，不加放大镜之外的任何装饰。
class WheelPicker extends StatelessWidget {
  const WheelPicker({
    required this.count,
    required this.controller,
    required this.onChanged,
    required this.label,
    this.style,
    super.key,
  });

  /// 列里有多少行（小时 24、分钟 60、日 28~31）。
  final int count;

  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  /// 第 index 行的文字。
  final String Function(int index) label;

  /// 默认 [AppType.metric]；日期那种带「年 / 月 / 日」后缀的列会传小一号。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: AppLayout.wheelRow,
      useMagnifier: true,
      magnification: 1.08,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onChanged,
      childCount: count,
      itemBuilder: (context, index) => Center(
        child: Text(
          label(index),
          maxLines: 1,
          style: style ?? AppType.metric,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 中间那一条高亮横条：浮层里所有滚轮共用一条，读起来就是「一个值」。
class WheelHighlight extends StatelessWidget {
  const WheelHighlight({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: AppLayout.wheelRow,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
        decoration: const BoxDecoration(
          color: AppColor.surfaceMuted,
          borderRadius: AppRadius.smAll,
        ),
      ),
    );
  }
}

/// 上下边缘渐隐：滚轮最外侧那一行只露出一半，不渐隐会被读成残字。
class WheelFade extends StatelessWidget {
  const WheelFade({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x00000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0x00000000),
        ],
        stops: [0, 0.34, 0.66, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

/// 浮层底部那一行：左边一句说明，右边一个回退按钮（「现在」/「今天」/「上次」）。
///
/// 没有可回退的值时不传 [actionLabel]：那一行只留说明，不摆一个点了没反应的按钮。
class PopoverFootline extends StatelessWidget {
  const PopoverFootline({
    required this.hint,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.popoverFooter,
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.label.copyWith(color: AppColor.inkFaint),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpace.xs),
            PopoverAction(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}
