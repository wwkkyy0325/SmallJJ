# SmallJJ Health

自用的个人健康数据应用（Flutter）。记录体重、饮食、经期，算出每日消耗与热量预算，
给能解释的建议。**所有数据在本机 SQLite 里，没有账号、没有埋点、Manifest 里没有任何
`uses-permission`（连 INTERNET 都没申请）。**

## 功能

| 功能 | 实现 |
|---|---|
| 体重 | 早/晚/任意时刻三个时段，`UNIQUE(local_date, slot)` 覆盖式写入；同日同格重记即改 |
| 体重趋势 | EWMA α=0.15，缺测按天数放大 α；图上是原始点 + 趋势线 |
| 每日消耗 TDEE | Mifflin-St Jeor × 活动系数；积累 10 天以上数据后按能量平衡反解，7:3 混合、±150 kcal/天 钳制 |
| 热量预算 | `TDEE − 目标缺口`，缺口 ≤25% TDEE、摄入下限 1200/1500 kcal、BMI<18.5 关闭缺口；每日预算落库，改资料不改写历史 |
| 饮食 | 内置 84 条食物（每 100 g 参考值）+ 自建条目；每餐条目落库时快照热量 |
| 一句话记饮食 | 「两个鸡蛋一杯牛奶」→ 只归一数量与单位，热量永远取自食物库，不猜 |
| 经期 | 记录开始日，最近 ≤6 个周期取中位数 + 标准差 → 区间 + 可信度 |
| 健康分析 | 规则引擎先算事实，每条洞察带 evidence 数字，文案在本地生成 |
| 小布 / 快捷指令 | `smalljj://` deep link + 桌面长按快捷方式 + 语音播报 |

## 小布入口

App 把 `smalljj://` 注册成自己的 scheme。链接里**带了数值就直接落库**，不弹表单、
不用键盘；缺参数才退回表单（时段/餐次已预选）。每次写入都留一次撤销。

| 链接 | 作用 |
|---|---|
| `smalljj://weight?slot=morning` | 打开体重弹层，时段已选 |
| `smalljj://weight?slot=morning&kg=59.8` | 直接记一次体重 |
| `smalljj://weight/59.8` | 同上，数值走路径，时段按钟点猜 |
| `smalljj://food?meal=lunch&text=两个鸡蛋一杯牛奶` | 一句话直接记一餐 |
| `smalljj://food` | 切到饮食页并打开「一句话记饮食」 |
| `smalljj://period?action=start` | 记经期开始 |
| `smalljj://query?what=budget` | 只播报不写数据（`budget` / `weight` / `cycle` / `all`） |
| `smalljj://undo` | 撤销上一条语音写入 |
| `smalljj://today` | 回到「今天」 |

类型与参数都带中文别名（`体重` / `饮食` / `经期` / `问` / `撤销` / `首页`）。

三条触发路径：

```bash
# 1) 直接触发（已实测）
adb shell am start -a android.intent.action.VIEW -d "smalljj://weight?slot=morning&kg=59.8"

# 2) 长按桌面图标 → 快捷方式（记早上体重 / 记晚上体重 / 记饮食 / 今天还能吃多少 / 记经期开始）

# 3) 小布指令里新建自定义指令，动作选「打开链接」，填上面的 URL
```

第 3 条能否绑定自定义 scheme 取决于 ColorOS 小布指令的版本，需要在真机上确认；
1、2 两条与它无关。

## 目录

```
lib/
  data/      db.dart（建表/迁移）、models.dart、repository.dart、food_seed.dart
  domain/    energy.dart（TDEE/预算）、weight_trend.dart、food_parse.dart、
             cycle.dart、analysis.dart（规则引擎）
  platform/  app_intents.dart（scheme 解析、系统 TTS）
  ui/        today / weight / food / profile / onboarding / sheets / voice
             intent_router.dart（链接 → 对数据做的事）
             theme/（设计 token）
test/        56 条单测与 widget 测试
docs/        功能调研、数据模型与算法、本轮实现与取舍
```

## 构建与测试

```bash
flutter pub get
flutter analyze          # No issues found!
flutter test             # All tests passed! (+56)
flutter build apk --debug
```

Android 侧入口在 `android/app/src/main/kotlin/com/smalljj/health_app/MainActivity.kt`：
`singleTask` 接收 deep link，`onNewIntent` 转给 Flutter，并提供 `smalljj/intent`、
`smalljj/paths` 两个 MethodChannel。

## 已知限制

- 食物库数值是公开参考值取整，个体差异大，用户可自建条目覆盖。
- 摄入下限 1200/1500 kcal 是保守阈值，不是指南原文，界面上标明是钳制值。
- 经期「可信度」是启发式（样本量 + 标准差），不是统计置信区间。
- 未接入 Health Connect / 系统步数；TDEE 用活动系数 + 体重变化自适应校准。
- 内置字体 Noto Sans SC 采用 OFL。
