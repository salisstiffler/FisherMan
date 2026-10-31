import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/catch_model.dart';
import '../../models/spot_model.dart';
import '../../models/user_model.dart';
import '../feed/catch_detail_screen.dart';
import '../map/spot_detail_screen.dart';
import 'follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late final TabController _tabController;
  UserModel? _user;
  List<CatchModel> _catches = [];
  List<SpotModel> _spots = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isUpdatingFollow = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _api.get(ApiEndpoints.userProfile(widget.userId)),
        _api.get(ApiEndpoints.catches, queryParams: {'userId': widget.userId}),
        _api.get(ApiEndpoints.spots, queryParams: {'creatorId': widget.userId}),
      ]);
      if (!mounted) return;
      final profileResponse = responses[0];
      if (!profileResponse.success || profileResponse.data is! Map) {
        setState(() {
          _error = profileResponse.message;
          _isLoading = false;
        });
        return;
      }

      final user = UserModel.fromJson(
        Map<String, dynamic>.from(profileResponse.data as Map),
      );
      setState(() {
        _user = user;
        _isFollowing = user.isFollowing;
        _catches = _parseList(responses[1], CatchModel.fromJson);
        _spots = _parseList(responses[2], SpotModel.fromJson);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败: $error';
        _isLoading = false;
      });
    }
  }

  List<T> _parseList<T>(
    ApiResponse<dynamic> response,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (!response.success || response.data is! List) return [];
    return (response.data as List)
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null || _isUpdatingFollow) return;
    setState(() => _isUpdatingFollow = true);
    final response = await _api.post(ApiEndpoints.toggleFollow(user.id));
    if (!mounted) return;
    if (!response.success || response.data is! Map) {
      setState(() => _isUpdatingFollow = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }

    final following = response.data['isFollowing'] == true;
    final stats = user.stats;
    setState(() {
      _isFollowing = following;
      _isUpdatingFollow = false;
      _user = user.copyWith(
        isFollowing: following,
        stats: UserStats(
          spotsCreated: stats.spotsCreated,
          catchesCount: stats.catchesCount,
          totalWeightKg: stats.totalWeightKg,
          maxWeightKg: stats.maxWeightKg,
          favoritesCount: stats.favoritesCount,
          followersCount: (stats.followersCount + (following ? 1 : -1)).clamp(
            0,
            999999,
          ),
          followingCount: stats.followingCount,
          badges: stats.badges,
        ),
      );
    });
  }

  void _openFollowList(bool followers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FollowListScreen(userId: widget.userId, showFollowers: followers),
      ),
    );
  }

  void _showBadge(UserBadge badge) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${badge.icon} ${badge.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.desc.isEmpty ? '钓界专属荣耀成就。' : badge.desc),
            if (badge.target > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${badge.unlocked ? '已解锁' : '未解锁'} · 进度 ${badge.current.toStringAsFixed(0)} / ${badge.target.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (badge.current / badge.target).clamp(0.0, 1.0),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: Text(user?.nickname ?? '钓友主页')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _loadProfile, child: const Text('重试')),
                ],
              ),
            )
          : Column(
              children: [
                _buildProfileHeader(user!),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: '战报 (${_catches.length})'),
                      Tab(text: '创建钓点 (${_spots.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildCatchList(), _buildSpotList()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final stats = user.stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: user.avatar.isEmpty
                ? null
                : NetworkImage(user.avatar),
            child: user.avatar.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 10),
          Text(user.nickname, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${user.fishingYears}年钓龄 · 主攻${user.targetFish}'),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(user.bio, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countButton('关注', stats.followingCount, () {
                _openFollowList(false);
              }),
              const SizedBox(width: 28),
              _countButton('粉丝', stats.followersCount, () {
                _openFollowList(true);
              }),
              const SizedBox(width: 28),
              _countButton('战报', stats.catchesCount, () {
                _tabController.animateTo(0);
              }),
            ],
          ),
          if (stats.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: stats.badges
                  .map(
                    (badge) => ActionChip(
                      avatar: Opacity(
                        opacity: badge.unlocked ? 1 : 0.45,
                        child: Text(badge.icon),
                      ),
                      label: Text(badge.name),
                      onPressed: () => _showBadge(badge),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isUpdatingFollow ? null : _toggleFollow,
            icon: _isUpdatingFollow
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFollowing
                        ? Icons.person_remove_outlined
                        : Icons.person_add_alt,
                  ),
            label: Text(_isFollowing ? '取消关注' : '关注'),
          ),
        ],
      ),
    );
  }

  Widget _countButton(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCatchList() {
    if (_catches.isEmpty) return const Center(child: Text('暂无战报'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _catches.length,
      itemBuilder: (context, index) {
        final item = _catches[index];
        return Card(
          child: ListTile(
            leading: item.photoUrl == null
                ? const Icon(Icons.phishing)
                : Image.network(
                    item.photoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.phishing),
                  ),
            title: Text('${item.fishType} · ${item.weightKg} kg'),
            subtitle: Text('${item.spotName} · ${item.createdAt ?? ''}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CatchDetailScreen(catchRecord: item),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotList() {
    if (_spots.isEmpty) return const Center(child: Text('暂无创建的钓点'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _spots.length,
      itemBuilder: (context, index) {
        final spot = _spots[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.place),
            title: Text(spot.name),
            subtitle: Text(spot.address),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
            ),
          ),
        );
      },
    );
  }
}
