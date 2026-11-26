import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/common/anchor_popover.dart';
import 'package:health_app/ui/common/time_popover.dart';
import 'package:health_app/ui/common/wheel_picker.dart';

/// 打开时间浮层，返回它往回调过的所有值（最后一个是当前选择）。
Future<List<TimeOfDay?>> openTimePopover(
  WidgetTester tester, {
  required TimeOfDay initial,
  required DateTime now,
  Alignment anchorAt = Alignment.topLeft,
}) async {
  final values = <TimeOfDay?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: anchorAt,
          child: Padding(
            padding: const EdgeInsets.only(top: 100, left: 20),
            child: Builder(
              builder: (chip) => TextButton(
                onPressed: () => showTimePopover(
                  chip,
                  anchor: chip,
                  initial: initial,
                  now: now,
                  onChanged: values.add,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return values;
}

void main() {
  test('落点：下方、越界往里推、放不下翻到上方', () {
    const overlay = Size(400, 800);

    // 1. 默认贴在锚点下方，左边缘对齐，中间留 popoverGap
    final below = placePopover(
      anchor: const Rect.fromLTWH(20, 100, 120, 44),
      overlay: overlay,
      width: AppLayout.timePopoverWidth,
      height: AppLayout.timePopoverHeight,
    );
    expect(
      below,
      Rect.fromLTWH(
        20,
        100 + 44 + AppLayout.popoverGap,
        AppLayout.timePopoverWidth,
        AppLayout.timePopoverHeight,
      ),
    );

    // 2. 右边放不下就往里推，留出 popoverInset
    final right = placePopover(
      anchor: const Rect.fromLTWH(340, 100, 60, 44),
      overlay: overlay,
      width: AppLayout.timePopoverWidth,
      height: AppLayout.timePopoverHeight,
    );
    expect(
      right.right,
      overlay.width - AppLayout.popoverInset,
    );

    // 3. 下面放不下就翻到锚点上方，底边离开锚点 popoverGap
    final above = placePopover(
      anchor: const Rect.fromLTWH(20, 700, 120, 44),
      overlay: overlay,
      width: AppLayout.timePopoverWidth,
      height: AppLayout.timePopoverHeight,
    );
    expect(above.bottom, 700 - AppLayout.popoverGap);
  });

  testWidgets('浮层贴在被点的 chip 下方，尺寸就是令牌里的数', (tester) async {
    await openTimePopover(
      tester,
      initial: const TimeOfDay(hour: 13, minute: 35),
      now: DateTime(2026, 1, 15, 15, 4),
    );

    final chip = tester.getRect(find.byType(TextButton));
    final popover = tester.getRect(find.byType(PopoverCard));
    expect(popover.width, AppLayout.timePopoverWidth);
    expect(popover.height, AppLayout.timePopoverHeight);
    expect(popover.left, chip.left);
    expect(popover.top, chip.bottom + AppLayout.popoverGap);
  });

  testWidgets('固定 24 小时制：两列数字，没有上午/下午', (tester) async {
    await openTimePopover(
      tester,
      initial: const TimeOfDay(hour: 21, minute: 7),
      now: DateTime(2026, 1, 15, 15, 4),
    );

    expect(find.byType(WheelPicker), findsNWidgets(2));
    expect(find.text('21'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
    expect(find.text('上午'), findsNothing);
    expect(find.text('下午'), findsNothing);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('滚到哪里就是哪里：没有「确定」，每滚一格就回调', (tester) async {
    final values = await openTimePopover(
      tester,
      initial: const TimeOfDay(hour: 9, minute: 30),
      now: DateTime(2026, 1, 15, 15, 4),
    );

    expect(find.text('确定'), findsNothing);

    // 时列往上推两格：09 → 11
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -88));
    await tester.pumpAndSettle();

    expect(values.last, const TimeOfDay(hour: 11, minute: 30));

    // 分列往上推一格：30 → 31
    await tester.drag(find.byType(CupertinoPicker).last, const Offset(0, -44));
    await tester.pumpAndSettle();
    expect(values.last, const TimeOfDay(hour: 11, minute: 31));
  });

  testWidgets('点「现在」回到当前时刻，滚轮也跟着回位', (tester) async {
    final values = await openTimePopover(
      tester,
      initial: const TimeOfDay(hour: 9, minute: 30),
      now: DateTime(2026, 1, 15, 15, 4),
    );

    await tester.tap(find.text('现在'));
    await tester.pumpAndSettle();

    expect(values.last, isNull);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
  });

  testWidgets('点旁边收起浮层，不再回调新的值', (tester) async {
    final values = await openTimePopover(
      tester,
      initial: const TimeOfDay(hour: 9, minute: 30),
      now: DateTime(2026, 1, 15, 15, 4),
    );
    final before = values.length;

    await tester.tapAt(const Offset(760, 560));
    await tester.pumpAndSettle();

    expect(find.byType(PopoverCard), findsNothing);
    expect(values.length, before);
  });
}
