import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/main.dart';
import 'package:health_app/platform/app_intents.dart';
import 'package:health_app/ui/app_model.dart';
import 'package:health_app/ui/format.dart';

const testProfile = Profile(
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

/// 模拟 Android 侧 onNewIntent 打过来的链接
Future<void> sendLink(WidgetTester tester, String uri) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall('open', uri),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage('smalljj/intent', message, (_) {});
  await tester.pumpAndSettle();
}

void main() {
  group('链接解析', () {
    test('体重：带数值和时刻', () {
      final link = parseLink('smalljj://weight?kg=60.4&time=08:00')!;
      expect(link.type, 'weight');
      expect(link['kg'], '60.4');
      expect(link['time'], '08:00');
    });

    test('旧链接 record 仍然有效，归到体重', () {
      final link = parseLink('smalljj://record?slot=evening')!;
      expect(link.type, 'weight');
      expect(link['slot'], 'evening');
    });

    test('百分号编码的中文原话能还原', () {
      final uri = Uri(
        scheme: 'smalljj',
        host: 'food',
        queryParameters: {'meal': 'breakfast', 'text': '两个鸡蛋一杯牛奶'},
      ).toString();
      expect(uri, contains('%'));
      final link = parseLink(uri)!;
      expect(link.type, 'food');
      expect(link['text'], '两个鸡蛋一杯牛奶');
    });

    test('其它 scheme、空链接、未知页面一律忽略', () {
      expect(parseLink(null), isNull);
      expect(parseLink(''), isNull);
      expect(parseLink('https://example.com/?slot=morning'), isNull);
      expect(parseLink('smalljj://nope'), isNull);
    });
  });

  group('语音入口落地', () {
    testWidgets('带数值的体重链接直接落库，撤销可回滚', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(tester, 'smalljj://weight?kg=61.2&time=08:00');

      final entry =
          model.entries.firstWhere((e) => e.weightKg == 61.2);
      expect(clockLabel(entry.date), '08:00');
      expect(find.textContaining('已记'), findsOneWidget);

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(model.entries.any((e) => e.weightKg == 61.2), isFalse);
    });

    testWidgets('一句话饮食直接落库，不用弹表单', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(
        tester,
        Uri(
          scheme: 'smalljj',
          host: 'food',
          queryParameters: {
            'meal': 'lunch',
            'text': '两个鸡蛋一杯牛奶',
          },
        ).toString(),
      );

      final lunch = model.meals.firstWhere((m) => m.slot == MealSlot.lunch);
      expect(lunch.items.length, 2);
      expect(lunch.items.map((i) => i.foodName), containsAll(['鸡蛋', '牛奶']));
      expect(model.facts!.todayIntake, greaterThan(0));
    });

    testWidgets('单位换算：半斤牛肉 = 250 g', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(
        tester,
        Uri(
          scheme: 'smalljj',
          host: 'food',
          queryParameters: {'meal': 'dinner', 'text': '牛肉半斤'},
        ).toString(),
      );

      final dinner = model.meals.firstWhere((m) => m.slot == MealSlot.dinner);
      expect(dinner.items.single.grams, closeTo(250, 0.01));
    });

    testWidgets('查询只播报，不写数据', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      final before = model.repo.tableCounts();
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(tester, 'smalljj://query?what=budget');

      expect(find.textContaining('今天预算'), findsOneWidget);
      expect(model.repo.tableCounts(), before);
    });

    testWidgets('连续两条提示不会永久压在页面上', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(tester, 'smalljj://weight?kg=62');
      await sendLink(tester, 'smalljj://period?action=start');
      expect(find.textContaining('已记'), findsOneWidget);

      // 到点自己走掉，不能永久盖住底部的「保存」
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.textContaining('已记'), findsNothing);
    });

    testWidgets('撤销链接在没有记录时给出提示而不是崩溃', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(tester, 'smalljj://undo');
      expect(find.textContaining('没有可撤销'), findsOneWidget);
    });

    testWidgets('超出合理范围的体重不写库', (tester) async {
      final model = buildModel();
      model.completeOnboarding(draft: testProfile, weightKg: 60);
      await tester.pumpWidget(HealthApp(model: model));
      await tester.pumpAndSettle();

      await sendLink(tester, 'smalljj://weight?kg=9');
      expect(model.entries.length, 1);
      expect(model.entries.single.weightKg, 60);
      expect(find.textContaining('不在 25–300'), findsOneWidget);
    });
  });
}
