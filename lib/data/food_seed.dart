/// 食物库种子。**数值是常见参考值（每 100 g 可食部），不是检测报告**，
/// 来源为公开发表的食物成分数据与包装营养表的常见区间，取整到一位小数。
///
/// 为什么自建而不是打包《中国食物成分表》：第 6 版有版权，只能内部核对。
/// 用户可以在 App 里新建自己的条目，覆盖任何一条不准的值。
typedef SeedFood = ({
  String name,
  String? alias,
  String? pinyin,
  double kcal,
  double protein,
  double carb,
  double fat,
  double portion,
  String portionLabel,
});

const List<SeedFood> foodSeeds = [
  // ── 主食 ──────────────────────────────────────────────
  (
    name: '米饭',
    alias: '白米饭',
    pinyin: 'mifan',
    kcal: 116,
    protein: 2.6,
    carb: 25.9,
    fat: 0.3,
    portion: 150,
    portionLabel: '碗'
  ),
  (
    name: '馒头',
    alias: null,
    pinyin: 'mantou',
    kcal: 223,
    protein: 7,
    carb: 47,
    fat: 1.1,
    portion: 100,
    portionLabel: '个'
  ),
  (
    name: '面条',
    alias: '煮面',
    pinyin: 'miantiao',
    kcal: 110,
    protein: 4.5,
    carb: 24,
    fat: 0.5,
    portion: 200,
    portionLabel: '碗'
  ),
  (
    name: '全麦面包',
    alias: '吐司',
    pinyin: 'quanmaimianbao',
    kcal: 246,
    protein: 9,
    carb: 45,
    fat: 3.5,
    portion: 35,
    portionLabel: '片'
  ),
  (
    name: '燕麦片',
    alias: '燕麦',
    pinyin: 'yanmaipian',
    kcal: 377,
    protein: 13,
    carb: 66,
    fat: 6.7,
    portion: 40,
    portionLabel: '份'
  ),
  (
    name: '玉米',
    alias: '煮玉米',
    pinyin: 'yumi',
    kcal: 112,
    protein: 4,
    carb: 22.8,
    fat: 1.2,
    portion: 150,
    portionLabel: '根'
  ),
  (
    name: '红薯',
    alias: '地瓜',
    pinyin: 'hongshu',
    kcal: 86,
    protein: 1.6,
    carb: 20,
    fat: 0.2,
    portion: 150,
    portionLabel: '个'
  ),
  (
    name: '土豆',
    alias: '马铃薯',
    pinyin: 'tudou',
    kcal: 77,
    protein: 2,
    carb: 17,
    fat: 0.1,
    portion: 120,
    portionLabel: '个'
  ),
  (
    name: '山药',
    alias: null,
    pinyin: 'shanyao',
    kcal: 57,
    protein: 1.9,
    carb: 12.4,
    fat: 0.2,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '油条',
    alias: null,
    pinyin: 'youtiao',
    kcal: 388,
    protein: 6.9,
    carb: 51,
    fat: 17.6,
    portion: 60,
    portionLabel: '根'
  ),
  (
    name: '包子',
    alias: '肉包',
    pinyin: 'baozi',
    kcal: 227,
    protein: 8,
    carb: 28,
    fat: 9,
    portion: 80,
    portionLabel: '个'
  ),
  (
    name: '饺子',
    alias: '水饺',
    pinyin: 'jiaozi',
    kcal: 240,
    protein: 9,
    carb: 26,
    fat: 11,
    portion: 20,
    portionLabel: '个'
  ),
  (
    name: '白粥',
    alias: '稀饭',
    pinyin: 'baizhou',
    kcal: 46,
    protein: 1.1,
    carb: 9.9,
    fat: 0.2,
    portion: 300,
    portionLabel: '碗'
  ),
  (
    name: '米粉',
    alias: '河粉',
    pinyin: 'mifen',
    kcal: 109,
    protein: 2.6,
    carb: 24,
    fat: 0.5,
    portion: 200,
    portionLabel: '碗'
  ),

  // ── 蛋白质 ────────────────────────────────────────────
  (
    name: '鸡蛋',
    alias: '蛋',
    pinyin: 'jidan',
    kcal: 144,
    protein: 13.3,
    carb: 2.8,
    fat: 8.8,
    portion: 50,
    portionLabel: '个'
  ),
  (
    name: '蛋清',
    alias: '蛋白',
    pinyin: 'danqing',
    kcal: 60,
    protein: 11.6,
    carb: 3.1,
    fat: 0.1,
    portion: 30,
    portionLabel: '个'
  ),
  (
    name: '牛奶',
    alias: '全脂牛奶',
    pinyin: 'niunai',
    kcal: 54,
    protein: 3,
    carb: 3.4,
    fat: 3.2,
    portion: 250,
    portionLabel: '杯'
  ),
  (
    name: '脱脂牛奶',
    alias: null,
    pinyin: 'tuozhiniunai',
    kcal: 33,
    protein: 3.4,
    carb: 5,
    fat: 0.1,
    portion: 250,
    portionLabel: '杯'
  ),
  (
    name: '无糖酸奶',
    alias: '酸奶',
    pinyin: 'suannai',
    kcal: 60,
    protein: 3.2,
    carb: 4.7,
    fat: 3.2,
    portion: 150,
    portionLabel: '杯'
  ),
  (
    name: '希腊酸奶',
    alias: null,
    pinyin: 'xilasuannai',
    kcal: 97,
    protein: 9,
    carb: 4,
    fat: 5,
    portion: 150,
    portionLabel: '杯'
  ),
  (
    name: '豆浆',
    alias: '无糖豆浆',
    pinyin: 'doujiang',
    kcal: 31,
    protein: 3,
    carb: 1.2,
    fat: 1.6,
    portion: 250,
    portionLabel: '杯'
  ),
  (
    name: '北豆腐',
    alias: '老豆腐',
    pinyin: 'beidoufu',
    kcal: 98,
    protein: 12.2,
    carb: 1.5,
    fat: 4.8,
    portion: 100,
    portionLabel: '块'
  ),
  (
    name: '南豆腐',
    alias: '嫩豆腐',
    pinyin: 'nandoufu',
    kcal: 57,
    protein: 6.2,
    carb: 2.4,
    fat: 2.5,
    portion: 100,
    portionLabel: '块'
  ),
  (
    name: '鸡胸肉',
    alias: '鸡胸',
    pinyin: 'jixiongrou',
    kcal: 133,
    protein: 24.6,
    carb: 0.6,
    fat: 5,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '鸡腿肉',
    alias: '鸡腿',
    pinyin: 'jituirou',
    kcal: 181,
    protein: 16,
    carb: 0,
    fat: 13,
    portion: 100,
    portionLabel: '个'
  ),
  (
    name: '瘦牛肉',
    alias: '牛肉',
    pinyin: 'shouniurou',
    kcal: 106,
    protein: 20.2,
    carb: 1.2,
    fat: 2.3,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '猪里脊',
    alias: '里脊肉',
    pinyin: 'zhuliji',
    kcal: 155,
    protein: 20.2,
    carb: 0.8,
    fat: 7.9,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '五花肉',
    alias: null,
    pinyin: 'wuhuarou',
    kcal: 508,
    protein: 7.7,
    carb: 0,
    fat: 53,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '三文鱼',
    alias: null,
    pinyin: 'sanwenyu',
    kcal: 208,
    protein: 20,
    carb: 0,
    fat: 13,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '鲈鱼',
    alias: null,
    pinyin: 'luyu',
    kcal: 105,
    protein: 18.6,
    carb: 0,
    fat: 3.4,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '虾',
    alias: '基围虾',
    pinyin: 'xia',
    kcal: 93,
    protein: 18.6,
    carb: 2.8,
    fat: 0.8,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '金枪鱼罐头',
    alias: '吞拿鱼',
    pinyin: 'jinqiangyu',
    kcal: 116,
    protein: 26,
    carb: 0,
    fat: 1,
    portion: 100,
    portionLabel: '罐'
  ),
  (
    name: '火腿肠',
    alias: null,
    pinyin: 'huotuichang',
    kcal: 212,
    protein: 14,
    carb: 10,
    fat: 13,
    portion: 50,
    portionLabel: '根'
  ),
  (
    name: '蛋白粉',
    alias: '乳清蛋白',
    pinyin: 'danbaifen',
    kcal: 400,
    protein: 80,
    carb: 5,
    fat: 5,
    portion: 30,
    portionLabel: '勺'
  ),

  // ── 蔬菜 ──────────────────────────────────────────────
  (
    name: '西兰花',
    alias: null,
    pinyin: 'xilanhua',
    kcal: 34,
    protein: 4.1,
    carb: 4.3,
    fat: 0.6,
    portion: 150,
    portionLabel: '份'
  ),
  (
    name: '菠菜',
    alias: null,
    pinyin: 'bocai',
    kcal: 24,
    protein: 2.6,
    carb: 4.5,
    fat: 0.3,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '生菜',
    alias: null,
    pinyin: 'shengcai',
    kcal: 13,
    protein: 1.3,
    carb: 2,
    fat: 0.3,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '番茄',
    alias: '西红柿',
    pinyin: 'fanqie',
    kcal: 15,
    protein: 0.9,
    carb: 3.3,
    fat: 0.2,
    portion: 150,
    portionLabel: '个'
  ),
  (
    name: '黄瓜',
    alias: null,
    pinyin: 'huanggua',
    kcal: 15,
    protein: 0.8,
    carb: 2.9,
    fat: 0.2,
    portion: 150,
    portionLabel: '根'
  ),
  (
    name: '胡萝卜',
    alias: null,
    pinyin: 'huluobo',
    kcal: 39,
    protein: 1,
    carb: 8.8,
    fat: 0.2,
    portion: 100,
    portionLabel: '根'
  ),
  (
    name: '大白菜',
    alias: '白菜',
    pinyin: 'dabaicai',
    kcal: 17,
    protein: 1.5,
    carb: 3.2,
    fat: 0.1,
    portion: 150,
    portionLabel: '份'
  ),
  (
    name: '茄子',
    alias: null,
    pinyin: 'qiezi',
    kcal: 21,
    protein: 1.1,
    carb: 4.9,
    fat: 0.2,
    portion: 150,
    portionLabel: '个'
  ),
  (
    name: '香菇',
    alias: null,
    pinyin: 'xianggu',
    kcal: 26,
    protein: 2.2,
    carb: 5.2,
    fat: 0.3,
    portion: 50,
    portionLabel: '份'
  ),
  (
    name: '洋葱',
    alias: null,
    pinyin: 'yangcong',
    kcal: 39,
    protein: 1.1,
    carb: 9,
    fat: 0.2,
    portion: 100,
    portionLabel: '个'
  ),
  (
    name: '青椒',
    alias: '柿子椒',
    pinyin: 'qingjiao',
    kcal: 22,
    protein: 1,
    carb: 5.4,
    fat: 0.2,
    portion: 100,
    portionLabel: '个'
  ),

  // ── 水果 ──────────────────────────────────────────────
  (
    name: '苹果',
    alias: null,
    pinyin: 'pingguo',
    kcal: 53,
    protein: 0.2,
    carb: 13.5,
    fat: 0.2,
    portion: 200,
    portionLabel: '个'
  ),
  (
    name: '香蕉',
    alias: null,
    pinyin: 'xiangjiao',
    kcal: 93,
    protein: 1.4,
    carb: 22,
    fat: 0.2,
    portion: 120,
    portionLabel: '根'
  ),
  (
    name: '橙子',
    alias: '橙',
    pinyin: 'chengzi',
    kcal: 48,
    protein: 0.8,
    carb: 11.1,
    fat: 0.2,
    portion: 200,
    portionLabel: '个'
  ),
  (
    name: '蓝莓',
    alias: null,
    pinyin: 'lanmei',
    kcal: 57,
    protein: 0.7,
    carb: 14.5,
    fat: 0.3,
    portion: 100,
    portionLabel: '盒'
  ),
  (
    name: '西瓜',
    alias: null,
    pinyin: 'xigua',
    kcal: 26,
    protein: 0.6,
    carb: 5.8,
    fat: 0.1,
    portion: 300,
    portionLabel: '份'
  ),
  (
    name: '葡萄',
    alias: null,
    pinyin: 'putao',
    kcal: 43,
    protein: 0.5,
    carb: 10.3,
    fat: 0.2,
    portion: 150,
    portionLabel: '份'
  ),
  (
    name: '草莓',
    alias: null,
    pinyin: 'caomei',
    kcal: 32,
    protein: 1,
    carb: 7.1,
    fat: 0.2,
    portion: 150,
    portionLabel: '份'
  ),
  (
    name: '猕猴桃',
    alias: null,
    pinyin: 'mihoutao',
    kcal: 56,
    protein: 0.8,
    carb: 14.5,
    fat: 0.6,
    portion: 100,
    portionLabel: '个'
  ),
  (
    name: '梨',
    alias: null,
    pinyin: 'li',
    kcal: 51,
    protein: 0.4,
    carb: 13.3,
    fat: 0.2,
    portion: 200,
    portionLabel: '个'
  ),

  // ── 坚果 / 油脂 ───────────────────────────────────────
  (
    name: '花生',
    alias: null,
    pinyin: 'huasheng',
    kcal: 574,
    protein: 24,
    carb: 16,
    fat: 44,
    portion: 20,
    portionLabel: '把'
  ),
  (
    name: '核桃',
    alias: null,
    pinyin: 'hetao',
    kcal: 646,
    protein: 14.9,
    carb: 19.1,
    fat: 58.8,
    portion: 20,
    portionLabel: '个'
  ),
  (
    name: '杏仁',
    alias: null,
    pinyin: 'xingren',
    kcal: 578,
    protein: 21,
    carb: 20,
    fat: 50,
    portion: 20,
    portionLabel: '把'
  ),
  (
    name: '橄榄油',
    alias: null,
    pinyin: 'ganlanyou',
    kcal: 899,
    protein: 0,
    carb: 0,
    fat: 99.9,
    portion: 10,
    portionLabel: '勺'
  ),
  (
    name: '花生油',
    alias: '食用油',
    pinyin: 'huashengyou',
    kcal: 899,
    protein: 0,
    carb: 0,
    fat: 99.9,
    portion: 10,
    portionLabel: '勺'
  ),
  (
    name: '黄油',
    alias: null,
    pinyin: 'huangyou',
    kcal: 717,
    protein: 0.9,
    carb: 0.1,
    fat: 81,
    portion: 10,
    portionLabel: '块'
  ),
  (
    name: '芝麻酱',
    alias: null,
    pinyin: 'zhimajiang',
    kcal: 618,
    protein: 19,
    carb: 16,
    fat: 52,
    portion: 15,
    portionLabel: '勺'
  ),

  // ── 饮品 / 甜食 ───────────────────────────────────────
  (
    name: '可乐',
    alias: null,
    pinyin: 'kele',
    kcal: 43,
    protein: 0,
    carb: 10.6,
    fat: 0,
    portion: 330,
    portionLabel: '罐'
  ),
  (
    name: '无糖可乐',
    alias: '零度可乐',
    pinyin: 'wutangkele',
    kcal: 0,
    protein: 0,
    carb: 0,
    fat: 0,
    portion: 330,
    portionLabel: '罐'
  ),
  (
    name: '美式咖啡',
    alias: '黑咖啡',
    pinyin: 'meishikafei',
    kcal: 2,
    protein: 0.2,
    carb: 0.3,
    fat: 0,
    portion: 300,
    portionLabel: '杯'
  ),
  (
    name: '拿铁',
    alias: '拿铁咖啡',
    pinyin: 'natie',
    kcal: 55,
    protein: 3,
    carb: 4.5,
    fat: 3,
    portion: 350,
    portionLabel: '杯'
  ),
  (
    name: '啤酒',
    alias: null,
    pinyin: 'pijiu',
    kcal: 32,
    protein: 0.3,
    carb: 3,
    fat: 0,
    portion: 500,
    portionLabel: '瓶'
  ),
  (
    name: '奶茶',
    alias: '珍珠奶茶',
    pinyin: 'naicha',
    kcal: 76,
    protein: 1,
    carb: 15,
    fat: 1.5,
    portion: 500,
    portionLabel: '杯'
  ),
  (
    name: '橙汁',
    alias: '果汁',
    pinyin: 'chengzhi',
    kcal: 45,
    protein: 0.7,
    carb: 10.4,
    fat: 0.2,
    portion: 250,
    portionLabel: '杯'
  ),
  (
    name: '白砂糖',
    alias: '糖',
    pinyin: 'baishatang',
    kcal: 400,
    protein: 0,
    carb: 99.9,
    fat: 0,
    portion: 5,
    portionLabel: '勺'
  ),
  (
    name: '蜂蜜',
    alias: null,
    pinyin: 'fengmi',
    kcal: 321,
    protein: 0.4,
    carb: 75.6,
    fat: 1.9,
    portion: 15,
    portionLabel: '勺'
  ),
  (
    name: '薯片',
    alias: null,
    pinyin: 'shupian',
    kcal: 536,
    protein: 6.6,
    carb: 53,
    fat: 34,
    portion: 30,
    portionLabel: '包'
  ),
  (
    name: '牛奶巧克力',
    alias: '巧克力',
    pinyin: 'qiaokeli',
    kcal: 535,
    protein: 7.7,
    carb: 59,
    fat: 29.7,
    portion: 20,
    portionLabel: '块'
  ),
  (
    name: '苏打饼干',
    alias: '饼干',
    pinyin: 'sudabinggan',
    kcal: 408,
    protein: 8.4,
    carb: 76,
    fat: 7.7,
    portion: 25,
    portionLabel: '片'
  ),
  (
    name: '奶油蛋糕',
    alias: '蛋糕',
    pinyin: 'naiyouDangao',
    kcal: 347,
    protein: 6,
    carb: 47,
    fat: 15,
    portion: 80,
    portionLabel: '块'
  ),

  // ── 常见成品菜 ────────────────────────────────────────
  (
    name: '番茄炒蛋',
    alias: '西红柿炒鸡蛋',
    pinyin: 'fanqiechaodan',
    kcal: 86,
    protein: 4.7,
    carb: 3.7,
    fat: 5.6,
    portion: 200,
    portionLabel: '份'
  ),
  (
    name: '清炒时蔬',
    alias: '炒青菜',
    pinyin: 'qingchaoshishu',
    kcal: 55,
    protein: 1.8,
    carb: 4,
    fat: 3.5,
    portion: 200,
    portionLabel: '份'
  ),
  (
    name: '红烧肉',
    alias: null,
    pinyin: 'hongshaorou',
    kcal: 471,
    protein: 9,
    carb: 3,
    fat: 46,
    portion: 100,
    portionLabel: '份'
  ),
  (
    name: '麻婆豆腐',
    alias: null,
    pinyin: 'mapodoufu',
    kcal: 116,
    protein: 8,
    carb: 4,
    fat: 7.5,
    portion: 200,
    portionLabel: '份'
  ),
  (
    name: '宫保鸡丁',
    alias: null,
    pinyin: 'gongbaojiding',
    kcal: 189,
    protein: 14,
    carb: 9,
    fat: 11,
    portion: 200,
    portionLabel: '份'
  ),
  (
    name: '蛋炒饭',
    alias: '炒饭',
    pinyin: 'danchaofan',
    kcal: 186,
    protein: 5,
    carb: 26,
    fat: 6.5,
    portion: 300,
    portionLabel: '份'
  ),
  (
    name: '兰州拉面',
    alias: '牛肉面',
    pinyin: 'lanzhoulamian',
    kcal: 120,
    protein: 5,
    carb: 20,
    fat: 2.5,
    portion: 500,
    portionLabel: '碗'
  ),
  (
    name: '麻辣烫',
    alias: null,
    pinyin: 'malatang',
    kcal: 90,
    protein: 4,
    carb: 6,
    fat: 5,
    portion: 400,
    portionLabel: '份'
  ),
  (
    name: '紫菜蛋花汤',
    alias: null,
    pinyin: 'zicaidanhuatang',
    kcal: 30,
    protein: 2,
    carb: 2,
    fat: 1.5,
    portion: 300,
    portionLabel: '碗'
  ),
  (
    name: '皮蛋瘦肉粥',
    alias: null,
    pinyin: 'pidanshourouzhou',
    kcal: 60,
    protein: 3,
    carb: 8,
    fat: 1.5,
    portion: 300,
    portionLabel: '碗'
  ),
];
