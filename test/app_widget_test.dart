import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/main.dart';
import 'package:health_app/ui/app_model.dart';
import 'package:health_app/ui/format.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/common/anchor_popover.dart';
import 'package:health_app/ui/common/surface_card.dart';
import 'package:health_app/ui/common/weight_entry.dart';

const testProfile = Profile(
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
);

AppModel buildModel() => AppModel(
      HealthRepository(
        openTestDatabase(),
        clock: () => DateTime(2026, 1, 15, 15),
      ),
    );

/// 首屏现在是「热量（上）+ 体重（下）」两张卡：默认 800×600 的测试窗口装不下
/// 整页，体重框和「保存」会落到窗口外，tap 打不中。这里把窗口拉高到 800×1000
/// （DPR 仍是 3，和真机一致），整页一屏可见；宽度没变，坐标断言照旧。
void _usePhoneWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// 打开体重浮层，把整数列推 [whole] 格（1 kg）、小数列推 [cents] 格（0.01 kg），
/// 再点浮层外面收起。体重没有输入框了，「记某个数」只能这么走。
Future<void> pickKg(WidgetTester tester, {int whole = 0, int cents = 0}) async {
  await tester.tap(find.byType(PickChip));
  await tester.pumpAndSettle();
  if (whole != 0) {
    await tester.drag(
      find.byType(CupertinoPicker).first,
      Offset(0, -AppLayout.wheelRow * whole),
    );
    await tester.pumpAndSettle();
  }
  if (cents != 0) {
    await tester.drag(
      find.byType(CupertinoPicker).at(1),
      Offset(0, -AppLayout.wheelRow * cents),
    );
    await tester.pumpAndSettle();
  }
  await tester.tapAt(const Offset(8, 8));
  await tester.pumpAndSettle();
}

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

    // 页脚只承诺「活动量按轻度」：功能里没有目标，文案也不许提
    expect(find.textContaining('活动量先按「轻度」算'), findsOneWidget);
    expect(find.textContaining('目标'), findsNothing);

    // 引导只问四项，体重不预填，用户自己敲
    await tester.enterText(find.byType(TextField).last, '60');
    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    // 引导完成后进主页：首屏是「今天」，体重卡直接能填
    expect(find.text('今天'), findsWidgets);
    expect(find.text('今日摄入'), findsOneWidget);
    expect(find.textContaining('现在'), findsOneWidget);
    expect(model.onboarded, isTrue);
    expect(model.entries.first.weightKg, 60);
  });

  testWidgets('第一次只填四项，其余资料在「我的」里改', (tester) async {
    final model = buildModel();
    await tester.pumpWidget(HealthApp(model: model));

    // 活动量/目标不在引导里拦人
    expect(find.text('日常活动量'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).last, '60.42');
    await tester.dragUntilVisible(
      find.text('开始'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('日常活动量'), findsOneWidget);
    // 没有目标：不问减脂/增重，也不问目标体重和每周速率
    expect(find.text('目标'), findsNothing);
    expect(find.text('目标体重'), findsNothing);

    // 身体资料只有出生年和身高，改身高不动已经记下的体重
    await tester.enterText(find.byType(TextField).at(1), '170');
    await tester.ensureVisible(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(model.profile!.heightCm, 170);
    expect(model.entries.first.weightKg, 60.42);
  });

  testWidgets('首屏记一次体重，时间就是现在', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    // 首屏第二张卡是体重填写，引导里记的 60 显示为 60.00
    expect(find.textContaining('60.00'), findsWidgets);

    await pickKg(tester, cents: 83);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(model.entries.first.weightKg, 60.83);
    expect(model.entries.first.date.hour, 15);
    expect(find.textContaining('60.83'), findsWidgets);
  });

  testWidgets('一条饮食都没记时只写「今天还没记饮食」，不报差值', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    expect(find.text('今日摄入'), findsOneWidget);
    expect(find.text('今天还没记饮食'), findsOneWidget);
    // 早上八点「比估算消耗少 1953」只是噪音，不许出现
    expect(find.textContaining('比估算消耗'), findsNothing);
  });

  testWidgets('热量卡：大数字是今日摄入，条子按估算消耗算，不给红绿评价', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    // 一碗米饭 150 g ≈ 174 kcal
    model.repo.addMealItem(
      localDate: model.todayKey,
      slot: MealSlot.lunch,
      food: model.repo.searchFoods('米饭').first,
      grams: 150,
    );
    model.reload();
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    final intake = model.facts!.todayIntake;
    final tdee = model.target!.tdee;
    expect(intake, greaterThan(0));

    expect(find.text('今日摄入'), findsOneWidget);
    expect(find.text('估算消耗 ${kcalLabel(tdee)}'), findsOneWidget);
    expect(find.text(kcalLabel(intake)), findsOneWidget);

    // 进度条：整条是估算消耗，填充是已摄入；没有红绿，也没有预算刻度
    final bar = tester.widget<ProgressBar>(find.byType(ProgressBar));
    expect(bar.value, closeTo(intake / tdee, 1e-9));

    // 差值只用一句话说方向，不写成「缺口」
    final gap = (tdee - intake).round();
    expect(find.text('比估算消耗少 $gap kcal'), findsOneWidget);
    final big = tester.widget<Text>(find.text(kcalLabel(intake)));
    expect(big.style!.color, isNot(AppColor.heart));
  });

  testWidgets('吃超估算消耗也不翻红，只说「比估算消耗多」', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    // 1600 g 米饭 ≈ 1856 kcal，超过公式 TDEE 1815 kcal
    model.repo.addMealItem(
      localDate: model.todayKey,
      slot: MealSlot.lunch,
      food: model.repo.searchFoods('米饭').first,
      grams: 1600,
    );
    model.reload();
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    final intake = model.facts!.todayIntake;
    final over = (intake - model.target!.tdee).round();
    expect(find.text('比估算消耗多 $over kcal'), findsOneWidget);
    expect(find.text('今日摄入'), findsOneWidget);

    // 条子满格，但不换颜色：多吃了不是错误
    final bar = tester.widget<ProgressBar>(find.byType(ProgressBar));
    expect(bar.value, 1.0);

    final big = tester.widget<Text>(find.text(kcalLabel(intake)));
    expect(big.style!.color, isNot(AppColor.heart));
  });

  testWidgets('体重是滚轮选出来的两位小数，第三位根本不存在', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    // 小数那一列一格就是 0.01 kg：能选出来的最小单位是两位小数，
    // 所以「第三位被过滤掉」这种事在这里不会发生——没有输入框可打字。
    await pickKg(tester, cents: 23);
    expect(find.text('60.23'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = model.entries.first;
    expect(saved.localDate, model.todayKey);
    expect(saved.weightKg, 60.23);
  });

  testWidgets('和上次差超过 3 kg 时先确认，取消就不落库', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    // 60 → 100：整数列推 40 格，和上一条差 40 kg，保存前先确认
    await pickKg(tester, whole: 40);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('确认这个体重'), findsOneWidget);
    await tester.tap(find.text('改一下'));
    await tester.pumpAndSettle();
    expect(model.entries.length, 1);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('就是这个数'));
    await tester.pumpAndSettle();
    expect(model.entries.first.weightKg, 100);
  });

  testWidgets('首屏时间入口是 24 小时滚轮：改小时就按那个时间落库', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    await tester.tap(find.text('现在 15:00'));
    await tester.pumpAndSettle();
    expect(find.byType(PopoverCard), findsOneWidget);

    // 时列往上推一格：15 → 16（滚轮往上推是往后走）
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -44));
    await tester.pumpAndSettle();
    // 没有「确定」：chip 上的字已经变了，点旁边收起就是完成
    expect(find.text('确定'), findsNothing);
    await tester.tapAt(const Offset(760, 560));
    await tester.pumpAndSettle();
    expect(find.text('16:00'), findsOneWidget);

    await pickKg(tester, cents: 20);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final entry = model.entries.firstWhere((e) => e.weightKg == 60.2);
    expect(entry.date.hour, 16);
    expect(entry.date.minute, 0);
  });

  testWidgets('添加食物后今日摄入增加', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
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

  testWidgets('克数填错时不显示 0 kcal，「添加」点不动', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    await tester.tap(find.text('饮食').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '两个鸡蛋');
    await tester.pumpAndSettle();
    await tester.tap(find.text('鸡蛋').last);
    await tester.pumpAndSettle();

    // 克数清空：标签说清楚，而不是算出一个 0 kcal 的食物
    await tester.enterText(find.byType(TextField).last, '');
    await tester.pumpAndSettle();
    expect(find.textContaining('克数没填对'), findsOneWidget);
    final disabled = tester.widget<FilledButton>(
      find.ancestor(of: find.text('添加'), matching: find.byType(FilledButton)),
    );
    expect(disabled.onPressed, isNull);

    // 填回去就能加
    await tester.enterText(find.byType(TextField).last, '50');
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(model.meals.first.items, isNotEmpty);
  });

  testWidgets('体重页「记一笔」和首屏是同一个表单：空框、同样式、能撤销', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    // 首屏那颗体重胶囊：值 + 单位都在胶囊上，不是输入框
    final onToday = tester.widget<PickChip>(find.byType(PickChip));
    expect(onToday.label, '60.00');
    expect(onToday.unit, 'kg');

    await tester.tap(find.text('体重').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();

    // 弹层里是同一个控件：没有第二套输入框/按钮，连一个 TextField 都没有
    expect(find.byType(WeightEntryForm), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final inSheet = tester.widget<PickChip>(find.byType(PickChip));
    expect(inSheet.label, onToday.label);
    expect(inSheet.unit, onToday.unit);

    await pickKg(tester, cents: 50);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('记体重'), findsNothing);
    expect(model.entries.first.weightKg, 60.5);
    expect(find.textContaining('已记 今天'), findsOneWidget);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(model.entries.first.weightKg, 60);
  });

  testWidgets('改已有的一条，撤销是把原值写回，不是删掉记录', (tester) async {
    final model = buildModel();
    _usePhoneWindow(tester);
    model.completeOnboarding(draft: testProfile, weightKg: 60);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    await tester.tap(find.text('体重').last);
    await tester.pumpAndSettle();
    final count = model.entries.length;

    final tile = find.widgetWithText(ListTile, '今天 15:00').first;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // 改的时候标题是「改体重」，胶囊预填原值（只有编辑才预填）
    expect(find.text('改体重'), findsOneWidget);
    expect(tester.widget<PickChip>(find.byType(PickChip)).label, '60.00');

    await pickKg(tester, cents: 80);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(model.entries.length, count);
    expect(model.entries.first.weightKg, 60.8);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(model.entries.length, count);
    expect(model.entries.first.weightKg, 60);
  });
}
