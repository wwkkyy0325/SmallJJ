import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 打开对话框。
///
/// 宽度上限、左右留白、形状、按钮高度都由主题和这里定，业务只给标题、内容和
/// 按钮；内容超长时在整个对话框里滚动，不会把按钮挤出屏幕。
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidth),
      title: Text(title),
      content: content,
      scrollable: true,
      actions: actions,
    ),
  );
}

/// 对话框里的按钮：高度固定，文字长短换不来高度变化。
class DialogAction extends StatelessWidget {
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.dialogAction,
      child: primary
          ? FilledButton(onPressed: onPressed, child: Text(label))
          : TextButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
