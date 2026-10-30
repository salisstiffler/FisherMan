class CatchComment {
  final int id;
  final int userId;
  final String userNickname;
  final String userAvatar;
  final String content;
  final int? parentId;
  final String createdAt;

  CatchComment({
    required this.id,
    required this.userId,
    required this.userNickname,
    required this.userAvatar,
    required this.content,
    this.parentId,
    required this.createdAt,
  });

  factory CatchComment.fromJson(Map<String, dynamic> json) {
    return CatchComment(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      userNickname: json['userNickname'] ?? json['user_nickname'] ?? '钓友',
      userAvatar: json['userAvatar'] ?? json['user_avatar'] ?? '',
      content: json['content'] ?? '',
      parentId: json['parentId'] ?? json['parent_id'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}

class CatchModel {
  final int id;
  final int userId;
  final String userNickname;
  final String userAvatar;
  final int userFishingYears;
  final int? spotId;
  final String spotName;
  final String spotAddress;
  final double spotLat;
  final double spotLng;
  final String spotWaterType;
  final String spotChargeType;
  final String fishType;
  final double weightKg;
  final double lengthCm;
  final String fishingMethod;
  final double depthM;
  final String bait;
  final String? photoUrl;
  final String notes;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<CatchComment> comments;
  final String? createdAt;

  CatchModel({
    required this.id,
    required this.userId,
    required this.userNickname,
    this.userAvatar = '',
    this.userFishingYears = 1,
    this.spotId,
    required this.spotName,
    this.spotAddress = '浙江省杭州市优质垂钓水域',
    this.spotLat = 30.244,
    this.spotLng = 120.145,
    this.spotWaterType = '野钓',
    this.spotChargeType = '免费',
    required this.fishType,
    required this.weightKg,
    this.lengthCm = 0.0,
    this.fishingMethod = '台钓',
    this.depthM = 2.0,
    this.bait = '商品饵',
    this.photoUrl,
    this.notes = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.comments = const [],
    this.createdAt,
  });

  factory CatchModel.fromJson(Map<String, dynamic> json) {
    List<CatchComment> parsedComments = [];
    if (json['comments'] is List) {
      parsedComments = (json['comments'] as List)
          .map((c) => CatchComment.fromJson(c))
          .toList();
    }

    final spotName = json['spotName'] ?? json['spot_name'] ?? '神秘水域';
    final spotAddress =
        json['spotAddress'] ?? json['spot_address'] ?? '$spotName • 户外垂钓标点';
    final spotLat =
        (json['spotLat'] ?? json['spot_lat'] as num?)?.toDouble() ?? 30.244;
    final spotLng =
        (json['spotLng'] ?? json['spot_lng'] as num?)?.toDouble() ?? 120.145;

    return CatchModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      userNickname: json['userNickname'] ?? json['user_nickname'] ?? '钓友',
      userAvatar: json['userAvatar'] ?? json['user_avatar'] ?? '',
      userFishingYears:
          json['userFishingYears'] ?? json['user_fishing_years'] ?? 1,
      spotId: json['spotId'] ?? json['spot_id'],
      spotName: spotName,
      spotAddress: spotAddress,
      spotLat: spotLat,
      spotLng: spotLng,
      spotWaterType: json['spotWaterType'] ?? json['spot_water_type'] ?? '野钓',
      spotChargeType:
          json['spotChargeType'] ?? json['spot_charge_type'] ?? '免费',
      fishType: json['fishType'] ?? json['fish_type'] ?? '大鱼',
      weightKg:
          (json['weightKg'] ?? json['weight_kg'] as num?)?.toDouble() ?? 1.0,
      lengthCm:
          (json['lengthCm'] ?? json['length_cm'] as num?)?.toDouble() ?? 0.0,
      fishingMethod: json['fishingMethod'] ?? json['fishing_method'] ?? '台钓',
      depthM: (json['depthM'] ?? json['depth_m'] as num?)?.toDouble() ?? 2.0,
      bait: json['bait'] ?? '商品饵',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      notes: json['notes'] ?? '',
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      commentsCount: json['commentsCount'] ?? json['comments_count'] ?? 0,
      isLiked: json['isLiked'] ?? json['is_liked'] ?? false,
      comments: parsedComments,
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userNickname': userNickname,
    'userAvatar': userAvatar,
    'userFishingYears': userFishingYears,
    'spotId': spotId,
    'spotName': spotName,
    'spotAddress': spotAddress,
    'spotLat': spotLat,
    'spotLng': spotLng,
    'spotWaterType': spotWaterType,
    'spotChargeType': spotChargeType,
    'fishType': fishType,
    'weightKg': weightKg,
    'lengthCm': lengthCm,
    'fishingMethod': fishingMethod,
    'depthM': depthM,
    'bait': bait,
    'photoUrl': photoUrl,
    'notes': notes,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'isLiked': isLiked,
    'createdAt': createdAt,
  };

  CatchModel copyWith({
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    List<CatchComment>? comments,
    String? notes,
  }) {
    return CatchModel(
      id: id,
      userId: userId,
      userNickname: userNickname,
      userAvatar: userAvatar,
      userFishingYears: userFishingYears,
      spotId: spotId,
      spotName: spotName,
      spotAddress: spotAddress,
      spotLat: spotLat,
      spotLng: spotLng,
      spotWaterType: spotWaterType,
      spotChargeType: spotChargeType,
      fishType: fishType,
      weightKg: weightKg,
      lengthCm: lengthCm,
      fishingMethod: fishingMethod,
      depthM: depthM,
      bait: bait,
      photoUrl: photoUrl,
      notes: notes ?? this.notes,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }
}
