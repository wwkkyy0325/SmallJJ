import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/domain/food_parse.dart';

void main() {
  test('连写多条：「两个鸡蛋一杯牛奶」拆成两条', () {
    final mentions = parseFoodText('两个鸡蛋一杯牛奶');
    expect(mentions.map((m) => m.name).toList(), ['鸡蛋', '牛奶']);
    expect(mentions[0].quantity, 2);
    expect(mentions[0].unit, '个');
    expect(mentions[1].quantity, 1);
    expect(mentions[1].unit, '杯');
  });

  test('数量在后：「米饭一碗」', () {
    final mentions = parseFoodText('米饭一碗');
    expect(mentions.single.name, '米饭');
    expect(mentions.single.gramsWith(150), 150);
  });

  test('绝对重量优先：「鸡胸肉 150 克」', () {
    final mentions = parseFoodText('鸡胸肉 150 克');
    expect(mentions.single.name, '鸡胸肉');
    expect(mentions.single.gramsWith(100), 150);
  });

  test('毫升按 1 g/ml 近似：「牛奶250ml」', () {
    final mentions = parseFoodText('牛奶250ml');
    expect(mentions.single.gramsWith(250), 250);
  });

  test('斤 / 两 换算', () {
    expect(parseFoodText('牛肉半斤').single.gramsWith(100), 250);
    expect(parseFoodText('二两米饭').single.gramsWith(150), 100);
  });

  test('「两」当数字用：「两个苹果」', () {
    final mentions = parseFoodText('两个苹果');
    expect(mentions.single.quantity, 2);
    expect(mentions.single.unit, '个');
    expect(mentions.single.gramsWith(200), 400);
  });

  test('没有数量词时按一份算', () {
    final mentions = parseFoodText('拿铁');
    expect(mentions.single.quantity, 1);
    expect(mentions.single.unit, isNull);
    expect(mentions.single.gramsWith(350), 350);
  });

  test('十二 / 半 这类数字', () {
    expect(parseFoodText('十二个饺子').single.quantity, 12);
    expect(parseFoodText('半碗米饭').single.quantity, 0.5);
  });

  test('分隔符（逗号、和）也能切', () {
    final mentions = parseFoodText('鸡蛋2个，牛奶1杯和香蕉1根');
    expect(mentions.map((m) => m.name).toList(), ['鸡蛋', '牛奶', '香蕉']);
  });
}
