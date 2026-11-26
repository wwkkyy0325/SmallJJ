# SmallJJ Health

自用的个人健康数据应用（Flutter）。记录体重、饮食、经期，算出每日消耗与热量预算，
给能解释的建议。**所有数据在本机 SQLite 里，没有账号、没有埋点、Manifest 里没有任何
`uses-permission`（连 INTERNET 都没申请）。**

## 功能

| 功能 | 实现 |
|---|---|
| 体重 | 首屏第二张卡（热量卡下面）：**两颗胶囊平分一行、都点开滚轮选，没有输入框也不弹键盘**——左边是时间（默认现在，24 小时制；弹层里另一行日期用它那半边，点日期半边开三列年月日），右边是体重（整数 kg 一列、小数两位一列，25.00–300.00，滚到哪格就是哪格，可以一键跳回「上次」），下面一排保存；同一天记几次都留着，日值取均值 |
| 体重趋势 | EWMA α=0.15，缺测按天数放大 α；图上是原始点 + 趋势线 |
| 每日消耗 TDEE | Mifflin-St Jeor × 活动系数；积累 10 天以上数据后按能量平衡反解，7:3 混合、±150 kcal/天 钳制 |
| 热量预算 | `TDEE − 目标缺口`，缺口 ≤25% TDEE、摄入下限 1200/1500 kcal、BMI<18.5 关闭缺口；每日预算落库，改资料不改写历史 |
| 饮食 | 内置 84 条食物（每 100 g 参考值）+ 自建条目；每餐条目落库时快照热量 |
| 一句话记饮食 | 「两个鸡蛋一杯牛奶」→ 只归一数量与单位，热量永远取自食物库，不猜 |
| 经期 | 记录开始日，最近 ≤6 个周期取中位数 + 标准差 → 区间 + 可信度 |
| 健康分析 | 规则引擎先算事实，每条洞察带 evidence 数字，文案在本地生成 |
| 快捷入口 | `smalljj://` deep link + 长按图标 4 条快捷方式 + 通知栏磁贴「记体重」 + 系统语音播报 |

## 上手

第一次打开只填三项：出生年、身高、现在体重。活动量按「轻度」、目标按
「减脂 0.5 kg/周」起步。以后要改的一切——出生年、身高、活动量、目标、
每周变化、目标体重、经期开关、分析文案——都在「我的 → 身体资料」里，改完当天
预算立刻重算，历史快照不动。

这个应用只服务女性：没有性别这一项，BMR 固定用 Mifflin-St Jeor 的女式
（`10W + 6.25H − 5A − 161`），摄入下限 1200 kcal，经期默认开启。

## 链接入口

App 把 `smalljj://` 注册成自己的 scheme。链接里**带了数值就直接落库**，不弹表单、
不用键盘；缺参数才退回表单（时间/餐次已预选）。每次写入都留一次撤销。

> 小布只能「打开 SmallJJ」，带不了参数，也没有「打开链接」这个动作——
> 所以不要把 scheme 填进小布指令，那条路不存在。原因与替代方案见
> [`docs/手机助手接入.md`](docs/手机助手接入.md)。

| 链接 | 作用 |
|---|---|
| `smalljj://weight?time=08:00` | 打开体重弹层，时间已填 |
| `smalljj://weight?kg=59.82&time=08:00` | 直接记一次体重 |
| `smalljj://weight/59.82` | 同上，数值走路径，时间取现在 |
| `smalljj://food?meal=lunch&text=两个鸡蛋一杯牛奶` | 一句话直接记一餐 |
| `smalljj://food` | 切到饮食页并打开「一句话记饮食」 |
| `smalljj://period?action=start` | 记经期开始 |
| `smalljj://query?what=budget` | 只播报不写数据（`budget` / `weight` / `cycle` / `all`） |
| `smalljj://undo` | 撤销上一条语音写入 |
| `smalljj://today` | 回到「今天」 |

类型与参数都带中文别名（`体重` / `饮食` / `经期` / `问` / `撤销` / `首页`）。

四条触发路径（都用 `adb shell am start` / 桌面长按在手机上点过）：

```bash
# 1) adb / 任何能打开链接的地方（已实测，逐条落库）
adb shell am start -a android.intent.action.VIEW -d "smalljj://weight?kg=59.82&time=08:00"

# 2) 长按桌面图标 → 快捷方式（记体重 / 记饮食 / 今天还能吃多少 / 记经期开始）

# 3) 下拉状态栏 → 磁贴「记体重」（时间取点下去的那一刻，进 App 还能改）

# 4) 打开 App，热量卡下面那张卡直接填
```

小布语音那条路要 OPPO 意图框架准入（client_id/secret + 审核，且要上云出卡），
自用场景走不通；上面四条都不依赖它。

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
test/        105 条单测与 widget 测试（含 `typography_test.dart` 看守字号令牌）
docs/        功能调研、数据模型与算法、本轮实现与取舍、手机助手接入、真机验收
```

## 构建与测试

```bash
flutter pub get
flutter analyze          # No issues found!
flutter test             # 105 passed

# 装到手机（release 包，冷启动比 debug 快约 9 倍）
export JAVA_HOME="$HOME/dev/java/current"
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**验收只在真机做，不用模拟器**——步骤、看什么、怎么取证见
[`docs/真机验收.md`](docs/真机验收.md)。

Android 侧入口在 `android/app/src/main/kotlin/com/smalljj/health_app/MainActivity.kt`：
`singleTask` 接收 deep link，`onNewIntent` 转给 Flutter，并提供 `smalljj/intent`、
`smalljj/paths` 两个 MethodChannel。

## 已知限制

- 小布只能「打开应用」，带不了参数；ColorOS 没有公开的第三方意图调用接口，
  「一句话记体重」要 OPPO 开放平台准入。替代入口与证据见 `docs/手机助手接入.md`。
- 食物库数值是公开参考值取整，个体差异大，用户可自建条目覆盖。
- 摄入下限 1200/1500 kcal 是保守阈值，不是指南原文，界面上标明是钳制值。
- 经期「可信度」是启发式（样本量 + 标准差），不是统计置信区间。
- 未接入 Health Connect / 系统步数；TDEE 用活动系数 + 体重变化自适应校准。
- 字体不打包文件，统一用系统字族 `sans-serif` + 中文回退链；字号收敛成文字 8 级、
  数字 4 级，取值只有 `lib/theme/tokens.dart` 一处。
