import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 底部导航的四个栏目：顺序、名字、图标只在这里定义一次。
///
/// 顺序就是页面在 [IndexedStack] 里的顺序，`IntentRouter` 和首屏的
/// 「趋势 / 我的」按钮都按这个顺序取下标。
enum AppTab {
  today('今天', Icons.today_outlined, Icons.today_rounded),
  weight('体重', Icons.show_chart_rounded, Icons.show_chart_rounded),
  food('饮食', Icons.restaurant_outlined, Icons.restaurant_rounded),
  profile('我的', Icons.person_outline_rounded, Icons.person_rounded);

  const AppTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// 底部导航栏：位置、高度、内部版面全部定死。
///
/// 三条不能破的约束，`test/layout_test.dart` 里量坐标锁着：
/// 1. 整栏的矩形 = 屏幕底边往上 `navBarLine + navBarHeight + 手势区`。
///    切页、键盘弹出、页面内容变长变短都不改变它；
/// 2. 栏目内部不做位移：选中只换图标（实心/线性）和颜色，
///    字重不变，所以文字宽度也不变；没有滑动的胶囊、没有图标上移。
/// 3. 底部手势区取 `viewPadding`（物理值），不取 `padding`。
///    `padding` 在键盘弹出时会被扣成 0——栏就会往下跳 24dp，
///    这正是之前打字时底栏「会活动」的原因。
class AppNavBar extends StatelessWidget {
  const AppNavBar({required this.index, required this.onSelected, super.key});

  final int index;
  final ValueChanged<int> onSelected;

  /// 整栏占的高度（含顶部细线和系统手势区）。
  ///
  /// 页面区按这个数预留底部空间，于是「页面区」和「导航栏」永远不会重叠，
  /// 也不会因为谁算错而上下差一行。
  static double heightOf(BuildContext context) =>
      AppLayout.navBarLine +
      AppLayout.navBarHeight +
      MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: AppColor.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: AppLayout.navBarLine,
            width: double.infinity,
            child: ColoredBox(color: AppColor.line),
          ),
          SizedBox(
            height: AppLayout.navBarHeight,
            child: Row(
              children: [
                for (var i = 0; i < AppTab.values.length; i++)
                  Expanded(
                    child: _NavItem(
                      tab: AppTab.values[i],
                      selected: i == index,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: bottomInset, width: double.infinity),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColor.brandStrong : AppColor.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      // 文字自己不再报一遍，否则读屏会念「今天，今天」。
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.selectedIcon : tab.icon,
              size: AppLayout.navIcon,
              color: color,
            ),
            const SizedBox(height: AppSpace.xxs),
            // 行高与字号来自令牌：选中与否只差颜色，宽度、高度都不变。
            Text(
              tab.label,
              maxLines: 1,
              style: AppType.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
