import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../format.dart';
import 'app_dialog.dart';

/// 体重跳变保护：和这一天之前最近的一条差超过 3 kg 时先问一句。
///
/// 滚轮虽然不可能把 63.5 打成 6.35，但能把 63 滚成 36（整数列滑过头），
/// 落库后同样会把趋势线拽出一个假缺口；12 小时内真的掉 4 kg 是去医院的事，
/// 不是记一笔的事。
/// 返回 true 表示可以保存（没触发，或用户确认就是这个数）。
Future<bool> confirmWeightJump(
  BuildContext context, {
  required double kg,
  required double? previousKg,
}) async {
  if (previousKg == null) return true;
  final diff = kg - previousKg;
  if (diff.abs() <= 3) return true;
  final ok = await showAppDialog<bool>(
    context,
    title: '确认这个体重',
    content: Text(
      '上次记录 ${kgLabel(previousKg)} kg，这次 ${kgLabel(kg)} kg，'
      '相差 ${signed(diff, digits: 2)} kg。\n\n是不是选错了？',
      style: AppType.body,
    ),
    actions: [
      DialogAction(
        label: '改一下',
        onPressed: () => Navigator.of(context).pop(false),
      ),
      DialogAction(
        label: '就是这个数',
        primary: true,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  return ok ?? false;
}
