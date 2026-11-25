import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'app_model.dart';

/// 首次启动：五件事就能开始用，其余留到「我的」里改。
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.model, super.key});

  final AppModel model;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String _sex = 'female';
  String _activity = 'light';
  String _goal = 'lose';
  final _year = TextEditingController(text: '1996');
  final _height = TextEditingController(text: '165');
  final _weight = TextEditingController(text: '60');
  final _goalWeight = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _year.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    super.dispose();
  }

  void _start() {
    final year = int.tryParse(_year.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    if (year == null || year < 1900 || year > DateTime.now().year) {
      setState(() => _error = '出生年看起来不对');
      return;
    }
    if (height == null || height < 100 || height > 250) {
      setState(() => _error = '身高请填 100–250 cm');
      return;
    }
    if (weight == null || weight < 25 || weight > 300) {
      setState(() => _error = '体重请填 25–300 kg');
      return;
    }
    final goalWeight = double.tryParse(_goalWeight.text.trim());
    widget.model.completeOnboarding(
      draft: Profile(
        sex: _sex,
        birthYear: year,
        heightCm: height,
        activityLevel: _activity,
        goalMode: _goal,
        goalRateKgWeek: 0.5,
        goalWeightKg: (goalWeight ?? 0) >= 30 ? goalWeight : null,
        periodTracking: _sex == 'female',
      ),
      weightKg: weight,
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
              '只做四件事：记体重、记饮食、算消耗、看趋势。\n数据全部在这台手机上。',
              style: AppType.body,
            ),
            const SizedBox(height: AppSpace.xl),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('女')),
                ButtonSegment(value: 'male', label: Text('男')),
              ],
              selected: {_sex},
              onSelectionChanged: (v) => setState(() => _sex = v.first),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '出生年'),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '身高',
                      suffixText: 'cm',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '今天的体重',
                suffixText: 'kg',
              ),
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
            TextField(
              controller: _goalWeight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '目标体重（可选）',
                suffixText: 'kg',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                _error!,
                style: AppType.bodySmall.copyWith(color: AppColor.heart),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.brandStrong,
                minimumSize: const Size(0, 52),
              ),
              child: const Text('开始'),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '预算用 Mifflin-St Jeor × 活动系数起步，之后用你实际的体重变化校准。',
              style: AppType.micro,
            ),
          ],
        ),
      ),
    );
  }
}
