/// 体重的唯一口径：单位 kg，保留两位小数。
///
/// 秤能给出的分辨率和用户手输的上限都是 0.01 kg；显示的位数、落库的值、
/// 比较的阈值都从这里取，避免「界面 60.42、库里 60.419999」这种账。
library;

/// 允许录入的体重范围（kg）。低于 25 多半是没填单位/打错位。
const double minWeightKg = 25;
const double maxWeightKg = 300;

/// 四舍五入到两位小数。0.005 这类二进制尾巴在这一步被削掉。
double normalizeKg(double kg) => (kg * 100).roundToDouble() / 100;

/// 把用户输入/语音带进来的文字解析成 kg。
///
/// 接受 `60.42`、`60,42`（逗号当小数点）、`60.42kg`、`60.42 公斤`。
/// 解析不了、或逗号被当成千分位（`1,234`）时返回 null，不猜。
double? parseWeightInput(String raw) {
  var text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'\s+'), '');
  text = text
      .replaceAll('公斤', '')
      .replaceAll('千克', '')
      .replaceAll('kg', '');
  // 「63,5」是欧洲写法的小数点；「1,234」是千分位，后者解析失败即拒绝。
  text = text.replaceAll('，', '.').replaceAll(',', '.');
  if (text.contains('.') && text.split('.').length > 2) return null;
  final value = double.tryParse(text);
  if (value == null) return null;
  return normalizeKg(value);
}

/// 保存前的校验文案。null 表示可以保存。
String? weightInputError(double? kg) {
  if (kg == null) return '请输入体重数字，例如 60.42';
  if (kg < minWeightKg || kg > maxWeightKg) {
    return '体重需在 25–300 kg 之间';
  }
  return null;
}
