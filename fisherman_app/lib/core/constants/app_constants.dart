class AppConstants {
  static const String appName = '钓鱼佬';
  static const String appSlogan = '记录每一次扬竿，分享每一个大鱼时刻';

  static const String defaultApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apifisherman.berlin2026.dpdns.org',
  );

  // Target Fish Species in China
  static const List<String> popularFishList = [
    '鲫鱼',
    '翘嘴',
    '鲤鱼',
    '加州鲈',
    '鳜鱼',
    '草鱼',
    '青鱼',
    '鳙鱼(花鲢)',
    '白鲢',
    '黑鱼',
    '马口',
    '溪哥',
    '光唇鱼',
    '红尾',
    '黄颡鱼(昂刺)',
    '罗非鱼',
    '鲶鱼',
    '鳊鱼',
  ];

  // Fishing Methods
  static const List<String> fishingMethods = [
    '台钓',
    '路亚',
    '传统钓',
    '飞钓(毛钩)',
    '海竿/抛竿',
    '筏钓',
    '矶钓',
  ];

  // Water Types
  static const List<String> waterTypes = [
    '全部',
    '野钓',
    '水库',
    '溪流',
    '湖泊',
    '江河',
    '黑坑',
    '海钓',
  ];

  // Charge Types
  static const List<String> chargeTypes = [
    '全部',
    '免费',
    '按天',
    '按斤',
    '按竿',
  ];

  // Default coordinate (West Lake / Hangzhou)
  static const double defaultLat = 30.244;
  static const double defaultLng = 120.145;
}
