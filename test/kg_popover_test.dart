import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/common/anchor_popover.dart';
import 'package:health_app/ui/common/kg_popover.dart';

/// 打开体重浮层，返回它往回调过的所有值（最后一个是当前选择）。
Future<List<double>> openKgPopover(
  WidgetTester tester, {
  required double initial,
  double? last,
}) async {
  final values = <double>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 100, left: 20),
            child: Builder(
              builder: (chip) => TextButton(
                onPressed: () => showKgPopover(
                  chip,
                  anchor: chip,
                  initial: initial,
                  last: last,
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

/// 把某一列往上推 [steps] 格（一格 = 一行 = 1 kg 或 0.01 kg）。
Future<void> roll(WidgetTester tester, int column, int steps) async {
  await tester.drag(
    find.byType(CupertinoPicker).at(column),
    Offset(0, -AppLayout.wheelRow * steps),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('体重浮层：整数列一格 1 kg，小数列一格 0.01 kg', (tester) async {
    final values = await openKgPopover(tester, initial: 60.42);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    // 尺寸就是令牌里的数：和日期 / 时间浮层同一套壳
    final card = tester.getRect(find.byType(PopoverCard));
    expect(
      card.size,
      const Size(AppLayout.kgPopoverWidth, AppLayout.kgPopoverHeight),
    );

    await roll(tester, 0, 1);
    expect(values.last, 61.42);

    await roll(tester, 1, 8);
    expect(values.last, 61.5);
  });

  testWidgets('上限 300：滚到 300 时小数只剩 00，越不过 300', (tester) async {
    // 起点就在 300：小数那列只有一格，滚也滚不动
    final values = await openKgPopover(tester, initial: 300);
    expect(find.text('300'), findsOneWidget);
    await roll(tester, 1, 3);
    expect(values, isEmpty);
    expect(find.text('00'), findsOneWidget);

    // 收起，再从头开一个：299.99 往上推一格整数 = 300.00，小数被夹回 00
    await tester.tapAt(const Offset(600, 500));
    await tester.pumpAndSettle();
    final up = await openKgPopover(tester, initial: 299.99);
    await roll(tester, 0, 1);
    expect(up.last, 300);
    expect(find.text('00'), findsOneWidget);
  });

  testWidgets('下限 25：最轻就到 25.00', (tester) async {
    final values = await openKgPopover(tester, initial: 25);
    await roll(tester, 0, -3);
    expect(values, isEmpty);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('「上次」跳回最近一次记过的值，没有历史就不摆这个按钮', (tester) async {
    final values = await openKgPopover(tester, initial: 60.42, last: 58.5);
    await roll(tester, 0, 5);
    expect(values.last, 65.42);

    await tester.tap(find.text('上次'));
    await tester.pumpAndSettle();
    expect(values.last, 58.5);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);

    await tester.tapAt(const Offset(600, 500));
    await tester.pumpAndSettle();
    expect(find.byType(PopoverCard), findsNothing);

    await openKgPopover(tester, initial: 60.42);
    expect(find.text('上次'), findsNothing);
  });
}
