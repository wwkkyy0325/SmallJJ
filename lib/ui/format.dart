/// 界面上的日期/数字格式化。只有中文习惯的一种写法，不做本地化框架。
String weekdayLabel(DateTime date) =>
    const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];

String monthDayLabel(DateTime date) => '${date.month}月${date.day}日';

String fullDateLabel(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日 ${weekdayLabel(date)}';

String kcalLabel(double kcal) => '${kcal.round()}';

String kgLabel(double kg) => kg.toStringAsFixed(1);

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
