import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import 'food_seed.dart';

/// 建库与迁移。表只有 8 张，全部围绕「体重 / 饮食 / 预算 / 周期」，
/// 没有预留表：用不上的东西不建。
const int kSchemaVersion = 1;

const String _schemaV1 = '''
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS profile (
  id                INTEGER PRIMARY KEY CHECK (id = 1),
  sex               TEXT NOT NULL CHECK (sex IN ('female','male')),
  birth_year        INTEGER NOT NULL CHECK (birth_year BETWEEN 1900 AND 2100),
  height_cm         REAL NOT NULL CHECK (height_cm BETWEEN 100 AND 250),
  activity_level    TEXT NOT NULL DEFAULT 'light'
                    CHECK (activity_level IN ('sedentary','light','moderate','active')),
  goal_mode         TEXT NOT NULL DEFAULT 'lose'
                    CHECK (goal_mode IN ('lose','maintain','gain')),
  goal_weight_kg    REAL CHECK (goal_weight_kg BETWEEN 30 AND 200),
  goal_rate_kg_week REAL NOT NULL DEFAULT 0.5
                    CHECK (goal_rate_kg_week BETWEEN 0 AND 1),
  period_tracking   INTEGER NOT NULL DEFAULT 0,
  ai_narration      INTEGER NOT NULL DEFAULT 1,
  updated_at        INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS weight_entry (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  local_date    TEXT NOT NULL,
  measured_at   INTEGER NOT NULL,
  slot          TEXT NOT NULL CHECK (slot IN ('morning','evening','other')),
  weight_kg     REAL NOT NULL CHECK (weight_kg BETWEEN 25 AND 300),
  body_fat_pct  REAL CHECK (body_fat_pct BETWEEN 1 AND 70),
  note          TEXT,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL,
  UNIQUE(local_date, slot)
);

CREATE TABLE IF NOT EXISTS food_item (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name            TEXT NOT NULL,
  alias           TEXT,
  pinyin          TEXT,
  kcal_per_100g   REAL NOT NULL CHECK (kcal_per_100g >= 0),
  protein_per_100g REAL NOT NULL DEFAULT 0,
  carb_per_100g   REAL NOT NULL DEFAULT 0,
  fat_per_100g    REAL NOT NULL DEFAULT 0,
  default_portion_g REAL NOT NULL DEFAULT 100 CHECK (default_portion_g > 0),
  portion_label   TEXT NOT NULL DEFAULT '份',
  is_custom       INTEGER NOT NULL DEFAULT 0,
  created_at      INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS meal_entry (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  local_date  TEXT NOT NULL,
  meal        TEXT NOT NULL CHECK (meal IN ('breakfast','lunch','dinner','snack')),
  created_at  INTEGER NOT NULL,
  UNIQUE(local_date, meal)
);

CREATE TABLE IF NOT EXISTS meal_item (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  meal_id     INTEGER NOT NULL REFERENCES meal_entry(id) ON DELETE CASCADE,
  food_id     INTEGER NOT NULL REFERENCES food_item(id),
  food_name   TEXT NOT NULL,
  grams       REAL NOT NULL CHECK (grams > 0 AND grams < 5000),
  kcal        REAL NOT NULL CHECK (kcal >= 0),
  protein_g   REAL NOT NULL DEFAULT 0,
  carb_g      REAL NOT NULL DEFAULT 0,
  fat_g       REAL NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_meal_item_meal ON meal_item(meal_id);

CREATE TABLE IF NOT EXISTS day_target (
  local_date      TEXT PRIMARY KEY,
  bmr             REAL NOT NULL,
  tdee            REAL NOT NULL,
  intake_budget   REAL NOT NULL,
  deficit_kcal    REAL NOT NULL,
  protein_g       REAL NOT NULL,
  carb_g          REAL NOT NULL,
  fat_g           REAL NOT NULL,
  algo_version    TEXT NOT NULL,
  note            TEXT,
  created_at      INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS cycle_event (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  local_date  TEXT NOT NULL,
  kind        TEXT NOT NULL DEFAULT 'start' CHECK (kind IN ('start','end')),
  created_at  INTEGER NOT NULL,
  UNIQUE(local_date, kind)
);

CREATE TABLE IF NOT EXISTS meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''';

/// 打开真实设备上的库（应用私有目录，不进相册、不需要任何权限）。
///
/// 目录由 MainActivity 直接给出（`filesDir`），不引入 path_provider：
/// 它的 Android 实现现在会拖进 jni 依赖，进而要求本机装一份完整 NDK。
Future<Database> openAppDatabase() async {
  final dir = await _appDir();
  final file = File('${dir.path}${Platform.pathSeparator}smalljj.db');
  final db = sqlite3.open(file.path);
  migrate(db);
  return db;
}

Future<Directory> _appDir() async {
  try {
    const channel = MethodChannel('smalljj/paths');
    final path = await channel.invokeMethod<String>('filesDir');
    if (path != null && path.isNotEmpty) return Directory(path);
  } on PlatformException {
    // 落到下面的兜底
  } on MissingPluginException {
    // 桌面/测试环境没有这个 channel
  }
  final fallback = Directory('${Directory.systemTemp.path}/smalljj_health');
  await fallback.create(recursive: true);
  return fallback;
}

/// 单测用。内存库，跑完即弃。
Database openTestDatabase() {
  final db = sqlite3.openInMemory();
  migrate(db);
  return db;
}

void migrate(Database db) {
  final version =
      (db.select('PRAGMA user_version').first.values.first as int?) ?? 0;
  if (version >= kSchemaVersion) return;
  db.execute(_schemaV1);
  _seedFoods(db);
  db.execute('PRAGMA user_version = $kSchemaVersion');
}

void _seedFoods(Database db) {
  final count = db.select('SELECT COUNT(*) AS c FROM food_item').first['c'] as int;
  if (count > 0) return;
  db.execute('BEGIN');
  final stmt = db.prepare(
    'INSERT INTO food_item '
    '(name, alias, pinyin, kcal_per_100g, protein_per_100g, carb_per_100g, '
    ' fat_per_100g, default_portion_g, portion_label, is_custom, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)',
  );
  final now = DateTime.now().millisecondsSinceEpoch;
  try {
    for (final food in foodSeeds) {
      stmt.execute([
        food.name,
        food.alias,
        food.pinyin,
        food.kcal,
        food.protein,
        food.carb,
        food.fat,
        food.portion,
        food.portionLabel,
        now,
      ]);
    }
  } finally {
    stmt.dispose();
    db.execute('COMMIT');
  }
}
