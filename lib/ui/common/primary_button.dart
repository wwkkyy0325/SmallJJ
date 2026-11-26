import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 主操作按钮：撑满一行、和输入框同高。
///
/// 颜色、圆角、文字都来自主题的 FilledButtonTheme，这里只统一「宽度和高度」，
/// 免得每个页面各自写 `styleFrom(minimumSize: ...)` 弄出三种高度。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppLayout.fieldHeight,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
