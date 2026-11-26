import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 贴着某个控件弹出来的浮层：位置、大小全部由调用方定死。
///
/// 和底部弹层 `showAppSheet` 的分工：
/// - 底部弹层：一次完整的动作（记一笔、改一条），铺满宽度、背景压暗；
/// - 锚点浮层：改一个值（时间、日期），贴在被点的 chip 旁边，不铺满、不压暗、
///   没有「确定」——滚到哪里就是哪里，点旁边一下收起。
///
/// 所以「改时间」不用先离开表单：chip 还看得见，它上面的字跟着滚轮一起变。
///
/// 位置只在三条规则里挑，不随手算：
/// 1. 默认贴在锚点下方，左边缘对齐锚点左边缘，中间留 [AppLayout.popoverGap]；
/// 2. 下面放不下就翻到锚点上方；
/// 3. 左右越界就往屏幕里推，永远留出 [AppLayout.popoverInset]。
Future<T?> showAnchorPopover<T>({
  required BuildContext context,
  required BuildContext anchor,
  required double width,
  required double height,
  required Widget Function(BuildContext context) builder,
}) {
  final overlayBox =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final anchorBox = anchor.findRenderObject()! as RenderBox;
  final spot = placePopover(
    anchor: MatrixUtils.transformRect(
      anchorBox.getTransformTo(overlayBox),
      Offset.zero & anchorBox.size,
    ),
    overlay: overlayBox.size,
    width: width,
    height: height,
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // 只压一层极浅的暗：浮层要读成「在上面一层」，但底下的表单还得看得清。
    barrierColor: AppColor.ink.withValues(alpha: 0.16),
    transitionDuration: AppMotion.respect(context, AppMotion.quick),
    pageBuilder: (dialogContext, animation, secondaryAnimation) => SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            left: spot.left,
            top: spot.top,
            width: spot.width,
            height: spot.height,
            child: PopoverCard(child: builder(dialogContext)),
          ),
        ],
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          alignment: Alignment.topLeft,
          child: child,
        ),
      );
    },
  );
}

/// 浮层的落点：给锚点矩形、屏幕尺寸和浮层尺寸，算出左上角。
///
/// 单独拎出来是为了能直接断言：同样的锚点永远落同一个位置，
/// 不会因为「这次屏幕矮一点」就换一种算法。
Rect placePopover({
  required Rect anchor,
  required Size overlay,
  required double width,
  required double height,
}) {
  const inset = AppLayout.popoverInset;
  const gap = AppLayout.popoverGap;

  final left = math.min(
    math.max(anchor.left, inset),
    math.max(inset, overlay.width - width - inset),
  );

  final below = anchor.bottom + gap;
  final above = anchor.top - gap - height;
  final double top;
  if (below + height + inset <= overlay.height) {
    top = below;
  } else if (above >= inset) {
    top = above;
  } else {
    // 上下都放不下（屏幕特别矮）：还是放在下面，但不出屏幕。
    top = math.min(
      math.max(below, inset),
      math.max(inset, overlay.height - height - inset),
    );
  }

  return Rect.fromLTWH(left, top, width, height);
}

/// 浮层的壳：白底、大圆角、细描边、一档更深的投影。
///
/// 尺寸由调用方给死，这里只负责「看起来浮在上面」，不加内边距、不撑高。
class PopoverCard extends StatelessWidget {
  const PopoverCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColor.line),
        boxShadow: AppShadow.popover,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Material(
          color: AppColor.surface,
          child: child,
        ),
      ),
    );
  }
}

/// 浮层底部的小按钮（「现在」「今天」）：高 [AppLayout.popoverFooter]，
/// 和旁边那行说明垂直居中对齐。
class PopoverAction extends StatelessWidget {
  const PopoverAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.brandSoft,
      borderRadius: AppRadius.pillAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppType.stat.copyWith(color: AppColor.brandStrong),
            ),
          ),
        ),
      ),
    );
  }
}
