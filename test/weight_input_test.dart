import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/domain/weight_input.dart';
import 'package:health_app/ui/common/kg_input.dart';
import 'package:health_app/ui/format.dart';

void main() {
  test('体重显示固定两位小数', () {
    expect(kgLabel(60), '60.00');
    expect(kgLabel(60.4), '60.40');
    expect(kgLabel(60.42), '60.42');
    expect(kgLabel(60.429), '60.43'); // 四舍五入，不截断
  });

  test('归一化：两位小数之外的部分被削掉', () {
    expect(normalizeKg(60), 60);
    expect(normalizeKg(60.4), 60.4);
    expect(normalizeKg(60.426), 60.43);
    expect(normalizeKg(70 - 3 * 0.1), 69.7); // 69.70000000000002 → 69.7
  });

  test('输入解析：兼容逗号小数点、单位后缀和空格', () {
    expect(parseWeightInput('60.42'), 60.42);
    expect(parseWeightInput(' 60.4 '), 60.4);
    expect(parseWeightInput('60,42'), 60.42);
    expect(parseWeightInput('60.42kg'), 60.42);
    expect(parseWeightInput('60.42 公斤'), 60.42);
    expect(parseWeightInput('60.426'), 60.43);
    expect(parseWeightInput(''), isNull);
    expect(parseWeightInput('轻了'), isNull);
    expect(parseWeightInput('60.4.2'), isNull);
  });

  test('范围校验：25–300 kg 之外不给保存', () {
    expect(weightInputError(null), isNotNull);
    expect(weightInputError(24.99), isNotNull);
    expect(weightInputError(300.01), isNotNull);
    expect(weightInputError(25), isNull);
    expect(weightInputError(300), isNull);
    expect(weightInputError(60.42), isNull);
  });

  test('输入格式化：最多三位整数、两位小数，第三位敲不进去', () {
    final formatter = KgInputFormatter();
    TextEditingValue format(String old, String next) => formatter
        .formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: next),
        );

    expect(format('', '60.42').text, '60.42');
    expect(format('60.4', '60.42').text, '60.42');
    expect(format('60.42', '60.425').text, '60.42');
    expect(format('60.42', '60.42.1').text, '60.42');
    expect(format('60.42', '60.42a').text, '60.42');
    expect(format('', '1234').text, '');
    expect(format('', '60,4').text, '60.4');
    expect(format('', '60。4').text, '60.4');
  });
}
