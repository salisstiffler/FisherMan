import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/spot_model.dart';

class SpotsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<SpotModel> _spots = [];
  SpotModel? _selectedSpot;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedWaterType = '全部';
  String _selectedChargeType = '全部';
  String _searchKeyword = '';

  List<SpotModel> get spots => _spots;
  SpotModel? get selectedSpot => _selectedSpot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedWaterType => _selectedWaterType;
  String get selectedChargeType => _selectedChargeType;
  String get searchKeyword => _searchKeyword;

  SpotsProvider() {
    // Populate realistic default spots so UI renders beautifully even prior to server fetch
    _spots = _getFallbackSpots();
  }

  void selectSpot(SpotModel? spot) {
    _selectedSpot = spot;
    notifyListeners();
  }

  void setWaterType(String type) {
    if (_selectedWaterType != type) {
      _selectedWaterType = type;
      fetchSpots();
    }
  }

  void setChargeType(String type) {
    if (_selectedChargeType != type) {
      _selectedChargeType = type;
      fetchSpots();
    }
  }

  void setSearchKeyword(String kw) {
    _searchKeyword = kw;
    fetchSpots();
  }

  Future<void> fetchSpots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedWaterType != '全部') {
        queryParams['water_type'] = _selectedWaterType;
      }
      if (_selectedChargeType != '全部') {
        queryParams['charge_type'] = _selectedChargeType;
      }
      if (_searchKeyword.isNotEmpty) queryParams['keyword'] = _searchKeyword;

      final res = await _api.get(ApiEndpoints.spots, queryParams: queryParams);

      if (res.success && res.data is List) {
        _spots = (res.data as List)
            .map((json) => SpotModel.fromJson(json))
            .toList();
      } else {
        // Fallback filtering in memory if server is offline
        _spots = _getFallbackSpots().where((s) {
          final matchesWater =
              _selectedWaterType == '全部' || s.waterType == _selectedWaterType;
          final matchesCharge =
              _selectedChargeType == '全部' ||
              s.chargeType == _selectedChargeType;
          final matchesKw =
              _searchKeyword.isEmpty ||
              s.name.contains(_searchKeyword) ||
              s.description.contains(_searchKeyword) ||
              s.address.contains(_searchKeyword);
          return matchesWater && matchesCharge && matchesKw;
        }).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSpot({
    required String name,
    required String description,
    required double lat,
    required double lng,
    required String waterType,
    required String chargeType,
    required String feeDesc,
    required List<String> fishTypes,
    required double depthMeters,
    required String rules,
    required String address,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.spots,
        body: {
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
          'imageUrl': imageUrl,
        },
      );

      if (res.success) {
        await fetchSpots();
        return true;
      }

      // If server unavailable, add locally
      final newLocalSpot = SpotModel(
        id: DateTime.now().millisecondsSinceEpoch,
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
        imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
        creatorNickname: '我标记的钓点',
      );
      _spots.insert(0, newLocalSpot);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(int spotId) async {
    final index = _spots.indexWhere((s) => s.id == spotId);
    if (index != -1) {
      final current = _spots[index];
      final newStatus = !current.isFavorited;
      _spots[index] = current.copyWith(
        isFavorited: newStatus,
        likesCount: newStatus
            ? current.likesCount + 1
            : (current.likesCount > 0 ? current.likesCount - 1 : 0),
      );
      if (_selectedSpot?.id == spotId) {
        _selectedSpot = _spots[index];
      }
      notifyListeners();
    }

    try {
      await _api.post(ApiEndpoints.toggleFavorite(spotId));
    } catch (_) {}
  }

  Future<bool> updateSpot(int spotId, {required String description}) async {
    final res = await _api.put(
      ApiEndpoints.updateSpot(spotId),
      body: {'description': description},
    );
    if (!res.success) return false;
    await fetchSpots();
    return true;
  }

  Future<bool> deleteSpot(int spotId) async {
    final res = await _api.delete(ApiEndpoints.deleteSpot(spotId));
    if (!res.success) return false;
    _spots.removeWhere((item) => item.id == spotId);
    notifyListeners();
    return true;
  }

  List<SpotModel> _getFallbackSpots() {
    return [
      SpotModel(
        id: 1,
        name: '千岛湖羡山半岛野钓点',
        description: '水质清澈见底达一类标准，缓坡铧尖位出鱼极好。清晨与傍晚翘嘴频繁炸水，底层常有大草鱼与青鱼巡游。',
        lat: 29.5623,
        lng: 119.0432,
        waterType: '野钓',
        chargeType: '免费',
        feeDesc: '免费开放水域',
        fishTypes: ['翘嘴', '鳙鱼', '草鱼', '青鱼', '鳜鱼'],
        depthMeters: 5.5,
        rules: '请带走塑料袋饵料袋，严禁使用活体泥鳅打窝',
        address: '浙江省杭州市淳安县千岛湖羡山半岛环湖步道',
        creatorNickname: '空军总司令',
        imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
        likesCount: 42,
        catchCount: 15,
      ),
      SpotModel(
        id: 2,
        name: '富春江芦茨湾溪流慢步道',
        description: '水质甘甜，风景如画的慢生活休闲体验区。水流平缓与乱石交错处是马口与光唇鱼绝佳标点，微物路亚或毛钩飞钓胜地。',
        lat: 29.7421,
        lng: 119.6845,
        waterType: '溪流',
        chargeType: '免费',
        feeDesc: '完全免费',
        fishTypes: ['马口', '溪哥', '光唇鱼', '红尾'],
        depthMeters: 2.2,
        rules: '卵石湿滑请穿防滑涉水鞋，雷雨天切勿近水',
        address: '浙江省桐庐县富春江镇芦茨村溪畔',
        creatorNickname: '溪流微物小圆',
        imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=600',
        likesCount: 28,
        catchCount: 8,
      ),
      SpotModel(
        id: 3,
        name: '湘湖三期野钓长廊',
        description: '水域宽阔，水草丰美。两岸有栈道和防晒垂钓台，适合 3.6m~4.5m 传统钓与台钓，大板鲫和昂刺鱼密集。',
        lat: 30.1342,
        lng: 120.2115,
        waterType: '野钓',
        chargeType: '免费',
        feeDesc: '免费开放',
        fishTypes: ['鲫鱼', '鲤鱼', '黄颡鱼', '黑鱼'],
        depthMeters: 2.8,
        rules: '一人限双竿，文明垂钓，不可使用倒刺三本钩',
        address: '浙江省杭州市萧山区湘湖路越王城下',
        creatorNickname: '空军总司令',
        imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600',
        likesCount: 35,
        catchCount: 12,
      ),
      SpotModel(
        id: 4,
        name: '青山湖水上森林路亚基地',
        description: '国内知名路亚胜地，拥有独特的水上杉树林湿地。水草区与枯树桩周围潜伏大量加州鲈、凶猛黑鱼和大型鳜鱼。',
        lat: 30.2458,
        lng: 119.7824,
        waterType: '水库',
        chargeType: '按天',
        feeDesc: '100元/天 (含路亚艇租借优惠)',
        fishTypes: ['加州鲈', '鳜鱼', '黑鱼', '翘嘴'],
        depthMeters: 4.0,
        rules: '倡导路亚 C&R (钓获放流)，不得私藏超标幼鱼',
        address: '浙江省杭州市临安区青山湖国家森林公园',
        creatorNickname: '路亚狂徒小林',
        imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600',
        likesCount: 56,
        catchCount: 22,
      ),
    ];
  }
}
