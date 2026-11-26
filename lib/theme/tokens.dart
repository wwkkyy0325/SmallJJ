import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// 设计令牌 —— 整个前端的唯一取值来源。
/// 组件里不写颜色、字号、间距、圆角、时长字面量，一律引用这里。
/// ─────────────────────────────────────────────────────────────

/// 颜色：一个中性阶梯 + 一个品牌色 + 四个指标色。
abstract final class AppColor {
  /// 页面底色（略带薄荷灰，和白卡片分层）
  static const canvas = Color(0xFFF2F5F4);

  /// 卡片 / 导航底色
  static const surface = Color(0xFFFFFFFF);

  /// 次级填充：进度条轨道、标签底色
  static const surfaceMuted = Color(0xFFE9F0ED);

  /// 正文最深的墨色
  static const ink = Color(0xFF0E1A16);

  /// 次级文字（对白底 5.6:1）
  static const inkMuted = Color(0xFF596B65);

  /// 仅用于装饰线条与 ≥24dp 的图标，不承载正文
  static const inkFaint = Color(0xFF8B9C96);

  /// 分隔线 / 描边
  static const line = Color(0xFFE0E8E4);

  /// 品牌色：图形、进度、选中态
  static const brand = Color(0xFF0E9F6E);

  /// 品牌色加深版：填充按钮底色，保证白字对比度 5.2:1
  static const brandStrong = Color(0xFF0A7C57);

  /// 品牌浅底
  static const brandSoft = Color(0xFFE3F4EC);

  /// 品牌色上的文字
  static const onBrand = Color(0xFFFFFFFF);

  /// 指标色：心率
  static const heart = Color(0xFFE2575F);

  /// 指标色：睡眠
  static const sleep = Color(0xFF5A64C8);

  /// 指标色：饮水
  static const water = Color(0xFF2A87C8);

  /// 指标色：活动 / 能量
  static const amber = Color(0xFFE2943F);

  /// 焦点环
  static const focus = Color(0xFF0E9F6E);

  /// 卡片投影（唯一一层）
  static const shadow = Color(0x140E1A16);
}

/// 字号阶梯：每一级都带行高与字距，标题是具名的一级而不是“字号+临时字距”。
abstract final class AppType {
  /// 字体回退链：打包的 Noto Sans SC 优先，其次各平台自带中文字体。
  static const family = 'NotoSansSC';
  static const fallback = <String>[
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
  ];

