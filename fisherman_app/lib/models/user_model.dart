class UserBadge {
  final String id;
  final String name;
  final String icon;

  UserBadge({required this.id, required this.name, required this.icon});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🎣',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};
}

class UserStats {
  final int spotsCreated;
  final int catchesCount;
  final double totalWeightKg;
  final double maxWeightKg;
  final int favoritesCount;
  final int followersCount;
  final int followingCount;
  final List<UserBadge> badges;

  UserStats({
    this.spotsCreated = 0,
    this.catchesCount = 0,
    this.totalWeightKg = 0.0,
    this.maxWeightKg = 0.0,
    this.favoritesCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.badges = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserStats();
    return UserStats(
      spotsCreated: json['spotsCreated'] ?? 0,
      catchesCount: json['catchesCount'] ?? 0,
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
      maxWeightKg: (json['maxWeightKg'] as num?)?.toDouble() ?? 0.0,
      favoritesCount: json['favoritesCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((b) => UserBadge.fromJson(b))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'spotsCreated': spotsCreated,
    'catchesCount': catchesCount,
    'totalWeightKg': totalWeightKg,
    'maxWeightKg': maxWeightKg,
    'favoritesCount': favoritesCount,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'badges': badges.map((b) => b.toJson()).toList(),
  };
}

class UserModel {
  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final String bio;
  final int fishingYears;
  final String targetFish;
  final UserStats stats;
  final bool isFollowing;

  UserModel({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    this.bio = '永不空军，钓获放流！',
    this.fishingYears = 1,
    this.targetFish = '鲫鱼、鲤鱼',
    UserStats? stats,
    this.isFollowing = false,
  }) : stats = stats ?? UserStats();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '钓友',
      avatar: json['avatar'] ?? '',
      bio: json['bio'] ?? '永不空军，钓获放流！',
      fishingYears: json['fishing_years'] ?? json['fishingYears'] ?? 1,
      targetFish: json['target_fish'] ?? json['targetFish'] ?? '鲫鱼、鲤鱼',
      stats: UserStats.fromJson(json['stats']),
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nickname': nickname,
    'avatar': avatar,
    'bio': bio,
    'fishing_years': fishingYears,
    'target_fish': targetFish,
    'stats': stats.toJson(),
    'isFollowing': isFollowing,
  };

  UserModel copyWith({
    String? nickname,
    String? avatar,
    String? bio,
    int? fishingYears,
    String? targetFish,
    UserStats? stats,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id,
      username: username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      fishingYears: fishingYears ?? this.fishingYears,
      targetFish: targetFish ?? this.targetFish,
      stats: stats ?? this.stats,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
