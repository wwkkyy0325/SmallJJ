/// 界面上的日期/数字格式化。只有中文习惯的一种写法，不做本地化框架。
String weekdayLabel(DateTime date) =>
    const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];

String monthDayLabel(DateTime date) => '${date.month}月${date.day}日';

String fullDateLabel(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日 ${weekdayLabel(date)}';

/// 胶囊里的日期：比 [relativeDay] 更短。
///
/// 日期和时间挤在同一颗胶囊里，宽度是写死的（156），
/// 所以「9月28日」在这里写成「9/28」；今天 / 昨天 / 前天照旧。
String compactDay(DateTime date, DateTime today) {
  final label = relativeDay(date, today);
  return label.endsWith('日') ? '${date.month}/${date.day}' : label;
}

String kcalLabel(double kcal) => '${kcal.round()}';

/// 体重：固定两位小数（0.01 kg），和录入精度一致。
String kgLabel(double kg) => kg.toStringAsFixed(2);

/// 身高：整数就不带小数，避免「165.00 cm」这种读起来别扭的写法。
String heightLabel(double cm) =>
    cm == cm.roundToDouble() ? cm.toStringAsFixed(0) : cm.toStringAsFixed(1);

String clockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String signed(double value, {int digits = 1}) {
  final text = value.abs().toStringAsFixed(digits);
  return value > 0
      ? '+$text'
      : value < 0
      ? '-$text'
      : text;
}

String relativeDay(DateTime date, DateTime today) {
  final diff = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff == 2) return '前天';
  return monthDayLabel(date);
}
