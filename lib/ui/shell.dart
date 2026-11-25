import 'package:flutter/material.dart';

import '../platform/app_intents.dart';
import '../theme/tokens.dart';
import 'app_model.dart';
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
        return Scaffold(
          body: SafeArea(
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            backgroundColor: AppColor.surface,
            indicatorColor: AppColor.brandSoft,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today_rounded),
                label: '今天',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_rounded),
                selectedIcon: Icon(Icons.show_chart_rounded),
                label: '体重',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant_rounded),
                label: '饮食',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}
