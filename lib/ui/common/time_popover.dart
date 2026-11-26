import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'anchor_popover.dart';
import 'wheel_picker.dart';

/// 改「称重时间」：贴着 chip 弹出一个小浮层，左「时」右「分」，24 小时制。
///
/// 和以前的底部弹层比，动线短在三点：
/// - 不接管屏幕：浮层就贴在 chip 底下，chip 上的字跟着滚轮一起变，
///   你不会在「另一屏」里改一个属于这一屏的值；
/// - 没有「确定」：滚到哪一行就是哪一行（[onChanged] 每滚一格就回调一次），
///   点旁边就收起，不必再确认一次；
/// - 不压暗背景：表单还在原地，改完接着填体重。
///
/// [onChanged] 收到 `null` 表示「现在」——保存时才取时刻，
/// 所以停在页面上几分钟也不会记成旧时间。
Future<void> showTimePopover(
  BuildContext context, {
  required BuildContext anchor,
  required TimeOfDay initial,
  required ValueChanged<TimeOfDay?> onChanged,
  DateTime? now,
}) {
  return showAnchorPopover<void>(
    context: context,
    anchor: anchor,
    width: AppLayout.timePopoverWidth,
    height: AppLayout.timePopoverHeight,
    builder: (context) => _TimePopoverBody(
      initial: initial,
      now: TimeOfDay.fromDateTime(now ?? DateTime.now()),
      onChanged: onChanged,
    ),
  );
}

class _TimePopoverBody extends StatefulWidget {
  const _TimePopoverBody({
    required this.initial,
    required this.now,
    required this.onChanged,
  });

  final TimeOfDay initial;
  final TimeOfDay now;
  final ValueChanged<TimeOfDay?> onChanged;

  @override
  State<_TimePopoverBody> createState() => _TimePopoverBodyState();
}

class _TimePopoverBodyState extends State<_TimePopoverBody> {
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;

  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: _minute);

  /// 点「现在」后两列会各自跳一次，那些回声不能再当成「用户选了某个时刻」。
  bool _rollingBack = false;

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _select({int? hour, int? minute}) {
    final h = hour ?? _hour;
    final m = minute ?? _minute;
    setState(() {
      _hour = h;
      _minute = m;
    });
    if (_rollingBack) {
      if (h == widget.now.hour && m == widget.now.minute) return;
      _rollingBack = false;
    }
    widget.onChanged(TimeOfDay(hour: h, minute: m));
  }

  void _resetToNow() {
    _rollingBack = true;
    setState(() {
      _hour = widget.now.hour;
      _minute = widget.now.minute;
    });
    _hourController.jumpToItem(widget.now.hour);
    _minuteController.jumpToItem(widget.now.minute);
    widget.onChanged(null);
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
                // 一条横条横穿两列：13 和 35 读起来是同一个时刻。
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
                          child: WheelPicker(
                            count: 24,
                            controller: _hourController,
                            label: _twoDigits,
                            onChanged: (index) => _select(hour: index),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                          child: Center(child: Text(':', style: _colon)),
                        ),
                        Expanded(
                          child: WheelPicker(
                            count: 60,
                            controller: _minuteController,
                            label: _twoDigits,
                            onChanged: (index) => _select(minute: index),
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
            actionLabel: '现在',
            onAction: _resetToNow,
          ),
        ],
      ),
    );
  }

  /// 两列都是 [AppType.metric]：和胶囊上的 `16:23` 同一档字号，
  /// 点开浮层时数字不会跳一号。冒号跟着同一档，只是压灰。
  static final _colon = AppType.metric.copyWith(color: AppColor.inkMuted);

  static String _twoDigits(int index) => index.toString().padLeft(2, '0');
}
