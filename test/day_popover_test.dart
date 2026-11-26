import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/ui/common/day_popover.dart';

/// 日期滚轮的方向语义，以及「今天之后滚不到」这条约束。
///
/// 这条测试是补上一个真实踩过的坑：浮层打开时「日」列停在**最后一行**
/// （今天），所以手指向上推（往后翻）永远没反应——那不是 bug，是未来日期
/// 不可选。要往回改日期，手指得向下拖。上一轮把这个当成了「滚轮拖不动」。
void main() {
  final now = DateTime(2026, 1, 15, 15);

  Future<List<DateTime>> open(WidgetTester tester) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDayPopover(
                  context,
                  anchor: context,
                  initial: DateTime(2026, 1, 15),
                  onChanged: picked.add,
                  now: now,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('三列都在，初始停在今天', (tester) async {
    await open(tester);
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('1月'), findsOneWidget);
    expect(find.text('15日'), findsOneWidget);
  });

  testWidgets('手指向上推（未来）夹住不动，不回调', (tester) async {
    final picked = await open(tester);
    await tester.drag(find.byType(CupertinoPicker).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    expect(find.text('15日'), findsOneWidget);
  });

  testWidgets('手指向下拖能往回改日期', (tester) async {
    final picked = await open(tester);
    await tester.drag(find.byType(CupertinoPicker).last, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(picked, isNotEmpty);
    expect(picked.last.isAfter(DateTime(2026, 1, 15)), isFalse);
    expect(picked.last.day, lessThan(15));
  });

  testWidgets('点「今天」把三列都拉回今天', (tester) async {
    final picked = await open(tester);
    await tester.drag(find.byType(CupertinoPicker).last, const Offset(0, 200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(find.text('15日'), findsOneWidget);
    expect(find.text('1月'), findsOneWidget);
    expect(picked.last, DateTime(2026, 1, 15));
  });
}
