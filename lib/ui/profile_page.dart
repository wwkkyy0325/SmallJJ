import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'common/measure_field.dart';
import 'common/primary_button.dart';
import 'common/surface_card.dart';
import 'app_model.dart';
import 'format.dart';
import 'voice_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.model, this.onRunLink, super.key});

  final AppModel model;

  /// 「快捷入口」页里的自测按钮，回到 Shell 走同一条路由
  final void Function(String uri)? onRunLink;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _year;
  late final TextEditingController _height;
  late final TextEditingController _goalWeight;
  late String _activity;
  late String _goal;
  late double _rate;
  late bool _period;
  late bool _aiNarration;

  @override
  void initState() {
    super.initState();
    final p = widget.model.profile!;
    _year = TextEditingController(text: '${p.birthYear}');
    _height = TextEditingController(text: heightLabel(p.heightCm));
    _goalWeight = TextEditingController(
      text: p.goalWeightKg == null ? '' : kgLabel(p.goalWeightKg!),
    );
    _activity = p.activityLevel;
    _goal = p.goalMode;
    _rate = p.goalRateKgWeek;
    _period = p.periodTracking;
    _aiNarration = p.aiNarration;
  }

  @override
  void dispose() {
    _year.dispose();
    _height.dispose();
    _goalWeight.dispose();
    super.dispose();
  }

  void _save() {
    final base = widget.model.profile!;
    final year = int.tryParse(_year.text.trim()) ?? base.birthYear;
    final height = double.tryParse(_height.text.trim()) ?? base.heightCm;
    final goalWeight = double.tryParse(_goalWeight.text.trim());
    widget.model.saveProfile(base.copyWith(
      birthYear: year.clamp(1900, 2100),
      heightCm: height.clamp(100, 250),
      activityLevel: _activity,
      goalMode: _goal,
      goalRateKgWeek: _rate,
      goalWeightKg: (goalWeight ?? 0) >= 30 ? goalWeight : null,
      periodTracking: _period,
      aiNarration: _aiNarration,
    ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('已保存，今天的预算按新资料重算')));
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final profile = model.profile!;
    final facts = model.facts;
    final cycle = model.cycle;
    final starts = model.repo.cycleStarts().reversed.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        Text('我的', style: AppType.display),
        const SizedBox(height: AppSpace.md),

        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '身体资料', caption: '只用来算 BMR，不上传'),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppLayout.fieldHeight,
                      child: TextField(
                        controller: _year,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '出生年'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: MeasureField(
                      controller: _height,
                      label: '身高',
                      unit: 'cm',
                      hint: '165',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: const InputDecoration(labelText: '日常活动量'),
                items: const [
                  DropdownMenuItem(value: 'sedentary', child: Text('久坐（几乎不运动）')),
                  DropdownMenuItem(value: 'light', child: Text('轻度（每周 1–3 次）')),
                  DropdownMenuItem(value: 'moderate', child: Text('中度（每周 3–5 次）')),
                  DropdownMenuItem(value: 'active', child: Text('活跃（每周 6–7 次）')),
                ],
                onChanged: (v) => setState(() => _activity = v ?? _activity),
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                decoration: const InputDecoration(labelText: '目标'),
                items: const [
                  DropdownMenuItem(value: 'lose', child: Text('减脂')),
                  DropdownMenuItem(value: 'maintain', child: Text('维持')),
                  DropdownMenuItem(value: 'gain', child: Text('增重')),
                ],
                onChanged: (v) => setState(() => _goal = v ?? _goal),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: MeasureField(
                      controller: _goalWeight,
                      label: '目标体重',
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: SizedBox(
                      height: AppLayout.fieldHeight,
                      child: DropdownButtonFormField<double>(
                        initialValue: _rate,
                        decoration: const InputDecoration(labelText: '每周变化'),
                        items: const [
                          DropdownMenuItem(value: 0.25, child: Text('0.25 kg')),
                          DropdownMenuItem(value: 0.5, child: Text('0.5 kg')),
                          DropdownMenuItem(value: 0.75, child: Text('0.75 kg')),
                        ],
                        onChanged: (v) => setState(() => _rate = v ?? _rate),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _period,
                onChanged: (v) => setState(() => _period = v),
                title: const Text('经期管理'),
                subtitle: const Text('记录开始日，推算下次区间'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _aiNarration,
                onChanged: (v) => setState(() => _aiNarration = v),
                title: const Text('分析文案',
                    style: TextStyle(fontFamily: 'NotoSansSC')),
                subtitle: const Text('规则引擎生成的提示，关掉只留数字'),
              ),
              const SizedBox(height: AppSpace.sm),
              PrimaryButton(label: '保存', onPressed: _save),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        if (_period)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '经期',
                  caption: '中位数 + 区间，不承诺精确到某一天',
                ),
                const SizedBox(height: AppSpace.sm),
                if (!cycle.hasPrediction)
                  Text(
                    '再记一次开始日就能给出区间预测（至少需要两个周期）。',
                    style: AppType.bodySmall,
                  )
                else ...[
                  Text(
                    '预计 ${monthDayLabel(cycle.windowStart!)} – '
                    '${monthDayLabel(cycle.windowEnd!)}',
                    style: AppType.section,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    '周期中位 ${cycle.medianCycleDays} 天 · '
                    '波动 ±${(cycle.sd ?? 0).toStringAsFixed(1)} 天 · '
                    '可信度 ${cycle.confidenceLabel}'
                    '${facts?.cycleDay != null ? ' · 当前第 ${facts!.cycleDay} 天' : ''}',
                    style: AppType.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  onPressed: () => model.addCycleStart(model.todayKey),
                  icon: const Icon(Icons.water_drop_outlined, size: AppIcon.sm),
                  label: const Text('今天来了'),
                ),
                if (starts.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  for (final start in starts)
                    Row(
                      children: [
                        Text(
                          '${monthDayLabel(start.date)} 开始',
                          style: AppType.body,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => model.removeCycleEvent(start.id),
                          icon: const Icon(Icons.close_rounded,
                              size: AppIcon.sm),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '快捷入口',
                caption: '磁贴 / 长按图标 / 链接，小布只能打开应用',
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(voiceSummary(model), style: AppType.bodySmall),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        VoicePage(model: model, onRun: widget.onRunLink),
                  ),
                ),
                icon: const Icon(Icons.mic_none_rounded, size: AppIcon.sm),
                label: const Text('查看可触发的链接'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '数据', caption: '全在本机 SQLite'),
              const SizedBox(height: AppSpace.sm),
              Text(
                '体重 ${model.counts['weight_entry'] ?? 0} 条 · '
                '饮食 ${model.counts['meal_item'] ?? 0} 条 · '
                '经期 ${model.counts['cycle_event'] ?? 0} 条 · '
                '食物库 ${model.counts['food_item'] ?? 0} 条',
                style: AppType.bodySmall,
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: model.repo.exportJsonString()),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制 JSON 到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: AppIcon.sm),
                    label: const Text('导出 JSON'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(width: AppSpace.xs),
                    OutlinedButton(
                      onPressed: () {
                        model.seedDemoData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已写入 21 天示例数据')),
                        );
                      },
                      child: const Text('示例数据'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '算法版本 v1 · 数据库 schema 1 · 身高 ${heightLabel(profile.heightCm)} cm',
                style: AppType.micro,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
