import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/ui/format.dart';

void main() {
  final today = DateTime(2026, 1, 15, 15, 35);

  test('胶囊里的日期：今天 / 昨天 / 前天照旧，更早的写成 M/d', () {
    // 胶囊和输入框并排，宽度写死 156：这里不能出现「9月28日」。
    expect(compactDay(today, today), '今天');
    expect(compactDay(DateTime(2026, 1, 14, 8), today), '昨天');
    expect(compactDay(DateTime(2026, 1, 13, 8), today), '前天');

    expect(compactDay(DateTime(2026, 1, 12), today), '1/12');
    expect(compactDay(DateTime(2025, 9, 28), today), '9/28');
    expect(compactDay(DateTime(2025, 12, 31), today), '12/31');

    // 跨年、跨月都按日历天数算，不是按小时。
    expect(compactDay(DateTime(2025, 12, 31, 23), DateTime(2026, 1, 1, 0, 5)), '昨天');
  });

  test('其余格式化：时钟补零、体重两位小数、身高不带多余小数', () {
    expect(clockLabel(DateTime(2026, 1, 15, 9, 5)), '09:05');
    expect(clockLabel(DateTime(2026, 1, 15, 23, 59)), '23:59');
    expect(kgLabel(60.5), '60.50');
    expect(kgLabel(59.999), '60.00');
    expect(heightLabel(165), '165');
    expect(heightLabel(165.4), '165.4');
    expect(monthDayLabel(DateTime(2026, 9, 28)), '9月28日');
  });
}
