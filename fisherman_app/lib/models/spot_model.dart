class SpotModel {
  final int id;
  final String name;
  final String description;
  final double lat;
  final double lng;
  final String waterType;
  final String chargeType;
  final String feeDesc;
  final List<String> fishTypes;
  final double depthMeters;
  final String rules;
  final String address;
  final int? creatorId;
  final String creatorNickname;
  final String creatorAvatar;
  final String? imageUrl;
  final int likesCount;
  final int catchCount;
  final bool isFavorited;
  final double? distanceKm;
  final String? createdAt;

  SpotModel({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    this.waterType = '野钓',
    this.chargeType = '免费',
    this.feeDesc = '免费',
    this.fishTypes = const [],
    this.depthMeters = 2.0,
    this.rules = '保护水资源，垃圾带走',
    this.address = '自然水域',
    this.creatorId,
    this.creatorNickname = '钓鱼佬',
    this.creatorAvatar = '',
    this.imageUrl,
    this.likesCount = 0,
    this.catchCount = 0,
    this.isFavorited = false,
    this.distanceKm,
    this.createdAt,
  });

  factory SpotModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFish = [];
    final rawFish = json['fishTypes'] ?? json['fish_types'];
    if (rawFish is List) {
      parsedFish = rawFish.map((e) => e.toString()).toList();
    } else if (rawFish is String) {
      try {
        parsedFish = rawFish
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    return SpotModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '未命名钓点',
      description: json['description'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 30.24,
      lng: (json['lng'] as num?)?.toDouble() ?? 120.15,
      waterType: json['waterType'] ?? json['water_type'] ?? '野钓',
      chargeType: json['chargeType'] ?? json['charge_type'] ?? '免费',
      feeDesc: json['feeDesc'] ?? json['fee_desc'] ?? '免费',
      fishTypes: parsedFish,
      depthMeters: (json['depthMeters'] ?? json['depth_meters'] as num?)?.toDouble() ?? 2.0,
      rules: json['rules'] ?? '保护环境，文明作钓',
      address: json['address'] ?? '自然水域',
      creatorId: json['creatorId'] ?? json['creator_id'],
      creatorNickname: json['creatorNickname'] ?? json['creator_nickname'] ?? '钓友',
      creatorAvatar: json['creatorAvatar'] ?? json['creator_avatar'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      catchCount: json['catchCount'] ?? json['catch_count'] ?? 0,
      isFavorited: json['isFavorited'] ?? json['is_favorited'] ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'lat': lat,
        'lng': lng,
        'waterType': waterType,
        'chargeType': chargeType,
        'feeDesc': feeDesc,
        'fishTypes': fishTypes,
        'depthMeters': depthMeters,
        'rules': rules,
        'address': address,
        'creatorId': creatorId,
        'creatorNickname': creatorNickname,
        'creatorAvatar': creatorAvatar,
        'imageUrl': imageUrl,
        'likesCount': likesCount,
        'catchCount': catchCount,
        'isFavorited': isFavorited,
        'distanceKm': distanceKm,
        'createdAt': createdAt,
      };

  SpotModel copyWith({
    bool? isFavorited,
    int? likesCount,
    int? catchCount,
  }) {
    return SpotModel(
      id: id,
      name: name,
      description: description,
      lat: lat,
      lng: lng,
      waterType: waterType,
      chargeType: chargeType,
      feeDesc: feeDesc,
      fishTypes: fishTypes,
      depthMeters: depthMeters,
      rules: rules,
      address: address,
      creatorId: creatorId,
      creatorNickname: creatorNickname,
      creatorAvatar: creatorAvatar,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      catchCount: catchCount ?? this.catchCount,
      isFavorited: isFavorited ?? this.isFavorited,
      distanceKm: distanceKm,
      createdAt: createdAt,
    );
  }
}
