import 'package:flutter/material.dart';

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
      home: AppShell(model: model),
    );
  }
}
