import 'package:flutter/services.dart';

/// 体重输入框的限制：最多 3 位整数、最多 2 位小数，只允许一个小数点。
///
/// 不用 [FilteringTextInputFormatter]：它是「删掉不匹配的字符」，
/// 输到第三位小数时会把那一位悄悄吞掉，光标位置也跟着跳。
/// 这里整串校验，不合法就保持原值，用户看到的是「敲不进去」。
class KgInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d{0,3}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 中文输入法/数字键盘可能给出全角逗号或句号，先折成小数点。
    final text = newValue.text
        .replaceAll('。', '.')
        .replaceAll('，', '.')
        .replaceAll(',', '.');
    if (text.isEmpty) {
      return newValue.copyWith(text: text, selection: newValue.selection);
    }
    if (!_pattern.hasMatch(text)) return oldValue;
    if (text == newValue.text) return newValue;
    return newValue.copyWith(
      text: text,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
