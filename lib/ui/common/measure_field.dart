import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'kg_input.dart';

/// 带单位的数值输入框：体重 kg、目标体重 kg、身高 cm 都是这一个。
///
/// 三件事在这里定死，页面上不再各写一套：
/// - 高度 [AppLayout.fieldHeight]：和主按钮同高，上下相邻时看起来是一套；
/// - 单位常显：用 suffixIcon 而不是 suffixText（后者只在聚焦/有内容时才画，
///   空框会丢掉单位，同一个控件在两个页面就不一样了）；
/// - 出错只换描边颜色，**不插入错误文字**：那一行由表单放在
///   [AppLayout.errorSlot] 的固定行里（见 [FieldError]）。decoration 的
///   `errorText` 会把输入框本身撑高一行，下面所有东西跟着往下跳。
class MeasureField extends StatelessWidget {
  const MeasureField({
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.unit = 'kg',
    this.invalid = false,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  /// 体重的示例值：和校验文案里的「例如 60.42」是同一个数。
  static const example = '60.42';

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String unit;

  /// 只看颜色：描边转红，高度一点不变。
  final bool invalid;

  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.fieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [KgInputFormatter()],
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: AppType.metric,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? example,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: AppSpace.md),
            child: Align(
              widthFactor: 1,
              alignment: Alignment.centerRight,
              child: Text(unit),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(),
          // 只覆盖出错时的描边；其余状态为 null，交回主题。
          enabledBorder: invalid ? appFieldBorder(AppColor.heart, 1) : null,
          focusedBorder: invalid ? appFieldBorder(AppColor.heart, 2) : null,
          disabledBorder: invalid ? appFieldBorder(AppColor.heart, 1) : null,
        ),
      ),
    );
  }
}

/// 表单的错误行：高度固定，没有错误时也占位。
///
/// 文字最多一行、超出省略——一行就是一行，绝不把下面的按钮往下推。
class FieldError extends StatelessWidget {
  const FieldError({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.errorSlot,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: message == null
            ? null
            : Text(
                message!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySmall.copyWith(color: AppColor.heart),
              ),
      ),
    );
  }
}
