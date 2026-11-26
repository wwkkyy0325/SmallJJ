import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../domain/weight_input.dart';
import '../../theme/tokens.dart';
import '../app_model.dart';
import '../format.dart';
import 'day_popover.dart';
import 'kg_popover.dart';
import 'primary_button.dart';
import 'snack.dart';
import 'time_popover.dart';
import 'weight_confirm.dart';

/// 一行里的单个选择胶囊：点整个灰底开浮层，值直接显示在胶囊上。
///
/// 它是「选择行」而不是输入框：没有光标、没有键盘、没有光标位置这一层，
/// 所以点开之后不存在「输入到一半」的状态——滚到哪一格，胶囊上就是那个值。
class PickChip extends StatelessWidget {
  const PickChip({
    required this.label,
    required this.onPressed,
    this.unit,
    this.icon,
    super.key,
  });

  final String label;

  /// 单位（体重的 `kg`）：常显，跟着数值一起读成「60.42 kg」。
  final String? unit;

  final IconData? icon;

  /// 点开浮层。参数是要贴着的那个控件（= 这颗胶囊本身）。
  final ValueChanged<BuildContext> onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.chipHeight,
      child: Material(
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.pillAll,
        clipBehavior: Clip.antiAlias,
        child: Builder(
          builder: (zone) => InkWell(
            onTap: () => onPressed(zone),
            child: _ChipFace(
              icon: icon,
              label: label,
              unit: unit,
              valueStyle: AppType.metric,
              trailingArrow: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// 「什么时候」这颗胶囊：左半边日期、右半边时间，点哪半边就改哪半边。
///
/// 宽度不写死：它由外面的 `Expanded` 决定（和体重胶囊各占行宽的一半）。
/// 所以日期从「今天」变成「9/28」、时间从「现在 15:35」变成「15:35」，
/// 只有文字变——胶囊的边界和右边那颗胶囊的位置一个像素都不动。
///
/// 没有日期那一半时（首屏只改时间、日期永远是今天）整颗胶囊就是一个时间按钮。
class WhenChip extends StatelessWidget {
  const WhenChip({
    required this.timeLabel,
    required this.onPickTime,
    this.dayLabel,
    this.onPickDay,
    super.key,
  });

  /// 右半边：'15:35' / '现在 15:35'。
  final String timeLabel;

  /// 左半边：'今天' / '9/28'。null = 这次不选日期，左半边整块不画。
  final String? dayLabel;

  /// 点左半边：打开日期浮层。参数是要贴着的那个控件（= 被点的那半边）。
  final ValueChanged<BuildContext>? onPickDay;

  /// 点右半边：打开时间浮层。
  final ValueChanged<BuildContext> onPickTime;

  bool get _hasDay => dayLabel != null && onPickDay != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.chipHeight,
      child: Material(
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.pillAll,
        clipBehavior: Clip.antiAlias,
        child: Row(
          // 撑满：两个半边各自占满整颗胶囊的高度，点击目标就是看得见的
          // 那块灰底，浮层也贴着胶囊底边弹出来。
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasDay) ...[
              // 日期半边按内容取宽（最宽也就是「12/28」），剩下的宽度全给时间
              // 半边——20sp 的数字比原来大一档，两边各分一半就会把「16:42」
              // 挤成「16:…」。IntrinsicWidth：Row 给非弹性子项的宽度是无限的，
              // 里面那个 Flex 会直接报 unbounded 断言，得先把它收成内容宽度。
              IntrinsicWidth(
                child: Builder(
                  builder: (zone) => InkWell(
                    onTap: () => onPickDay!(zone),
                    child: _ChipFace(
                      icon: Icons.event_rounded,
                      label: dayLabel!,
                      valueStyle: AppType.metric,
                      compact: true,
                    ),
                  ),
                ),
              ),
              // 一条细线把两个半边分开：不然读起来像一句「今天 15:35」，
              // 看不出是两个能分别点的值。
              Container(
                width: 1,
                height: AppLayout.chipHeight / 2,
                color: AppColor.line,
              ),
            ],
            Expanded(
              child: Builder(
                builder: (zone) => InkWell(
                  onTap: () => onPickTime(zone),
                  child: _ChipFace(
                    label: timeLabel,
                    valueStyle: AppType.metric,
                    // 拆成两个半边时不再画展开箭头：一条缝已经把「这是两段」
                    // 说清楚了，箭头只会再吃掉 20dp，把时间挤掉。
                    trailingArrow: !_hasDay,
                    compact: _hasDay,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 胶囊里面的内容：图标 + 一行字 +（单位）+（展开箭头）。三处共用一个排法。
class _ChipFace extends StatelessWidget {
  const _ChipFace({
    required this.label,
    this.icon,
    this.unit,
    required this.valueStyle,
    this.trailingArrow = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final String? unit;

  /// 值用哪一档字：三处都传 [AppType.metric]，所以「时间」和「体重」两颗
  /// 胶囊上的字必须一样大、一样粗——这两颗胶囊并排在一起，差一档就看得出来。
  final TextStyle valueStyle;

  final bool trailingArrow;

  /// 挤在一颗胶囊里的两段（日期 + 时间）用紧凑内边距：两段各留 8dp 的话，
  /// 20sp 的「16:42」就会被省略号截掉。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.xxs : AppSpace.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.sm, color: AppColor.inkMuted),
            const SizedBox(width: AppSpace.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle.copyWith(color: AppColor.ink),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: AppSpace.xxs / 2),
            Text(
              unit!,
              maxLines: 1,
              style: AppType.bodySmall.copyWith(color: AppColor.inkMuted),
            ),
          ],
          if (trailingArrow) ...[
            const SizedBox(width: AppSpace.xxs),
            const Icon(
              Icons.expand_more_rounded,
              size: AppIcon.sm,
              color: AppColor.inkFaint,
            ),
          ],
        ],
      ),
    );
  }
}

/// 记体重的完整表单：一行放「时间」和「体重」两颗胶囊，下一行是保存。
///
/// 首屏第二张卡（热量卡下面）和「记体重」弹层用的是同一个控件，所以两处的顺序、
/// 尺寸、单位、保存后的提示完全一致。只有两点按入口不同，由参数说明：
/// - [allowDate]：弹层里为 true，可以把这次补记到以前的某一天（左胶囊左半边就是日期）；
/// - 首屏那一处不选日期，日期永远是今天。
///
/// 两个值都是「选」出来的，没有输入框：
/// - 体重从 [showKgPopover] 的两列滚轮里选，范围就是 [minWeightKg]–[maxWeightKg]，
///   所以「打错位」这种错在入口处就不存在了；
/// - 时间从 [showTimePopover] 选，日期从 [showDayPopover] 选。
///
/// 体重胶囊初始停在最近一次记过的值上：滚轮总得有个起点，而从昨天的数字
/// 挪 0.2 kg 比从 60.00 挪到 55.42 少滚很多格。
///
/// 「最近一次」是活的：首屏那张卡常驻在 IndexedStack 里、State 不会销毁，
/// 所以在体重页、语音入口或撤销条里改了数据之后，这颗胶囊跟着变（见
/// [_WeightEntryFormState._onModelChanged]）。
class WeightEntryForm extends StatefulWidget {
  const WeightEntryForm({
    required this.model,
    this.entry,
    this.at,
    this.allowDate = false,
    this.onSaved,
    super.key,
  });

  final AppModel model;

  /// 传了就表示改已有那一条。
  final WeightEntry? entry;

  /// 初始时间；null = 现在（保存那一刻的时刻）。
  final DateTime? at;

  final bool allowDate;

  /// 保存成功后回调：弹层用来关自己，首屏不用传。
  final VoidCallback? onSaved;

  /// 整个表单的高度：两颗胶囊那一行 + 空档 + 按钮，全部由令牌算出。
  ///
  /// 弹层按这个数规划高度，所以「记体重」和「改体重」的弹层一样高；
  /// 换了选中值、换了日期，高度一个像素都不变。
  static const double stackedHeight =
      AppLayout.chipHeight + AppSpace.md + AppLayout.fieldHeight;

  @override
  State<WeightEntryForm> createState() => _WeightEntryFormState();
}

class _WeightEntryFormState extends State<WeightEntryForm> {
  /// null = 现在。保存时才取时刻，停在这一页几分钟也不会记成旧时间。
  DateTime? _at;

  /// 当前选中的体重。起点：改这条 → 原值；新记 → 最近一次记过的值。
  late double _kg = widget.entry?.weightKg ?? _latestKg();

  /// 这次是用户亲手滚出来的数吗。
  ///
  /// 没滚过 = 胶囊代表「上次的值」，外面记了新体重它就跟着变；
  /// 滚过 = 尊重这次的选择，不能把滚了一半的数冲掉。
  bool _picked = false;

  double _latestKg() {
    final model = widget.model;
    return normalizeKg(
      (model.repo.latestWeightKg() ??
              model.profile?.goalWeightKg ??
              60)
          .toDouble(),
    );
  }

  @override
  void initState() {
    super.initState();
    _at = widget.entry?.date ?? widget.at;
    // 首屏那张卡常驻在 IndexedStack 里、State 不销毁，别的入口（体重页、
    // 语音、撤销条）改了数据它不会自己重建，所以跟着仓储走。
    widget.model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  /// 别处记/删了体重：胶囊没被用户动过就跟到新的「上次的值」。
  void _onModelChanged() {
    if (!mounted || widget.entry != null || _picked) return;
    final latest = _latestKg();
    if (latest == _kg) return;
    setState(() => _kg = latest);
  }

  DateTime get _now => widget.model.now;

  /// 这次要记的时刻。首屏只改时分（日期永远是今天），弹层里可以改日期。
  DateTime _resolvedAt() {
    final time = _at;
    if (time == null) return _now;
    if (widget.allowDate) return time;
    return DateTime(_now.year, _now.month, _now.day, time.hour, time.minute);
  }

  /// 点日期半边：浮层直接贴在它旁边，选好就生效，不用再点「确定」。
  Future<void> _pickDate(BuildContext anchor) async {
    final now = _now;
    final base = _at ?? now;
    await showDayPopover(
      context,
      anchor: anchor,
      initial: base.isAfter(now) ? now : base,
      now: now,
      onChanged: (picked) {
        setState(() {
          _at = DateTime(
            picked.year,
            picked.month,
            picked.day,
            base.hour,
            base.minute,
          );
        });
      },
    );
  }

  /// 点时间半边：同一个浮层，两列「时 / 分」。
  ///
  /// [showTimePopover] 收到 `null` 表示回到「现在」，所以这里把 [_at] 清回 null：
  /// 保存那一刻才取时刻，停在页面上多久都不会记成旧时间。
  Future<void> _pickTime(BuildContext anchor) async {
    final now = _now;
    final base = _at ?? now;
    await showTimePopover(
      context,
      anchor: anchor,
      initial: TimeOfDay.fromDateTime(base),
      now: now,
      onChanged: (picked) {
        setState(() {
          if (picked == null) {
            _at = null;
            return;
          }
          final day = widget.allowDate ? (_at ?? now) : now;
          _at = DateTime(
            day.year,
            day.month,
            day.day,
            picked.hour,
            picked.minute,
          );
        });
      },
    );
  }

  /// 点体重胶囊：两列滚轮「整数 / 小数」，滚到哪一格胶囊上就是哪一格。
  Future<void> _pickKg(BuildContext anchor) async {
    await showKgPopover(
      context,
      anchor: anchor,
      initial: _kg,
      last: widget.model.repo.latestWeightKg(),
      onChanged: (kg) => setState(() {
        _picked = true;
        _kg = kg;
      }),
    );
  }

  Future<void> _save() async {
    final model = widget.model;
    final value = normalizeKg(_kg);
    final at = _resolvedAt();
    // 和这之前最近的一条差 >3 kg 时先确认，挡住滚错整数位这一类错。
    final go = await confirmWeightJump(
      context,
      kg: value,
      previousKg: model.repo.weightOnOrBefore(repoDateKey(at)),
    );
    if (!go || !mounted) return;

    final editing = widget.entry;
    // 存下去的这条就是新的「上次的值」：之后别处再改，胶囊照样跟。
    _picked = false;
    final id = model.saveWeight(at: at, kg: value, id: editing?.id);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _kg = value;
      _at = widget.allowDate ? at : null;
    });
    widget.onSaved?.call();

    showSnack(
      messenger,
      SnackBar(
        content: Text(
          '${editing == null ? '已记' : '已改'} ${relativeDay(at, model.now)} '
          '${clockLabel(at)} ${kgLabel(value)} kg',
        ),
        // 带撤销按钮的 SnackBar 默认会一直挂着（persist 默认 = 有 action），
        // 会永久盖住底部按钮，所以显式要求按时走掉。
        persist: false,
        action: SnackBarAction(
          label: '撤销',
          textColor: AppColor.brandSoft,
          onPressed: () {
            if (editing == null) {
              model.deleteWeight(id);
            } else {
              // 改过的那条按原值写回去：撤销一次修改不能把记录删掉。
              model.saveWeight(
                at: editing.date,
                kg: editing.weightKg,
                id: id,
              );
            }
            if (!mounted) return;
            setState(() {
              _kg = editing?.weightKg ?? _latestKg();
              _at = editing?.date;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final at = _resolvedAt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 一行两颗胶囊，各占一半：左边「什么时候」，右边「多少 kg」。
        // 两个值都是点开浮层选，行里没有输入框，所以这一行不会因为
        // 键盘、光标、文字长短而变高或挪位。
        Row(
          children: [
            Expanded(
              child: WhenChip(
                dayLabel: widget.allowDate ? compactDay(at, _now) : null,
                onPickDay: widget.allowDate ? _pickDate : null,
                // 有日期半边时「现在」由日期那半边交代，时间只写时:分，
                // 否则两半各自挤不下。
                timeLabel: _at == null && !widget.allowDate
                    ? '现在 ${clockLabel(at)}'
                    : clockLabel(at),
                onPickTime: _pickTime,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: PickChip(
                icon: Icons.monitor_weight_outlined,
                label: kgLabel(_kg),
                unit: 'kg',
                onPressed: _pickKg,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(label: '保存', onPressed: _save),
      ],
    );
  }
}
