import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'anchor_popover.dart';
import 'wheel_picker.dart';

/// 改「称重日期」：和 [showTimePopover] 是同一套浮层，只是三列「年 / 月 / 日」。
///
/// 用它替掉 Material 的 `showDatePicker`：那个是整屏对话框 + 绿/灰两套
/// Material 控件，紧挨着时间 chip 弹出来的时候，两个 chip 像在打开两个 App。
///
/// 未来日期在滚轮里滚不到：选到今年就只列到本月，选到本月就只列到今天。
Future<void> showDayPopover(
  BuildContext context, {
  required BuildContext anchor,
  required DateTime initial,
  required ValueChanged<DateTime> onChanged,
  DateTime? now,
  int yearsBack = 2,
}) {
  return showAnchorPopover<void>(
    context: context,
    anchor: anchor,
    width: AppLayout.dayPopoverWidth,
    height: AppLayout.dayPopoverHeight,
    builder: (context) => _DayPopoverBody(
      initial: initial,
      now: now ?? DateTime.now(),
      yearsBack: yearsBack,
      onChanged: onChanged,
    ),
  );
}

class _DayPopoverBody extends StatefulWidget {
  const _DayPopoverBody({
    required this.initial,
    required this.now,
    required this.yearsBack,
    required this.onChanged,
  });

  final DateTime initial;
  final DateTime now;
  final int yearsBack;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_DayPopoverBody> createState() => _DayPopoverBodyState();
}

class _DayPopoverBodyState extends State<_DayPopoverBody> {
  late int _year = widget.initial.year;
  late int _month = widget.initial.month;
  late int _day = widget.initial.day;

  late final FixedExtentScrollController _yearController =
      FixedExtentScrollController(initialItem: _year - _minYear);
  late final FixedExtentScrollController _monthController =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: _day - 1);

  /// 为了让「日」不越界而由代码去滚动的那一下，不能当成人选了新值。
  bool _silent = false;

  int get _minYear => widget.now.year - widget.yearsBack;

  /// 今年的月份只到本月。
  int get _monthCount => _year == widget.now.year ? widget.now.month : 12;

  int _dayCount(int year, int month) {
    final days = DateUtils.getDaysInMonth(year, month);
    if (year == widget.now.year && month == widget.now.month) {
      return math.min(days, widget.now.day);
    }
    return days;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _jumpTo(FixedExtentScrollController controller, int index) {
    _silent = true;
    controller.jumpToItem(index);
    _silent = false;
  }

  /// 三列共用一个落点计算：换年、换月、换日都走这里，
  /// 所以「1月31日 → 2月」不会留下一个不存在的 31 号。
  void _settle({int? year, int? month, int? day}) {
    final y = year ?? _year;
    final maxMonth = y == widget.now.year ? widget.now.month : 12;
    final m = math.min(month ?? _month, maxMonth);
    final d = math.min(day ?? _day, _dayCount(y, m));

    final monthMoved = m != _month;
    final dayMoved = d != _day;
    setState(() {
      _year = y;
      _month = m;
      _day = d;
    });
    if (monthMoved) _jumpTo(_monthController, m - 1);
    if (dayMoved) _jumpTo(_dayController, d - 1);
    widget.onChanged(DateTime(y, m, d));
  }

  void _resetToToday() {
    final now = widget.now;
    setState(() {
      _year = now.year;
      _month = now.month;
      _day = now.day;
    });
    _jumpTo(_yearController, now.year - _minYear);
    _jumpTo(_monthController, now.month - 1);
    _jumpTo(_dayController, now.day - 1);
    widget.onChanged(DateTime(now.year, now.month, now.day));
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
                          flex: 5,
                          child: WheelPicker(
                            count: widget.now.year - _minYear + 1,
                            controller: _yearController,
                            style: _dayType,
                            label: (index) => '${_minYear + index}年',
                            onChanged: (index) {
                              if (_silent) return;
                              _settle(year: _minYear + index);
                            },
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: WheelPicker(
                            count: _monthCount,
                            controller: _monthController,
                            style: _dayType,
                            label: (index) => '${index + 1}月',
                            onChanged: (index) {
                              if (_silent) return;
                              _settle(month: index + 1);
                            },
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: WheelPicker(
                            count: _dayCount(_year, _month),
                            controller: _dayController,
                            style: _dayType,
                            label: (index) => '${index + 1}日',
                            onChanged: (index) {
                              if (_silent) return;
                              _settle(day: index + 1);
                            },
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
            actionLabel: '今天',
            onAction: _resetToToday,
          ),
        ],
      ),
    );
  }

  /// 三列都带「年 / 月 / 日」后缀，19px 刚好让「2026年」不挤，也不抢时间浮层的字号。
  static final _dayType = AppType.metric.copyWith(fontSize: 19);
}