  static const _base = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
  );

  /// 大数字 / 首屏主标题 34px
  static final display = _base.copyWith(
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColor.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 页面标题 24px
  static final headline = _base.copyWith(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColor.ink,
  );

  /// 区块标题 20px
  static final section = _base.copyWith(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColor.ink,
  );

  /// 卡片标题 / 列表主文字 16px
  static final title = _base.copyWith(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColor.ink,
  );

  /// 正文 15px
  static final body = _base.copyWith(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColor.ink,
  );

  /// 次级说明 13px
  static final bodySmall = _base.copyWith(
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColor.inkMuted,
  );

  /// 数值：卡片里的测量值 22px，等宽数字
  static final metric = _base.copyWith(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColor.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 环内主数字 30px
  static final ringNumber = _base.copyWith(
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColor.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 行内数值 14px
  static final stat = _base.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColor.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 迷你标签 / 单位 11px
  static final label = _base.copyWith(
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColor.inkMuted,
  );

  /// 柱状图刻度 10px
  static final micro = _base.copyWith(
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColor.inkMuted,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// 按钮文字 15px
  static final button = _base.copyWith(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColor.onBrand,
  );
}

/// 间距阶梯：4 / 8 / 12 / 16 / 24 / 32 / 48，只有这七级。
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 圆角
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
}

/// 动效：时长与曲线成对出现。
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  /// 常规进出
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// 入场：快起慢落
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1);

  /// 退场
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// 系统开启“减弱动态效果”时用零时长，而不是把动画缩短。
  static Duration respect(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}

/// 版式断点与栅格
abstract final class AppLayout {
  /// < 600 单列（手机）
  static const double medium = 600;

  /// ≥ 1000 双列 + 左侧导航栏（平板横屏 / 桌面）
  static const double wide = 1000;

  /// 内容最大宽度，1440 屏也不拉成一条线
  static const double maxContent = 1120;

  static const double gutterCompact = AppSpace.md;
  static const double gutterWide = AppSpace.lg;

  /// 手指点击目标下限
  static const double tapMin = 48;

  /// 一行输入框 / 主按钮的统一高度：两者并排或上下相邻时看起来是一套
  static const double fieldHeight = 52;

  /// 错误提示的常驻行高。
  ///
  /// 错误文字**不放在输入框自己的 decoration 里**：`InputDecoration.errorText`
  /// 会把输入框撑高一行，下面所有东西跟着往下跳。这里给它一个固定行，
  /// 没出错时也占位，于是「出错 / 没出错」只有颜色变化，没有位移。
  static const double errorSlot = 20;

  /// 一行里两个可点胶囊（时间 / 体重）的高度。
  ///
  /// 和 [fieldHeight] 一样高：它们和下面的「保存」按钮同宽同列，上下相邻时
  /// 看起来是一套。宽度不写死——两个胶囊各占行宽的一半（`Expanded`），
  /// 行宽由卡片或弹层决定，窄屏也不会顶出去、宽屏也不会留下一条空档。
  static const double chipHeight = fieldHeight;

  /// 底部导航：整栏钉在屏幕底边上，位置和高度只由这里决定。
  ///
  /// 栏的总高 = [navBarLine] + [navBarHeight] + 系统手势区（`viewPadding`）。
  /// 键盘弹出时这个数一个像素都不改：页面区自己收窄，栏不动——
  /// 否则一打字，四个栏目就整体上下挪一次。
  static const double navBarLine = 1;
  static const double navBarHeight = 64;

  /// 栏目里的图标边长（选中/未选中同尺寸，切换时不会挤动文字）。
  static const double navIcon = 24;

  /// 底部弹层：位置（贴底、居中、限宽）与头部、内边距全部从这里取。
  static const double sheetMaxWidth = 480;
  static const double sheetGutter = AppSpace.lg;
  static const double sheetTopPad = AppSpace.sm;
  static const double sheetHeader = tapMin;
  static const double sheetFooterGap = AppSpace.sm;
  static const double sheetBottomPad = AppSpace.lg;

  /// 弹层顶部至少留这么多，永远顶不到状态栏。
  static const double sheetTopGap = 40;

  /// 对话框：最大宽度 + 左右留白，窄屏按屏幕宽度收窄。
  static const double dialogMaxWidth = 400;
  static const double dialogInset = 28;
  static const double dialogAction = 44;

  /// ── 锚点浮层（改「时间 / 日期」这一层）─────────────────────────
  ///
  /// 和底部弹层的区别：浮层贴在被点的 chip 旁边、不压暗背景、没有「确定」，
  /// 所以它必须够小——它只盖住自己那一小块，不接管整块屏幕。
  ///
  /// 浮层离屏幕边缘的最小距离。
  static const double popoverInset = 8;

  /// 浮层与锚点 chip 之间的缝。
  static const double popoverGap = 6;

  /// 浮层内容的内边距（左右）与底部那一行的高度。
  static const double popoverPad = AppSpace.sm;
  static const double popoverFooter = 36;

  /// 滚轮一行的高度。浮层里的滚轮固定 3 行，上下两行只作参照，
  /// 中间那一行才是当前值。
  static const double wheelRow = 44;
  static const double wheelRows = 3;

  /// 时间浮层：两列「时 / 分」。
  static const double timePopoverWidth = 188;
  static const double timePopoverHeight =
      AppSpace.xs + wheelRow * wheelRows + popoverFooter + AppSpace.xxs;

  /// 日期浮层：三列「年 / 月 / 日」，每列都要放得下「2026年」。
  static const double dayPopoverWidth = 240;
  static const double dayPopoverHeight = timePopoverHeight;

  /// 体重浮层：两列「整数 kg / 小数」，每列最多三位数字。
  static const double kgPopoverWidth = 200;
  static const double kgPopoverHeight = timePopoverHeight;
}

/// 图标尺寸
abstract final class AppIcon {
  static const double sm = 16;
  static const double md = 22;
  static const double lg = 28;
}

/// 唯一一层投影
abstract final class AppShadow {
  static const card = [
    BoxShadow(color: AppColor.shadow, blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// 浮层浮在页面之上：两层投影，一层近距离描出边缘，一层远距离交代高度。
  static const popover = [
    BoxShadow(color: AppColor.shadow, blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: AppColor.shadow, blurRadius: 32, offset: Offset(0, 12)),
  ];
}
