import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'app_model.dart';
import 'common/surface_card.dart';

/// 一条可以交给小布 / 快捷方式 / adb 触发的链接。
class VoiceLink {
  const VoiceLink({
    required this.title,
    required this.uri,
    required this.hint,
    required this.writes,
  });

  final String title;
  final String uri;

  /// 小布那侧怎么念才会走到这条链接
  final String hint;

  /// 是否直接改数据（true = 不弹表单，落库后给撤销）
  final bool writes;
}

/// 链接都用 Uri 拼，中文参数会被百分号编码——粘到「打开链接」里不会挂。
String _link(String host, [Map<String, String> query = const {}]) =>
    Uri(scheme: 'smalljj', host: host, queryParameters: query).toString();

final List<VoiceLink> voiceCatalog = [
  VoiceLink(
    title: '记早上体重',
    uri: _link('weight', {'slot': 'morning'}),
    hint: '打开弹层，时段已选「早上」，只补一个数字',
    writes: false,
  ),
  VoiceLink(
    title: '记晚上体重',
    uri: _link('weight', {'slot': 'evening'}),
    hint: '打开弹层，时段已选「晚上」',
    writes: false,
  ),
  VoiceLink(
    title: '直接记体重（带数值）',
    uri: _link('weight', {'slot': 'morning', 'kg': '60.4'}),
    hint: '不弹表单，直接落库并给「撤销」；数值改成你实际的体重',
    writes: true,
  ),
  VoiceLink(
    title: '记饮食',
    uri: _link('food', {'meal': 'lunch'}),
    hint: '切到饮食页并弹出「一句话记饮食」，餐次已选午餐',
    writes: false,
  ),
  VoiceLink(
    title: '直接记饮食（带原话）',
    uri: _link('food', {'meal': 'breakfast', 'text': '两个鸡蛋一杯牛奶'}),
    hint: '一句话解析后直接落库；认不出的食物会把原话带进弹层',
    writes: true,
  ),
  VoiceLink(
    title: '记经期开始',
    uri: _link('period', {'action': 'start'}),
    hint: '按今天记一次经期开始，可撤销',
    writes: true,
  ),
  VoiceLink(
    title: '问今天还能吃多少',
    uri: _link('query', {'what': 'budget'}),
    hint: '不写数据，只播报 + 顶部提示剩余热量',
    writes: false,
  ),
  VoiceLink(
    title: '问体重趋势',
    uri: _link('query', {'what': 'weight'}),
    hint: '播报最近体重与周趋势',
    writes: false,
  ),
  VoiceLink(
    title: '问经期预测',
    uri: _link('query', {'what': 'cycle'}),
    hint: '播报预测区间（只给区间，不给精确某一天）',
    writes: false,
  ),
  VoiceLink(
    title: '撤销刚才那条',
    uri: _link('undo'),
    hint: '说错了用它回滚最近一次语音写入',
    writes: true,
  ),
];

/// 「我的 → 小布 / 快捷指令」：把可触发的链接摆出来，能复制、能当场自测。
class VoicePage extends StatelessWidget {
  const VoicePage({required this.model, this.onRun, super.key});

  final AppModel model;

  /// 本地自测：不经过小布，直接用应用内的路由跑一遍
  final void Function(String uri)? onRun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小布 / 快捷指令')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.xl,
        ),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '手机上怎么接',
                  caption: '不需要账号，也不需要联网',
                ),
                const SizedBox(height: AppSpace.xs),
                for (final step in const [
                  '1. 对小布说「打开小布指令」，或用桌面图标进「小布指令」。',
                  '2. 右上角「+」新建指令，触发方式选「一句话」，写你顺口的说法。',
                  '3. 添加动作 → 找「打开链接 / 打开网页」，把下面任意一条粘进去。',
                  '4. 保存后对小布说那句话，链接会直接进到这里的对应页面或直接落库。',
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xxs),
                    child: Text(step, style: AppType.bodySmall),
                  ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '如果当前 ColorOS 的「打开链接」只认 http/https，'
                  '这一路就走不通；桌面快捷方式和 adb 仍然可用，'
                  '下面每条都能用「自测」按钮先在本机验证。',
                  style: AppType.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          for (final link in voiceCatalog) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(link.title, style: AppType.section),
                      ),
                      if (link.writes)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.brandSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text('直接落库', style: AppType.micro),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(link.hint, style: AppType.bodySmall),
                  const SizedBox(height: AppSpace.xs),
                  SelectableText(
                    link.uri,
                    style: AppType.bodySmall.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link.uri));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已复制：${link.title}')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: AppIcon.sm),
                        label: const Text('复制'),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      TextButton.icon(
                        onPressed: () {
                          final run = onRun;
                          if (run == null) return;
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            run(link.uri);
                          });
                        },
                        icon: const Icon(Icons.play_arrow_rounded,
                            size: AppIcon.sm),
                        label: const Text('自测'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: '没接 OPPO 意图框架',
                  caption: '这条是取舍，不是漏做',
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '意图框架要在开放平台申请 client_id/secret，由平台审核后下发意图名，'
                  '且设计上是由小布侧执行、数据要出端。自用场景既拿不到审批，'
                  '也和数据全留本机冲突，所以只做到「scheme 入口」这一层：'
                  '小布负责唤起，解析和计算都在手机本地完成。',
                  style: AppType.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 当前时间在哪个时段：给「不带 slot 的链接」兜底
String guessSlotLabel(AppModel model) {
  final hour = model.now.hour;
  if (hour < 11) return '早上';
  if (hour >= 17) return '晚上';
  return '任意';
}

/// 给「我的」页显示一行摘要
String voiceSummary(AppModel model) =>
    '${voiceCatalog.length} 个入口 · 当前会记到「${guessSlotLabel(model)}」';
