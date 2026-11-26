import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/app_intents.dart';
import 'app_model.dart';
import 'common/app_nav_bar.dart';
import 'intent_router.dart';
import 'food_page.dart';
import 'onboarding_page.dart';
import 'profile_page.dart';
import 'today_page.dart';
import 'weight_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.model, super.key});

  final AppModel model;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  late final IntentRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = IntentRouter(
      model: widget.model,
      onTab: (index) {
        if (!mounted) return;
        setState(() => _index = index);
      },
    );
    AppIntents.listen(_onUri);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await AppIntents.initial();
      if (uri != null) _onUri(uri);
    });
  }

  @override
  void dispose() {
    AppIntents.unlisten(_onUri);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 跨天/后台回来时刷新，页面上的「今天」永远是真今天。
    if (state == AppLifecycleState.resumed) widget.model.reload();
  }

  void _onUri(String uri) {
    final link = parseLink(uri);
    if (link == null || !mounted) return;
    _router.handle(context, link);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        if (!model.onboarded) return OnboardingPage(model: model);
        // resizeToAvoidBottomInset 关掉：Scaffold 一旦理会键盘，就会连底栏
        // 一起抬到键盘上面，或者因为安全区被扣成 0 而往下掉一格——
        // 那是底栏唯一会「活动」的两个来源。现在键盘只影响下面这行 Padding：
        // 页面区收窄到键盘上沿，底栏永远钉在屏幕底边（被键盘挡住就挡住）。
        //
        // 底栏仍然放在 bottomNavigationBar 这个槽位里，这样 Scaffold 知道
        // 它有多高：SnackBar（保存后的撤销条）才会落在底栏上方，而不是盖住它。
        final keyboard = math.max(
          0.0,
          MediaQuery.viewInsetsOf(context).bottom - AppNavBar.heightOf(context),
        );
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _index,
                children: [
                  TodayPage(
                    model: model,
                    onOpenTrend: () => setState(() => _index = 1),
                    onOpenProfile: () => setState(() => _index = 3),
                  ),
                  WeightPage(model: model),
                  FoodPage(model: model),
                  ProfilePage(model: model, onRunLink: _onUri),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AppNavBar(
            index: _index,
            onSelected: (value) => setState(() => _index = value),
          ),
        );
      },
    );
  }
}
