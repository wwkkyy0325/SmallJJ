/// 一句话记饮食：「两个鸡蛋一杯牛奶 米饭一碗」→ 食物名 + 数量 + 单位。
///
/// 只做**数量的归一**，不猜食物热量本身：热量永远来自食物库条目 × 克数。
/// 解析不出来就让用户手动选，宁可不填也不乱填。
class FoodMention {
  const FoodMention({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.raw,
  });

  final String name;
  final double quantity;
  final String? unit;

  /// 原始片段，界面上回显用（用户能看出解析对不对）
  final String raw;

  /// 这次提到的是绝对重量（克/毫升）还是「份」。
  bool get hasAbsoluteWeight => _gramsPerUnit != null;

  double? get _gramsPerUnit => switch (unit) {
        '克' || 'g' || 'G' || '公克' => 1,
        '千克' || '公斤' || 'kg' || 'KG' => 1000,
        '斤' => 500,
        '两' => 50,
        '毫升' || 'ml' || 'ML' => 1,
        '升' || 'l' || 'L' => 1000,
        _ => null,
      };

  /// [defaultPortionG] 是食物库里这一条的「一份多少克」（一个鸡蛋 50 g 之类）。
  double gramsWith(double defaultPortionG) =>
      quantity * (_gramsPerUnit ?? defaultPortionG);
}

/// 中文数字。支持 一…九、两、十、十二、半。
double? _parseNumber(String raw) {
  final direct = double.tryParse(raw);
  if (direct != null) return direct;
  const digits = {
    '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
  };
  if (raw == '半') return 0.5;
  if (raw.contains('十')) {
    final parts = raw.split('十');
    final tens = parts[0].isEmpty ? 1 : digits[parts[0]] ?? 1;
    final ones = parts.length > 1 && parts[1].isNotEmpty ? digits[parts[1]] ?? 0 : 0;
    return (tens * 10 + ones).toDouble();
  }
  if (raw.length == 1) return digits[raw]?.toDouble();
  return null;
}

final _quantityPattern = RegExp(
  r'(半|[一二两三四五六七八九十]+|\d+(?:\.\d+)?)\s*'
  r'(千克|公斤|毫升|公克|kg|KG|ml|ML|克|斤|两|个|只|杯|碗|勺|片|根|块|份|袋|盒|瓶|条|颗|把|包|罐|g|G)',
);

final _separator = RegExp(r'[，,、；;。\s+]+|和|还有|再加|以及');

String _despace(String input) {
  var out = input.replaceAllMapped(
    RegExp(
      r'(\d)\s+(千克|公斤|毫升|公克|kg|KG|ml|ML|克|斤|两|个|只|杯|碗|勺|片|根|块|份|袋|盒|瓶|条|颗|把|包|罐|升|l|L|g|G)',
    ),
    (m) => '${m[1]}${m[2]}',
  );
  out = out.replaceAllMapped(RegExp(r'([\u4e00-\u9fff])\s+(?=\d)'), (m) => m[1]!);
  return out;
}

/// 把一段自然语言拆成若干条「食物 + 数量」。
///
/// 一条里可以连写多个食物（「两个鸡蛋一杯牛奶」）：名称取数量词**后面**那段，
/// 后面没有内容才回落到前面（「鸡蛋两个」）。
List<FoodMention> parseFoodText(String text) {
  final out = <FoodMention>[];
  for (final rawSegment in _despace(text).split(_separator)) {
    final segment = rawSegment.trim();
    if (segment.isEmpty) continue;
    final matches = _quantityPattern.allMatches(segment).toList();
    if (matches.isEmpty) {
      out.add(FoodMention(name: segment, quantity: 1, unit: null, raw: segment));
      continue;
    }
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final afterStart = match.end;
      final afterEnd =
          i + 1 < matches.length ? matches[i + 1].start : segment.length;
      final beforeStart = i == 0 ? 0 : matches[i - 1].end;
      var name = segment.substring(afterStart, afterEnd).trim();
      if (name.isEmpty) name = segment.substring(beforeStart, match.start).trim();
      if (name.isEmpty) continue;
      final quantity = _parseNumber(match.group(1)!) ?? 1;
      out.add(FoodMention(
        name: name,
        quantity: quantity,
        unit: match.group(2)!,
        raw: segment,
      ));
    }
  }
  return out;
}
