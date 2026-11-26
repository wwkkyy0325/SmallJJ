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
    title: '记体重',
    uri: _link('weight'),
    hint: '打开弹层，时间是现在，点「时间」可以改',
    writes: false,
  ),
  VoiceLink(
    title: '记体重（带数值带时间）',
    uri: _link('weight', {'kg': '60.4', 'time': '08:00'}),
    hint: '不弹表单，直接落库并给「撤销」；数值和时间改成你实际的',
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
      appBar: AppBar(title: const Text('快捷入口 / 小布')),
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
                  caption: '小布只能「打开应用」，打不开 smalljj:// 这种链接',
                ),
                const SizedBox(height: AppSpace.xs),
                for (final step in const [
                  '1. 长按桌面上的 SmallJJ 图标 → 4 条快捷方式，点「记体重」直达。',
                  '2. 下拉状态栏 → 编辑磁贴 → 把「记体重」拖进来，之后点一下就到。',
                  '3. 任何能打开链接的地方都能用：浏览器地址栏、扫码、笔记里的链接、adb，效果一样。',
                  '4. 想要「一句话记体重」，小布那侧没有这个动作 —— 见下面那张卡。',
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xxs),
                    child: Text(step, style: AppType.bodySmall),
                  ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '小布指令（com.coloros.shortcuts）里能选的动作只有「打开应用」这一类，'
                  '没有能填 URL 的动作，所以把 scheme 填进小布这条路不成立；'
                  '这一页以前写的教程是错的，已改。'
                  '下面的链接仍然有用，而且每条都能用「自测」先在本机跑一遍。',
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
                          child: Text('直接落库', style: AppType.label),
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
                  '「小布 → App 执行动作」在 OPPO 这边只有一条官方路：'
                  '开放平台申请 client_id/secret，平台审核后下发意图名（意图共享/流体云/'
                  '小布建议那套还要把数据推到 OPPO 云出卡）。自用场景拿不到审批，'
                  '也和数据全留本机冲突。'
                  '没有这条准入，小布就只能「打开 SmallJJ」，参数进不来。',
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

/// 给「我的」页显示一行摘要
String voiceSummary(AppModel model) =>
    '${voiceCatalog.length} 个入口 · 不带时间的一律记到当前时间';
