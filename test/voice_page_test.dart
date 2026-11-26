import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/db.dart';
import 'package:health_app/data/repository.dart';
import 'package:health_app/ui/app_model.dart';
import 'package:health_app/ui/voice_page.dart';

/// 这一页以前教用户「小布指令 → 添加动作 → 打开链接 → 粘 scheme」，
/// 但小布没有「打开链接」这个动作，那条路不存在。测试守住这个说法不再回来。
void main() {
  testWidgets('快捷入口页不再把小布当链接器', (tester) async {
    final model = AppModel(
      HealthRepository(
        openTestDatabase(),
        clock: () => DateTime(2026, 1, 15, 15),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: VoicePage(model: model, onRun: (_) {})),
    );

    // 小布指令里没有「添加动作 → 打开链接」这一步，旧教程不能再出现
    expect(find.textContaining('添加动作'), findsNothing);
    expect(find.textContaining('打开网页'), findsNothing);
    expect(find.textContaining('磁贴'), findsWidgets);
    expect(find.textContaining('小布只能'), findsWidgets);
  });
}
