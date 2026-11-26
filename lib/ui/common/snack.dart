import 'package:flutter/material.dart';

/// 显示一条会自己消失的提示。
///
/// 换新提示时用「立刻移除」而不是 `hideCurrentSnackBar`：后者一边播上一条的
/// 退场动画、一边排新一条，新一条的入场动画被打断后，SnackBar 自带的计时器
/// 就不会启动——撤销条永久停在底部（实测：连续两条链接，12 秒后还压在
/// 「我的 → 保存」上）。
void showSnack(ScaffoldMessengerState messenger, SnackBar bar) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(bar);
}
