import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/models.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/main.dart';
import 'package:health_app/theme/app_theme.dart';
import 'package:health_app/theme/tokens.dart';
import 'package:health_app/ui/app_model.dart';
import 'package:health_app/ui/common/anchor_popover.dart';
import 'package:health_app/ui/common/app_nav_bar.dart';
import 'package:health_app/ui/common/app_sheet.dart';
import 'package:health_app/ui/common/primary_button.dart';
import 'package:health_app/ui/common/surface_card.dart';
import 'package:health_app/ui/common/weight_entry.dart';

/// 位置固定这件事的回归测试：这些断言量的是「坐标」，不是「长什么样」。

const _profile = Profile(
  birthYear: 1996,
  heightCm: 165,
  activityLevel: 'light',
);

AppModel _buildModel() => AppModel(
  HealthRepository(openTestDatabase(), clock: () => DateTime(2026, 1, 15, 15)),
);

/// 首屏现在是「热量（上）+ 体重（下）」两张卡：默认 800×600 的测试窗口装不下
/// 整页，体重框和「保存」会落到窗口外，tap 打不中。这里把窗口拉高到 800×1000
/// （DPR 仍是 3，和真机一致），整页一屏可见；宽度没变，坐标断言照旧。
void _usePhoneWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<AppModel> _pumpOnboarded(WidgetTester tester) async {
  _usePhoneWindow(tester);
  final model = _buildModel();
  model.completeOnboarding(draft: _profile, weightKg: 60);
  await tester.pumpWidget(HealthApp(model: model));
  await tester.pumpAndSettle();
  return model;
}

/// 弹层的总高度：头部 + 内容 + 底部按钮 + 上下留白，全部来自令牌。
double _sheetHeight({required double bodyHeight, bool footer = false}) =>
    AppLayout.sheetTopPad +
    AppLayout.sheetHeader +
    bodyHeight +
    AppLayout.sheetBottomPad +
    (footer ? AppLayout.sheetFooterGap + AppLayout.fieldHeight : 0);

