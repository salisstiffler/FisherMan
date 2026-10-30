import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/catch_model.dart';

class CatchesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<CatchModel> _catches = [];
  List<CatchModel> _myCatches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  static const int _pageSize = 20;
  String? _errorMessage;
  String _selectedFishFilter = '全部';

  List<CatchModel> get catches => _catches;
  List<CatchModel> get myCatches => _myCatches;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get selectedFishFilter => _selectedFishFilter;

  CatchesProvider() {
    _catches = _getFallbackCatches();
  }

  void setFishFilter(String fish) {
    if (_selectedFishFilter != fish) {
      _selectedFishFilter = fish;
      fetchCatches();
    }
  }

  Future<void> fetchCatches({bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore || (loadMore && !_hasMore)) return;
    if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _hasMore = true;
      _nextOffset = 0;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedFishFilter != '全部') {
        queryParams['fishType'] = _selectedFishFilter;
      }
      queryParams['limit'] = _pageSize;
      queryParams['offset'] = loadMore ? _nextOffset : 0;

      final res = await _api.get(
        ApiEndpoints.catches,
        queryParams: queryParams,
      );

      if (res.success && res.data is List) {
        final page = (res.data as List)
            .map((json) => CatchModel.fromJson(json))
            .toList();
        if (loadMore) {
          _catches.addAll(page);
        } else {
          _catches = page;
        }
        _nextOffset += page.length;
        _hasMore = page.length == _pageSize;
      } else if (!loadMore) {
        // Fallback filter locally
        _catches = _getFallbackCatches().where((c) {
          if (_selectedFishFilter == '全部') return true;
          return c.fishType.contains(_selectedFishFilter);
        }).toList();
        _hasMore = false;
      } else {
        _errorMessage = res.message;
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchCatchDetail(int catchId) async {
    final response = await _api.get(ApiEndpoints.catchDetail(catchId));
    if (!response.success || response.data is! Map) return;
    final item = CatchModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    final index = _catches.indexWhere((catchItem) => catchItem.id == catchId);
    if (index == -1) {
      _catches.insert(0, item);
    } else {
      _catches[index] = item;
    }
    notifyListeners();
  }

  Future<void> fetchMyCatches(int userId) async {
    final response = await _api.get(
      ApiEndpoints.catches,
      queryParams: {'userId': userId, 'limit': 100},
    );
    if (!response.success || response.data is! List) return;
    _myCatches = (response.data as List)
        .map((item) => CatchModel.fromJson(item))
        .toList();
    notifyListeners();
  }

  Future<bool> publishCatch({
    int? spotId,
    required String spotName,
    String spotAddress = '杭州市自然水域',
    double spotLat = 30.244,
    double spotLng = 120.145,
    String spotWaterType = '野钓',
    String spotChargeType = '免费',
    required String fishType,
    required double weightKg,
    double lengthCm = 0.0,
    String fishingMethod = '台钓',
    double depthM = 2.0,
    String bait = '商品饵',
    String? photoUrl,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.catches,
        body: {
          'spotId': spotId,
          'spotName': spotName,
          'spotAddress': spotAddress,
          'spotLat': spotLat,
          'spotLng': spotLng,
          'fishType': fishType,
          'weightKg': weightKg,
          'lengthCm': lengthCm,
          'fishingMethod': fishingMethod,
          'depthM': depthM,
          'bait': bait,
          'photoUrl': photoUrl,
          'notes': notes,
        },
      );

      if (res.success) {
        await fetchCatches();
        return true;
      }

      // Offline fallback: insert local catch record
      final newLocalCatch = CatchModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        userNickname: '我',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        userFishingYears: 2,
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
        photoUrl:
            photoUrl ??
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
        notes: notes,
        createdAt: '刚刚',
      );
      _catches.insert(0, newLocalCatch);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(int catchId) async {
    final index = _catches.indexWhere((c) => c.id == catchId);
    if (index != -1) {
      final current = _catches[index];
      final newLiked = !current.isLiked;
      _catches[index] = current.copyWith(
        isLiked: newLiked,
        likesCount: newLiked
            ? current.likesCount + 1
            : (current.likesCount > 0 ? current.likesCount - 1 : 0),
      );
      notifyListeners();
    }

    try {
      await _api.post(ApiEndpoints.toggleLike(catchId));
    } catch (_) {}
  }

  Future<bool> addComment(int catchId, String content, {int? parentId}) async {
    try {
      final body = <String, dynamic>{'content': content};
      if (parentId != null) body['parentId'] = parentId;
      final res = await _api.post(ApiEndpoints.addComment(catchId), body: body);
      if (!res.success) return false;
      await fetchCatchDetail(catchId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCatch(int catchId, {required String notes}) async {
    final res = await _api.put(
      ApiEndpoints.updateCatch(catchId),
      body: {'notes': notes},
    );
    if (!res.success) return false;
    for (final catches in [_catches, _myCatches]) {
      final index = catches.indexWhere((item) => item.id == catchId);
      if (index != -1) {
        catches[index] = catches[index].copyWith(notes: notes);
      }
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteCatch(int catchId) async {
    final res = await _api.delete(ApiEndpoints.deleteCatch(catchId));
    if (!res.success) return false;
    _catches.removeWhere((item) => item.id == catchId);
    _myCatches.removeWhere((item) => item.id == catchId);
    notifyListeners();
    return true;
  }

  Future<bool> deleteComment(int catchId, int commentId) async {
    final response = await _api.delete(
      ApiEndpoints.deleteComment(catchId, commentId),
    );
    if (!response.success) return false;
    await fetchCatchDetail(catchId);
    return true;
  }

  List<CatchModel> _getFallbackCatches() {
    return [
      CatchModel(
        id: 1,
        userId: 2,
        userNickname: '路亚狂徒小林',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        userFishingYears: 6,
        spotId: 1,
        spotName: '千岛湖羡山半岛野钓点',
        spotAddress: '浙江省杭州市淳安县千岛湖羡山半岛环湖步道',
        spotLat: 29.5623,
        spotLng: 119.0432,
        spotWaterType: '野钓',
        spotChargeType: '免费',
        fishType: '翘嘴',
        weightKg: 7.8,
        lengthCm: 86.5,
        fishingMethod: '路亚',
        depthM: 4.5,
        bait: '14g 沉水米诺 (银背雷射)',
        photoUrl:
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
        notes: '清晨5点40分第一竿！在铧尖外侧水流交汇处一口爆截，线杯出线如同尖叫！溜了足足八分钟才入抄网，太爽了！',
        likesCount: 89,
        commentsCount: 3,
        createdAt: '2小时前',
        comments: [
          CatchComment(
            id: 1,
            userId: 1,
            userNickname: '空军总司令',
            userAvatar: '',
            content: '太强了林大师！这个米诺什么克数？下次一起冲千岛湖！',
            createdAt: '1小时前',
          ),
          CatchComment(
            id: 2,
            userId: 3,
            userNickname: '千岛湖老钓客',
            userAvatar: '',
            content: '大翘嘴水上洗鳃那一下最刺激，恭喜破个人记录！',
            createdAt: '40分钟前',
          ),
        ],
      ),
      CatchModel(
        id: 2,
        userId: 1,
        userNickname: '空军总司令',
        userAvatar:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        userFishingYears: 15,
        spotId: 3,
        spotName: '湘湖三期野钓长廊',
        spotAddress: '浙江省杭州市萧山区湘湖路越王城下亲水平台',
        spotLat: 30.1342,
        spotLng: 120.2115,
        spotWaterType: '野钓',
        spotChargeType: '免费',
        fishType: '鲫鱼',
        weightKg: 1.35,
        lengthCm: 33.0,
        fishingMethod: '台钓',
        depthM: 2.5,
        bait: '自制酒米打窝 + 蓝鲫单开',
        photoUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600',
        notes: '入秋后的黄金大板鲫，手感沉稳压手！漂相先轻轻上浮两目，然后稳稳下顿，提竿中鱼，手感极为美妙！',
        likesCount: 46,
        commentsCount: 1,
        createdAt: '4小时前',
      ),
      CatchModel(
        id: 3,
        userId: 2,
        userNickname: '路亚狂徒小林',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        userFishingYears: 6,
        spotId: 4,
        spotName: '青山湖水上森林路亚基地',
        spotAddress: '浙江省杭州市临安区青山湖国家森林公园水杉湿地',
        spotLat: 30.2458,
        spotLng: 119.7824,
        spotWaterType: '水库',
        spotChargeType: '按天',
        fishType: '加州鲈',
        weightKg: 2.4,
        lengthCm: 48.0,
        fishingMethod: '路亚',
        depthM: 3.0,
        bait: '3.5寸 T尾软虫 + 德州钓组',
        photoUrl: 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=600',
        notes: '水杉根部标点精细作钓。轻跳两下后顿感一重，扬竿瞬间水花四溅洗鳃！拍照后已经安全放流！',
        likesCount: 63,
        commentsCount: 2,
        createdAt: '昨天',
      ),
      CatchModel(
        id: 4,
        userId: 4,
        userNickname: '溪流微物小圆',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        userFishingYears: 3,
        spotId: 2,
        spotName: '富春江芦茨湾溪流慢步道',
        spotAddress: '浙江省桐庐县富春江镇芦茨村溪畔亲水步道',
        spotLat: 29.7421,
        spotLng: 119.6845,
        spotWaterType: '溪流',
        spotChargeType: '免费',
        fishType: '马口',
        weightKg: 0.28,
        lengthCm: 22.0,
        fishingMethod: '飞钓(毛钩)',
        depthM: 1.2,
        bait: '#16号鹿毛干蝇',
        photoUrl: 'https://images.unsplash.com/photo-1508873696983-2df5293cb325?w=600',
        notes: '婚姻色极度绚烂的雄性大公马口！落蝇入水瞬间从卵石底冲上来抢食，溪流水质清澈，视觉冲击力拉满！',
        likesCount: 77,
        commentsCount: 4,
        createdAt: '2天前',
      ),
    ];
  }
}
