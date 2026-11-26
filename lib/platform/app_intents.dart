import 'package:flutter/services.dart';

/// 小布 / 桌面快捷方式 / adb 都通过这套 scheme 进来，端侧实现，不需要
/// 任何服务端账号，也不联网。
///
/// 全部支持的链接（大小写、中英别名都接受，解析见 [parseLink]）：
///
///   记体重（带数值 = 直接落库，不带 = 打开弹层预填）
///     smalljj://weight?kg=60.4                 时间 = 现在
///     smalljj://weight?kg=60.4&time=08:00      指定时刻
///     smalljj://weight?date=2026-01-14&kg=60.4 补记哪天
///     smalljj://weight                        只打开弹层，时间预填现在
///     smalljj://weight?slot=morning            兼容旧链接（= 早上 8:00）
///
///   记饮食（带 text = 一句话解析后直接落库）
///     smalljj://food?meal=lunch&text=两个鸡蛋一杯牛奶
///     smalljj://food                           打开饮食页
///
///   经期
///     smalljj://period?action=start
///     smalljj://period?action=status           只播报，不写数据
///
///   查询（只播报 + 顶部提示，不写数据）
///     smalljj://query?what=budget|weight|cycle|all
///
///   其它
///     smalljj://today                          回到今天
///     smalljj://undo                           撤销刚才那条语音记录
class AppIntents {
  static const MethodChannel _channel = MethodChannel('smalljj/intent');

  /// 冷启动时携带的链接（消费一次）
  static Future<String?> initial() async {
    try {
      return await _channel.invokeMethod<String>('initialIntent');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static final Set<void Function(String)> _listeners = {};
  static bool _installed = false;

  /// 应用已在运行时收到的新链接。
  ///
  /// 用一个注册表而不是「后注册覆盖前注册」：以前 setMethodCallHandler 只保留
  /// 最后一个监听者，热启动时如果多建了一个 Widget 树，链接会打到屏幕上看不见
  /// 的那个实例上（smalljj://food 切页失败就是这个原因）。
  static void listen(void Function(String uri) onIntent) {
    _listeners.add(onIntent);
    if (_installed) return;
    _installed = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        for (final listener in List.of(_listeners)) {
          listener(call.arguments as String);
        }
      }
      return null;
    });
  }

  static void unlisten(void Function(String uri) onIntent) {
    _listeners.remove(onIntent);
  }

  /// 系统 TTS 播报。设备没装中文语音包时静默跳过，不影响落库。
  static void speak(String text) {
    _channel.invokeMethod<void>('speak', text).catchError((_) {});
  }
}

/// 解析后的链接：type + 原始参数（键已小写）。
class SmalljjLink {
  const SmalljjLink({required this.type, this.args = const {}});

  final String type;
  final Map<String, String> args;

  String? operator [](String key) => args[key];

  /// 按别名顺序取第一个非空值。
  String? firstOf(List<String> keys) {
    for (final key in keys) {
      final value = args[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  @override
  String toString() => 'SmalljjLink($type, $args)';
}

const _typeAlias = <String, String>{
  'weight': 'weight',
  'record': 'weight',
  'log': 'weight',
  '体重': 'weight',
  'food': 'food',
  'meal': 'food',
  '饮食': 'food',
  'period': 'period',
  'cycle': 'period',
  '经期': 'period',
  'query': 'query',
  'ask': 'query',
  '问': 'query',
  'today': 'today',
  'home': 'today',
  '首页': 'today',
  'undo': 'undo',
  '撤销': 'undo',
};

SmalljjLink? parseLink(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) return null;
  if (parsed.scheme.toLowerCase() != 'smalljj') return null;

  var head = parsed.host.trim().toLowerCase();
  if (head.isEmpty && parsed.pathSegments.isNotEmpty) {
    head = parsed.pathSegments.first.trim().toLowerCase();
  }
  final type = _typeAlias[head];
  if (type == null) return null;

  final args = <String, String>{
    for (final entry in parsed.queryParameters.entries)
      entry.key.trim().toLowerCase(): entry.value,
  };
  // smalljj://weight/60.4 这种把数值放在路径里的写法
  if (type == 'weight' &&
      parsed.pathSegments.isNotEmpty &&
      args['kg'] == null &&
      double.tryParse(parsed.pathSegments.first) != null) {
    args['kg'] = parsed.pathSegments.first;
  }
  return SmalljjLink(type: type, args: args);
}
