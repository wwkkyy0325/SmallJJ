import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 弹层路由本身：位置（贴底、左右居中）、最大宽度、圆角、遮罩只在这里写一次。
///
/// 绝大多数弹层用 [showAppSheet] 就够了；需要自己持有状态（比如时间滚轮的
/// 「现在」要滚动两列）时，用这个拿到路由后把 [AppSheet] 放进自己的 State 里。
Future<T?> pushAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context).push<T>(
    ModalBottomSheetRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: Navigator.of(context).context,
      ),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColor.surface,
      modalBarrierColor: AppColor.ink.withValues(alpha: 0.32),
      constraints: const BoxConstraints(maxWidth: AppLayout.sheetMaxWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
  );
}

/// 打开底部弹层。
///
/// 位置（贴底、左右居中、限宽）、高度、头部、底部按钮全由 [AppSheet] 定，
/// 业务只给「标题 + 计划内容高度 + 内容 + 可选底部按钮」。
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required double bodyHeight,
  required Widget Function(double bodyHeight) body,
  Widget? titleAction,
  Widget? footer,
}) {
  return pushAppSheet<T>(
    context,
    (context) => AppSheet(
      title: title,
      bodyHeight: bodyHeight,
      body: body,
      titleAction: titleAction,
      footer: footer,
    ),
  );
}

/// 所有底部弹层的唯一实现。
///
/// 一个弹层从上到下只有四段，每段高度都是常量或调用方给的数：
/// 1. 顶部留白 [AppLayout.sheetTopPad]；
/// 2. 头部 [AppLayout.sheetHeader]（标题 / 可选动作 / 关闭）；
/// 3. 内容：调用方计划的高度，屏幕矮或键盘弹出时收窄；
/// 4. 底部按钮（可选）+ 留白。
///
/// 所以「记体重」和「改体重」、有没有错误提示、时间标签长短，弹层的顶边都在
/// 同一个 y 上；内容变化只发生在第 3 段内部。
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.bodyHeight,
    required this.body,
    this.titleAction,
    this.footer,
    super.key,
  });

  final String title;

  /// 计划的内容高度（不含头部、底部按钮和内边距）。
  final double bodyHeight;

  /// 内容。拿到的是**实际**可用的内容高度：键盘弹出或屏幕矮时会小于
  /// [bodyHeight]，内容自己决定在里面滚动，还是让列表变矮。
  final Widget Function(double bodyHeight) body;

  /// 头部右侧的额外动作（比如时间滚轮的「现在」）。
  final Widget? titleAction;

  /// 固定在弹层底部的按钮，跟着键盘一起上移。
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // 键盘占掉的部分先扣掉：弹层贴底，不扣就会有一截藏在键盘后面。
    final available =
        media.size.height -
        keyboard -
        math.max(media.padding.top, AppLayout.sheetTopGap);
    final bottomInset = keyboard > 0 ? 0.0 : media.padding.bottom;
    final chrome =
        AppLayout.sheetTopPad +
        AppLayout.sheetHeader +
        AppLayout.sheetBottomPad +
        bottomInset +
        (footer == null ? 0 : AppLayout.sheetFooterGap + AppLayout.fieldHeight);
    final bodyH = math.max(
      AppLayout.fieldHeight,
      math.min(bodyHeight, available - chrome),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: chrome + bodyH,
        child: Column(
          children: [
            const SizedBox(height: AppLayout.sheetTopPad),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.sheetGutter,
              ),
              child: SizedBox(
                height: AppLayout.sheetHeader,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppType.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ?titleAction,
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
            ),
            // 内容和底部按钮用同一条左右留白，输入框和按钮不会顶到屏幕边缘。
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.sheetGutter,
              ),
              child: SizedBox(height: bodyH, child: body(bodyH)),
            ),
            if (footer != null) ...[
              const SizedBox(height: AppLayout.sheetFooterGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sheetGutter,
                ),
                child: footer!,
              ),
            ],
            SizedBox(height: AppLayout.sheetBottomPad + bottomInset),
          ],
        ),
      ),
    );
  }
}
