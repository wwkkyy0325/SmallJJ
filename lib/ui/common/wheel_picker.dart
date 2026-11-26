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
    this.suffix,
    this.style,
    super.key,
  });

  /// 列里有多少行（小时 24、分钟 60、日 28~31）。
  final int count;

  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  /// 第 index 行的文字。
  final String Function(int index) label;

  /// 数字后面的单位（日期那三列的「年 / 月 / 日」）。
  ///
  /// 单独画成一段小字而不是拼进 [label]：拼进去之后整串只能用同一个字号，
  /// 「2026年」要么数字太小、要么被列宽挤掉。
  final String? Function(int index)? suffix;

  /// 默认 [AppType.metric]——和胶囊上的值同一档，滚轮里外不会两个样。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: AppLayout.wheelRow,
      // 不要 Cupertino 的放大镜：它会把选中行放大 1.08 倍，20sp 的数字在真机上
      // 渲成 44px 高，而胶囊里同一个数是 40px——「滚轮里外两个样」就是这么来的。
      // 选中行靠身后那条高亮色带区分，不靠字号。
      useMagnifier: false,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onChanged,
      childCount: count,
      // 数字 + 单位未必塞得进一列（「2026年」是最长的一行，窄屏或
      // 换字体都可能多出几像素）；放不下时整体缩一点，而不是剪掉一个「年」。
      itemBuilder: (context, index) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label(index),
                maxLines: 1,
                style: style ?? AppType.metric,
                textAlign: TextAlign.center,
              ),
              if (suffix?.call(index) case final tail?)
                Text(
                  tail,
                  maxLines: 1,
                  // 单位就是 bodySmall：和胶囊上「62.42 kg」的 kg 同一档。
                  style: AppType.bodySmall,
                ),
            ],
          ),
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
