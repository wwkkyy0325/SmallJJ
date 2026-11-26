import 'package:flutter/material.dart';

import '../../domain/weight_input.dart';
import '../../theme/tokens.dart';
import 'anchor_popover.dart';
import 'wheel_picker.dart';

/// 改「体重」：和 [showTimePopover] 同一套浮层，两列「整数 kg / 小数」。
///
/// 为什么不用一个 `25.00–300.00` 的单列：那是 27500 行，滚一整天也滚不到
/// 自己的数。拆成两列之后最长的一列 276 行，小数那列一格正好是 0.01 kg——
/// 和 [minWeightKg] 起的两位小数口径一致，滚出来的值就是落库的值，
/// 中间不再经过文本框解析，也就没有「打错位」这一类错了。
///
/// [onChanged] 每滚一格回调一次，chip 上的字跟着变，没有「确定」；
/// 点旁边收起就是选完了。
Future<void> showKgPopover(
  BuildContext context, {
  required BuildContext anchor,
  required double initial,
  required ValueChanged<double> onChanged,

  /// 最近一次记过的体重：底部「上次」按钮跳回它，滚远了能一键回来。
  /// null = 没有历史，不显示那个按钮。
  double? last,
}) {
  return showAnchorPopover<void>(
    context: context,
    anchor: anchor,
    width: AppLayout.kgPopoverWidth,
    height: AppLayout.kgPopoverHeight,
    builder: (context) => _KgPopoverBody(
      initial: _clamp(initial),
      last: last == null ? null : _clamp(last),
      onChanged: onChanged,
    ),
  );
}

double _clamp(double kg) =>
    normalizeKg(kg.clamp(minWeightKg, maxWeightKg).toDouble());

class _KgPopoverBody extends StatefulWidget {
  const _KgPopoverBody({
    required this.initial,
    required this.last,
    required this.onChanged,
  });

  final double initial;
  final double? last;
  final ValueChanged<double> onChanged;

  @override
  State<_KgPopoverBody> createState() => _KgPopoverBodyState();
}

class _KgPopoverBodyState extends State<_KgPopoverBody> {
  /// 整数部分（kg 的整数）与两位小数。
  late int _whole = widget.initial.floor();
  late int _cents = _clampCents(widget.initial) % 100;

  late final FixedExtentScrollController _wholeController =
      FixedExtentScrollController(initialItem: _whole - _minWhole);
  late final FixedExtentScrollController _centsController =
      FixedExtentScrollController(initialItem: _cents);

  /// 代码自己 jump 出来的回声不算用户的选择。
  bool _silent = false;

  static int get _minWhole => minWeightKg.floor();
  static int get _maxWhole => maxWeightKg.floor();

  /// 滚到 300 时小数只剩「00」：300.99 超出上限，不该让人滚得到。
  static int _centsCount(int whole) => whole >= _maxWhole ? 1 : 100;

  static int _clampCents(double kg) => (normalizeKg(kg) * 100).round();

  double get _value => normalizeKg(_whole + _cents / 100);

  @override
  void dispose() {
    _wholeController.dispose();
    _centsController.dispose();
    super.dispose();
  }

  void _select({int? whole, int? cents}) {
    // 代码把小数夹回 00 时自己跳了一下，那一格的回声不能再当成一次选择。
    if (_silent) return;
    final w = whole ?? _whole;
    var c = cents ?? _cents;
    if (c > _centsCount(w) - 1) {
      // 整数跳到 300：小数只剩 00，300.99 超出上限，不该滚得到。
      c = 0;
      _silent = true;
      _centsController.jumpToItem(0);
      _silent = false;
    }
    setState(() {
      _whole = w;
      _cents = c;
    });
    widget.onChanged(_value);
  }

  void _resetToLast() {
    final last = widget.last;
    if (last == null) return;
    final whole = last.floor();
    final cents = (_clampCents(last) - whole * 100).clamp(0, _centsCount(whole) - 1);
    _silent = true;
    setState(() {
      _whole = whole;
      _cents = cents;
    });
    _wholeController.jumpToItem(whole - _minWhole);
    _centsController.jumpToItem(cents);
    widget.onChanged(_value);
    _silent = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.popoverPad,
        AppSpace.xs,
        AppLayout.popoverPad,
        AppSpace.xxs,
      ),
      child: Column(
        children: [
          SizedBox(
            height: AppLayout.wheelRow * AppLayout.wheelRows,
            child: Stack(
              children: [
                // 一条横条横穿两列：60 和 42 读起来是同一个数。
                const Positioned(
                  left: 0,
                  right: 0,
                  top: AppLayout.wheelRow,
                  height: AppLayout.wheelRow,
                  child: WheelHighlight(),
                ),
                Positioned.fill(
                  child: WheelFade(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: WheelPicker(
                            count: _maxWhole - _minWhole + 1,
                            controller: _wholeController,
                            label: (index) => '${index + _minWhole}',
                            onChanged: (index) =>
                                _select(whole: index + _minWhole),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                          child: Center(child: Text('.', style: _dot)),
                        ),
                        Expanded(
                          flex: 2,
                          child: WheelPicker(
                            count: _centsCount(_whole),
                            controller: _centsController,
                            label: (index) => index.toString().padLeft(2, '0'),
                            onChanged: (index) => _select(cents: index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopoverFootline(
            hint: '选好就生效',
            actionLabel: widget.last == null ? null : '上次',
            onAction: widget.last == null ? null : _resetToLast,
          ),
        ],
      ),
    );
  }

  /// 小数点跟着数字同一档字号，只是压灰：它是这个数的一部分，不是装饰。
  static final _dot = AppType.metric.copyWith(color: AppColor.inkMuted);
}