/// 打开体重浮层，把整数列往上推 [steps] 格（一格 1 kg），再点浮层外面收起。
///
/// 体重没有输入框了：所有「记某个数」的测试都从这里进来，走的就是手指走的路。
Future<void> pickKg(WidgetTester tester, {int steps = 0, int cents = 0}) async {
  await tester.tap(find.byType(PickChip));
  await tester.pumpAndSettle();
  if (steps != 0) {
    await tester.drag(
      find.byType(CupertinoPicker).first,
      Offset(0, -AppLayout.wheelRow * steps),
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
  // 点浮层外面收起：没有「确定」
  await tester.tapAt(const Offset(8, 8));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('一行两颗胶囊：平分、同高，值变了谁都不动', (tester) async {
    await _pumpOnboarded(tester);

    final form = find.byType(WeightEntryForm);
    expect(tester.getSize(form).height, WeightEntryForm.stackedHeight);

    final when = tester.getRect(find.byType(WhenChip));
    final kg = tester.getRect(find.byType(PickChip));
    final save = tester.getRect(find.byType(PrimaryButton));

    // 两个胶囊并排、平分：同高、上下边重合，中间只隔 AppSpace.xs。
    expect(when.height, AppLayout.chipHeight);
    expect(kg.height, AppLayout.chipHeight);
    expect(when.top, kg.top);
    expect(when.width, kg.width);
    expect(kg.left, when.right + AppSpace.xs);
    // 两颗胶囊的外沿和下面的「保存」对齐：一行两个、下面一个，宽度同一套
    expect(when.left, save.left);
    expect(kg.right, save.right);

    // 换一个体重：只有胶囊上的字变
    await pickKg(tester, steps: 5);
    expect(find.text('65.00'), findsOneWidget);
    expect(tester.getRect(find.byType(PickChip)), kg);
    expect(tester.getRect(find.byType(WhenChip)), when);
    expect(tester.getRect(find.byType(PrimaryButton)), save);
    expect(tester.getSize(form).height, WeightEntryForm.stackedHeight);
  });

  testWidgets('日期 + 时间挤进一颗胶囊时，时间半边不被省略号吃掉', (tester) async {
    // 测试字体是方块字（每个字符宽 = 字号），比真机的中文字体宽得多，所以这里
    // 用的宽度是「够宽」的：这条守的不是像素，而是分配规则——日期半边按内容
    // 取宽，时间半边吃掉剩下全部。写成两半平分的话，20sp 的「16:42」在两段
    // 都放下的宽度下也会被截成「16:…」（真机上就是这么暴露的）。
    Future<void> check(String day, double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: WhenChip(
                  dayLabel: day,
                  onPickDay: (_) {},
                  timeLabel: '16:42',
                  onPickTime: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.renderObject<RenderParagraph>(find.text('16:42')).didExceedMaxLines,
        isFalse,
        reason: '时间被截断了（day=$day）',
      );
      expect(
        tester.renderObject<RenderParagraph>(find.text(day)).didExceedMaxLines,
        isFalse,
        reason: '日期被截断了（day=$day）',
      );
    }

    await check('今天', 200);
    await check('12/28', 260);
  });

  testWidgets('时间标签从「现在 15:00」变成「16:00」，两颗胶囊、按钮都不动', (tester) async {
    await _pumpOnboarded(tester);

    final chipBefore = tester.getRect(find.byType(WhenChip));
    final kgBefore = tester.getRect(find.byType(PickChip));
    final saveBefore = tester.getRect(find.byType(PrimaryButton));
    expect(chipBefore.height, AppLayout.chipHeight);
    expect(kgBefore.left, chipBefore.right + AppSpace.xs);

    await tester.tap(find.text('现在 15:00'));
    await tester.pumpAndSettle();

    // 浮层贴着 chip 出现：左边缘对齐、上面留一条缝，尺寸就是令牌里的数
    final popover = tester.getRect(find.byType(PopoverCard));
    expect(popover.left, chipBefore.left);
    expect(popover.top, chipBefore.bottom + AppLayout.popoverGap);
    expect(
      popover.size,
      const Size(AppLayout.timePopoverWidth, AppLayout.timePopoverHeight),
    );

    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -44));
    await tester.pumpAndSettle();
    // 滚一格 chip 上的字就变了，不用再点「确定」
    expect(find.text('16:00'), findsOneWidget);

    await tester.tapAt(const Offset(760, 560));
    await tester.pumpAndSettle();

    expect(find.byType(PopoverCard), findsNothing);
    expect(tester.getRect(find.byType(WhenChip)), chipBefore);
    expect(tester.getRect(find.byType(PickChip)), kgBefore);
    expect(tester.getRect(find.byType(PrimaryButton)), saveBefore);
  });

  testWidgets('补记到别的日子：左胶囊的日期写成 12/31，两颗胶囊宽度都不变', (tester) async {
    _usePhoneWindow(tester);
    final model = _buildModel();
    model.completeOnboarding(draft: _profile, weightKg: 60);
    // 弹层内容宽度：手机 400 宽 - 两边的 sheetGutter。
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400 - AppLayout.sheetGutter * 2,
              child: WeightEntryForm(
                model: model,
                at: DateTime(2025, 12, 31, 9, 5),
                allowDate: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chip = tester.getRect(find.byType(WhenChip));
    final kg = tester.getRect(find.byType(PickChip));
    expect(chip.height, AppLayout.chipHeight);
    // 左胶囊两个半边都在：「12/31」和「09:05」各占一半，谁都不省略
    expect(find.text('12/31'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
    expect(chip.width, kg.width);
    expect(kg.left, chip.right + AppSpace.xs);
    expect(tester.takeException(), isNull);
  });

  testWidgets('体重卡记了第一条之后不长高，上面的热量卡不动', (tester) async {
    _usePhoneWindow(tester);
    final model = _buildModel();
    model.completeOnboarding(draft: _profile, weightKg: 60);
    // 一条记录都没有的初始状态：这时卡片上的两行摘要是占位文字
    model.deleteWeight(model.entries.first.id);
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.byType(WeightEntryForm),
      matching: find.byType(SurfaceCard),
    ).first;
    final before = tester.getRect(card);
    final calorie = find
        .ancestor(
          of: find.text('今日摄入'),
          matching: find.byType(SurfaceCard),
        )
        .first;
    final calorieBefore = tester.getRect(calorie);
    // 顺序：热量卡在上，体重卡在下
    expect(tester.getRect(card).top, greaterThan(calorieBefore.bottom));
    expect(find.text('还没有记录'), findsOneWidget);
    expect(find.text('趋势：两条记录之后显示'), findsOneWidget);

    // 不动胶囊直接保存：没有历史记录时起点是默认的 60.00
    expect(find.text('60.00'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 摘要行换成真实数据，行数没变 → 卡片高度、位置都不变
    expect(find.textContaining('最近 60.00 kg'), findsOneWidget);
    expect(tester.getRect(card), before);
    // 下面的卡长高长矮都不许把上面的热量卡推走
    expect(tester.getRect(calorie), calorieBefore);
  });

  testWidgets('记体重弹层：宽度、高度、贴底位置固定，「记」和「改」一样', (tester) async {
    final model = await _pumpOnboarded(tester);
    final screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    await tester.tap(find.text('体重').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();

    final add = tester.getRect(find.byType(AppSheet));
    expect(add.height, _sheetHeight(bodyHeight: WeightEntryForm.stackedHeight));
    expect(add.width, AppLayout.sheetMaxWidth);
    expect(add.left, (screen - AppLayout.sheetMaxWidth) / 2);
    expect(add.bottom, tester.getRect(find.byType(MaterialApp)).bottom);

    // 弹层里也是两颗胶囊：左边「今天 / 15:00」，右边体重，中间只隔 AppSpace.xs。
    final when = tester.getRect(find.byType(WhenChip));
    final kg = tester.getRect(
      find.descendant(
        of: find.byType(AppSheet),
        matching: find.byType(PickChip),
      ),
    );
    expect(kg.left, when.right + AppSpace.xs);
    expect(when.width, kg.width);
    expect(when.height, AppLayout.chipHeight);
    expect(find.descendant(of: find.byType(WhenChip), matching: find.text('今天')), findsOneWidget);
    expect(
      find.descendant(of: find.byType(WhenChip), matching: find.text('15:00')),
      findsOneWidget,
    );

    // 内容、头部、底部按钮共用一条左右留白：胶囊和按钮都不顶到屏幕边缘。
    final title = tester.getRect(find.text('记体重'));
    final save = tester.getRect(
      find.descendant(
        of: find.byType(AppSheet),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(title.left - add.left, AppLayout.sheetGutter);
    expect(save.left - add.left, AppLayout.sheetGutter);
    expect(add.right - save.right, AppLayout.sheetGutter);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    // 改已有那一条：标题变了、框里预填了原值，弹层还是那个位置那个大小
    final tile = find.widgetWithText(ListTile, '今天 15:00').first;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('改体重'), findsOneWidget);
    expect(tester.getRect(find.byType(AppSheet)), add);
    expect(model.entries.length, 1);
  });

  testWidgets('时间浮层不是弹层：不铺满宽度、不占屏幕下半截', (tester) async {
    await _pumpOnboarded(tester);

    await tester.tap(find.text('现在 15:00'));
    await tester.pumpAndSettle();

    // 以前这里是一个贴底的 AppSheet，现在没有弹层了
    expect(find.byType(AppSheet), findsNothing);

    final screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final popover = tester.getRect(find.byType(PopoverCard));
    expect(popover.width, lessThan(screen / 2));
    expect(popover.height, AppLayout.timePopoverHeight);
    // 表单本身没有被推走：chip 还在原来的位置
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('确认对话框：宽度有上限，按钮高度固定', (tester) async {
    await _pumpOnboarded(tester);

    // 60 → 100：滚轮推 40 格，和上一条差 40 kg，保存前先确认
    await pickKg(tester, steps: 40);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('确认这个体重'), findsOneWidget);
    // AlertDialog / Dialog 自己是铺满全屏的（内边距 + 居中），量标题所在的那层
    // Material：那就是对话框的可见面，宽度受 AppLayout.dialogMaxWidth 限制。
    final surface = tester.getRect(
      find
          .ancestor(
            of: find.text('确认这个体重'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(surface.width, lessThanOrEqualTo(AppLayout.dialogMaxWidth));
    expect(tester.getSize(find.text('就是这个数')).height, greaterThan(0));
    // 两个按钮在同一行，高度由令牌定死
    final ok = tester.getRect(find.ancestor(
      of: find.text('就是这个数'),
      matching: find.byType(FilledButton),
    ));
    expect(ok.height, AppLayout.dialogAction);
  });

  testWidgets('引导页出错只换一行红字，「开始」不动', (tester) async {
    final model = _buildModel();
    await tester.pumpWidget(HealthApp(model: model));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('开始'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    final startBefore = tester.getRect(find.text('开始'));
    await tester.tap(find.text('开始'));
    await tester.pumpAndSettle();

    expect(find.text('请输入体重数字，例如 60.42'), findsOneWidget);
    expect(tester.getRect(find.text('开始')), startBefore);
  });

  testWidgets('底部导航栏定死：切页、键盘、安全区都不动', (tester) async {
    await _pumpOnboarded(tester);
    final bar = find.byType(AppNavBar);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    // 贴屏幕底边，高度只由令牌决定（测试环境没有手势区）
    final resting = tester.getRect(bar);
    expect(resting.height, AppLayout.navBarLine + AppLayout.navBarHeight);
    expect(resting.bottom, screen.height);

    final todayBefore = tester.getRect(
      find.descendant(of: bar, matching: find.text('今天')),
    );
    final weightBefore = tester.getRect(
      find.descendant(of: bar, matching: find.text('体重')),
    );

    // 切到「体重」：整栏和四个栏目的矩形一个都不动，只有颜色和实心图标变
    await tester.tap(find.descendant(of: bar, matching: find.text('体重')));
    await tester.pumpAndSettle();
    expect(tester.getRect(bar), resting);
    expect(
      tester.getRect(find.descendant(of: bar, matching: find.text('今天'))),
      todayBefore,
    );
    expect(
      tester.getRect(find.descendant(of: bar, matching: find.text('体重'))),
      weightBefore,
    );

    // 系统手势区（物理像素 72 = 逻辑 24）：变高的是底部留白，
    // 四个栏目整体上移一格，各自的尺寸和相对位置不变。
    tester.view.viewPadding = const FakeViewPadding(bottom: 72);
    await tester.pumpAndSettle();
    final withInset = tester.getRect(bar);
    expect(withInset.bottom, screen.height);
    expect(withInset.height, resting.height + 24);
    final todayWithInset = tester.getRect(
      find.descendant(of: bar, matching: find.text('今天')),
    );
    expect(todayWithInset, todayBefore.translate(0, -24));

    // 键盘弹出：页面区自己收窄到键盘上沿，导航栏一步也不动——
    // 之前这里会先掉 24dp（安全区被扣掉），再被键盘整个盖住，看着就是「会活动」。
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.getRect(bar), withInset);
    expect(
      tester.getRect(find.descendant(of: bar, matching: find.text('今天'))),
      todayWithInset,
    );

    // 键盘弹出：页面区自己收窄到键盘上沿，导航栏一步也不动——
    // 之前这里会先掉 24dp（安全区被扣掉），再被键盘整个盖住，看着就是「会活动」。
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.getRect(bar), withInset);
    expect(
      tester.getRect(find.byType(IndexedStack)).bottom,
      screen.height - 900 / tester.view.devicePixelRatio,
    );

    tester.view.resetViewInsets();
    tester.view.resetViewPadding();
    await tester.pumpAndSettle();
    expect(tester.getRect(bar), resting);
  });

  testWidgets('保存后的撤销条落在导航栏上方，不盖住底栏', (tester) async {
    await _pumpOnboarded(tester);

    await pickKg(tester);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('撤销'), findsOneWidget);
    final snack = tester.getRect(find.byType(SnackBar));
    final bar = tester.getRect(find.byType(AppNavBar));
    expect(snack.bottom, lessThanOrEqualTo(bar.top));
  });
}
