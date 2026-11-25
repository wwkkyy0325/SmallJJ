import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/main.dart';
import 'package:health_app/ui/app_model.dart';

const testProfile = Profile(
  sex: 'female',
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
  goalMode: 'lose',
  goalRateKgWeek: 0.5,
  goalWeightKg: 58,
);

AppModel buildModel() => AppModel(
      HealthRepository(
        openTestDatabase(),
        clock: () => DateTime(2026, 1, 15, 15),
      ),
    );

void main() {
  testWidgets('首次启动进入引导，填完资料后进入今天页', (tester) async {
    final model = buildModel();
    await tester.pumpWidget(HealthApp(model: model));

    expect(find.text('SmallJJ 健康'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('开始'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('开始'), findsOneWidget);

    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    // 引导完成后进主页：首屏是「今天」，预算与早晚两次入口都在
    expect(find.text('今天'), findsWidgets);
    expect(find.text('今天还能吃'), findsOneWidget);
    expect(find.text('早上'), findsOneWidget);
    expect(find.text('晚上'), findsOneWidget);
    expect(model.onboarded, isTrue);
    expect(model.morningEntry, isNotNull);
  });

  testWidgets('记录晚上体重后首屏显示新数值', (tester) async {
    final model = buildModel();
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    expect(find.textContaining('60.0 kg'), findsWidgets);

    await tester.tap(find.text('晚上'));
    await tester.pumpAndSettle();
    expect(find.text('记录体重'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '60.8');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(model.eveningEntry, isNotNull);
    expect(find.textContaining('60.8 kg'), findsWidgets);
  });

  testWidgets('添加食物后今日摄入增加', (tester) async {
    final model = buildModel();
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    await tester.tap(find.text('饮食').last);
    await tester.pumpAndSettle();

    // 早餐卡片上的添加按钮
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '两个鸡蛋');
    await tester.pumpAndSettle();
    await tester.tap(find.text('鸡蛋').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    expect(model.meals.first.items, isNotEmpty);
    expect(model.facts!.todayIntake, greaterThan(0));
  });
}
