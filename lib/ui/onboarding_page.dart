import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/weight_input.dart';
import '../theme/tokens.dart';
import 'app_model.dart';
import 'common/measure_field.dart';
import 'common/primary_button.dart';

/// 第一次打开：只问算 BMR 必须的三项，十几秒填完就进主页。
///
/// 没有性别：这个应用只服务女性，BMR 固定女式。
///
/// 活动量、目标、目标体重都给了合理的起步值，之后在「我的」里随时改，
/// 不在这里拦人——第一次用的人还没有耐心回答七个问题。
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.model, super.key});

  final AppModel model;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _year = TextEditingController(text: '1996');
  final _height = TextEditingController(text: '165');
  final _weight = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _weight.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _year.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _start() {
    final year = int.tryParse(_year.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = parseWeightInput(_weight.text);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      setState(() => _error = '出生年看起来不对');
      return;
    }
    if (height == null || height < 100 || height > 250) {
      setState(() => _error = '身高请填 100–250 cm');
      return;
    }
    final weightError = weightInputError(weight);
    if (weightError != null) {
      setState(() => _error = weightError);
      return;
    }
    widget.model.completeOnboarding(
      draft: Profile(
        birthYear: year,
        heightCm: height,
        activityLevel: 'light',
        goalMode: 'lose',
        goalRateKgWeek: 0.5,
      ),
      weightKg: weight!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            const SizedBox(height: AppSpace.xl),
            Text('SmallJJ 健康', style: AppType.display),
            const SizedBox(height: AppSpace.xs),
            Text(
              '填三项就能开始，数据全在这台手机上。\n其余资料在「我的」里随时改。',
              style: AppType.body,
            ),
            const SizedBox(height: AppSpace.lg),
            // 两个框都在固定行高里：一个带单位、一个不带，高度仍然一样。
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
            MeasureField(
              controller: _weight,
              autofocus: true,
              label: '现在体重',
              invalid: _error != null,
            ),
            const SizedBox(height: AppSpace.xxs),
            // 错误行常驻：出错时只有这一行变色，下面的「开始」不动。
            FieldError(message: _error),
            const SizedBox(height: AppSpace.md),
            PrimaryButton(label: '开始', onPressed: _start),
            const SizedBox(height: AppSpace.sm),
            Text(
              '活动量按「轻度」、目标按「减脂 0.5 kg/周」起步，'
              '之后在「我的」里改，预算跟着重算。',
              style: AppType.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
