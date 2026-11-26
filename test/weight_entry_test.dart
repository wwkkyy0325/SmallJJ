import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/app_model.dart';
import 'package:health_app/ui/common/weight_entry.dart';

/// 胶囊 = 「上一次的值」这件事的回归测试。
///
/// 首屏那张卡常驻在 IndexedStack 里，State 不会因为切页而重建，所以
/// 「起点是上次的值」既要对第一次挂载成立，也要对别处改了数据之后成立。

const _profile = Profile(
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
  goalMode: 'lose',
  goalRateKgWeek: 0.5,
  goalWeightKg: 58,
);

AppModel _buildModel() => AppModel(
  HealthRepository(openTestDatabase(), clock: () => DateTime(2026, 1, 15, 15)),
);

Future<AppModel> _pumpForm(WidgetTester tester) async {
  final model = _buildModel();
  // 引导页那一步会写下第一条体重（= 「上一次的值」），胶囊的起点该是它，
  // 不是 60 这个兜底值。
  model.completeOnboarding(draft: _profile, weightKg: 60.4);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: WeightEntryForm(model: model))),
  );
  await tester.pumpAndSettle();
  return model;
}

void main() {
  testWidgets('胶囊起点是最近一次记过的值', (tester) async {
    await _pumpForm(tester);
    expect(find.text('60.40'), findsOneWidget);
  });

  testWidgets('别处记了新体重，没动过的胶囊跟着变', (tester) async {
    final model = await _pumpForm(tester);

    // 相当于在体重页 / 语音入口 / 撤销条里动数据：只走仓储，不碰这张卡。
    model.saveWeight(at: DateTime(2026, 1, 15, 18), kg: 61.25);
    await tester.pumpAndSettle();

    expect(find.text('61.25'), findsOneWidget);
    expect(find.text('60.40'), findsNothing);
  });

  testWidgets('最近一条被删掉，胶囊退回再前一条', (tester) async {
    final model = await _pumpForm(tester);
    final id = model.saveWeight(at: DateTime(2026, 1, 15, 18), kg: 61.25);
    await tester.pumpAndSettle();
    expect(find.text('61.25'), findsOneWidget);

    model.deleteWeight(id);
    await tester.pumpAndSettle();
    expect(find.text('60.40'), findsOneWidget);
  });

  testWidgets('用户滚过之后，别处的记录不冲掉这次的选择', (tester) async {
    final model = await _pumpForm(tester);

    await tester.tap(find.byType(PickChip));
    await tester.pumpAndSettle();
    // 整数列往上推一格 = +1 kg。
    await tester.drag(
      find.byType(CupertinoPicker).first,
      const Offset(0, -AppLayout.wheelRow),
    );
    await tester.pumpAndSettle();
    expect(find.text('61'), findsOneWidget);
    await tester.tapAt(const Offset(600, 20));
    await tester.pumpAndSettle();
    expect(find.text('61.40'), findsOneWidget);

    model.saveWeight(at: DateTime(2026, 1, 15, 18), kg: 70);
    await tester.pumpAndSettle();

    expect(find.text('61.40'), findsOneWidget);
    expect(find.text('70.00'), findsNothing);
  });

  testWidgets('点开浮层时滚轮停在胶囊上的那个数', (tester) async {
    await _pumpForm(tester);
    await tester.tap(find.byType(PickChip));
    await tester.pumpAndSettle();

    final picker = find.byType(CupertinoPicker);
    expect(
      tester.widget<CupertinoPicker>(picker.first).scrollController!
          .initialItem,
      60 - 25,
    );
    expect(
      tester.widget<CupertinoPicker>(picker.last).scrollController!.initialItem,
      40,
    );
  });
}
