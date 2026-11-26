import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/db.dart';
import 'data/repository.dart';
import 'theme/app_theme.dart';
import 'ui/app_model.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final model = AppModel(HealthRepository(db));
  runApp(HealthApp(model: model));
}

class HealthApp extends StatelessWidget {
  const HealthApp({required this.model, super.key});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmallJJ 健康',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // 系统弹窗（选日期）的文字要跟着中文走，否则日历里冒出 Cancel / OK。
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppShell(model: model),
    );
  }
}
