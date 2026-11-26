import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/common/wheel_picker.dart';
import 'package:health_app/ui/common/weight_entry.dart';

/// 「就几套字体」这件事得有人守着：字族只有一个、字号只有令牌里那几级，
/// 尤其「时间」和「体重」两颗并排的胶囊，字必须一样。
void main() {
  /// 字号、字重、字族、字距全对上才算同一套字。
  void expectSameType(TextStyle? actual, TextStyle expected) {
    expect(actual?.fontSize, expected.fontSize);
    expect(actual?.fontWeight, expected.fontWeight);
    expect(actual?.fontFamily, expected.fontFamily);
    expect(actual?.letterSpacing, expected.letterSpacing);
  }

  TextStyle? styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style;

  testWidgets('时间胶囊和体重胶囊上的字是同一档', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: WhenChip(
                  dayLabel: '今天',
                  onPickDay: (_) {},
                  timeLabel: '16:23',
                  onPickTime: (_) {},
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: PickChip(
                  label: '62.42',
                  unit: 'kg',
                  onPressed: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expectSameType(styleOf(tester, '今天'), AppType.metric);
    expectSameType(styleOf(tester, '16:23'), AppType.metric);
    expectSameType(styleOf(tester, '62.42'), AppType.metric);
    // 单位跟着小字那一档走，两处一致。
    expectSameType(styleOf(tester, 'kg'), AppType.bodySmall);
  });

  testWidgets('三只浮层的滚轮都是同一档字，单位是小字', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: WheelPicker(
                  count: 3,
                  controller: FixedExtentScrollController(),
                  label: (index) => '${index + 1}',
                  suffix: (_) => '日',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final items = tester.widgetList<Text>(find.byType(Text));
    expect(items, isNotEmpty);
    for (final item in items) {
      final isSuffix = item.data == '日';
      expectSameType(
        item.style,
        isSuffix ? AppType.bodySmall : AppType.metric,
      );
      expect(item.style?.fontSize, isSuffix ? 13.0 : 20.0);
    }

    // 选中行不许被放大：放大 1.08 倍之后真机上量到的字高比胶囊里的大 4px。
    final picker = tester.widget<CupertinoPicker>(find.byType(CupertinoPicker));
    expect(picker.useMagnifier, isFalse);
    expect(picker.magnification, 1.0);
  });

  test('字族和字号只在 tokens.dart 里定，组件里不写', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('theme/tokens.dart')) continue;
      final source = entity.readAsStringSync();
      // 字族：任何地方再写一次 `fontFamily:` 就是出现了第二套字。
      // 字号：写死 fontSize 就是绕过阶梯自造一级。
      if (source.contains('fontFamily:')) offenders.add('${entity.path} fontFamily');
      if (source.contains('fontSize:')) offenders.add('${entity.path} fontSize');
    }
    expect(offenders, isEmpty);
  });
}
