import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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

    final responses = await Future.wait([
      _api.get(ApiEndpoints.userProfile(widget.userId)),
      _api.get(ApiEndpoints.catches, queryParams: {'userId': widget.userId}),
      _api.get(ApiEndpoints.spots, queryParams: {'creatorId': widget.userId}),
    ]);

    if (!mounted) return;
    if (!responses[0].success || responses[0].data is! Map) {
      setState(() {
        _error = responses[0].message;
        _isLoading = false;
      });
      return;
    }

    final user = UserModel.fromJson(
      Map<String, dynamic>.from(responses[0].data as Map),
    );
    setState(() {
      _user = user;
      _isFollowing = user.isFollowing;
      _catches = responses[1].success && responses[1].data is List
          ? (responses[1].data as List)
                .map(
                  (item) => CatchModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : [];
      _spots = responses[2].success && responses[2].data is List
          ? (responses[2].data as List)
                .map(
                  (item) => SpotModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : [];
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final response = await _api.post(ApiEndpoints.toggleFollow(widget.userId));
    if (!mounted) return;
    if (!response.success || response.data is! Map) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final isFollowing = response.data['isFollowing'] == true;
    setState(() {
      _isFollowing = isFollowing;
      final oldStats = _user!.stats;
      _user = UserModel(
        id: _user!.id,
        username: _user!.username,
        nickname: _user!.nickname,
        avatar: _user!.avatar,
        bio: _user!.bio,
        fishingYears: _user!.fishingYears,
        targetFish: _user!.targetFish,
        isFollowing: isFollowing,
        stats: UserStats(
          spotsCreated: oldStats.spotsCreated,
          catchesCount: oldStats.catchesCount,
          totalWeightKg: oldStats.totalWeightKg,
          maxWeightKg: oldStats.maxWeightKg,
          favoritesCount: oldStats.favoritesCount,
          followersCount: oldStats.followersCount + (isFollowing ? 1 : -1),
          followingCount: oldStats.followingCount,
          badges: oldStats.badges,
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

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(text: '战报 (${_catches.length})'),
                      Tab(text: '创建的钓点 (${_spots.length})'),
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
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 40)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            user.nickname,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${user.fishingYears}年钓龄 · 主攻${user.targetFish}'),
          const SizedBox(height: 6),
          Text(user.bio, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countButton(
                '关注',
                stats.followingCount,
                () => _openFollowList(false),
              ),
              const SizedBox(width: 28),
              _countButton(
                '粉丝',
                stats.followersCount,
                () => _openFollowList(true),
              ),
              const SizedBox(width: 28),
              _countButton(
                '战报',
                stats.catchesCount,
                () => _tabController.animateTo(0),
              ),
            ],
          ),
          if (stats.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: stats.badges
                  .map(
                    (badge) => Chip(
                      avatar: Text(badge.icon),
                      label: Text(badge.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (user.id != 0)
            OutlinedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
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
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
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
            leading: const Icon(Icons.place, color: AppColors.primary),
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
