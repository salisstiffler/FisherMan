import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/catch_model.dart';
import '../../models/spot_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catches_provider.dart';
import '../../providers/spots_provider.dart';
import '../feed/catch_detail_screen.dart';
import '../map/spot_detail_screen.dart';
import 'follow_list_screen.dart';
import 'edit_profile_screen.dart';
import 'my_stats_chart.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<CatchesProvider>().fetchMyCatches(userId);
        }
      });
    }
  }

  int? _loadedUserId;

  void _showBadgeDialog(BuildContext context, UserBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              badge.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.desc.isNotEmpty ? badge.desc : '钓界专属荣耀成就！',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (badge.target > 0) ...[
              Text(
                '${badge.unlocked ? '已解锁' : '未解锁'} · 进度 ${badge.current} / ${badge.target}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.fishermanColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (badge.current / badge.target).clamp(0.0, 1.0),
                backgroundColor: context.fishermanColors.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.fishermanColors.primary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showServerSettings(BuildContext context) {
    final controller = TextEditingController(text: ApiClient().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器网络设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '配置后端 API 服务地址（支持本地或云端 IP）：',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8080 或 http://localhost:8080',
                labelText: 'API Base URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiClient().setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已更新服务器地址为: ${controller.text.trim()}')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageCatch(CatchModel item) async {
    final catchesProvider = context.read<CatchesProvider>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑备注'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: context.fishermanColors.error,
              ),
              title: Text(
                '删除战报',
                style: TextStyle(color: context.fishermanColors.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      final controller = TextEditingController(text: item.notes);
      final notes = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('编辑战报备注'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '记录这次作钓经历'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (notes == null) return;
      final success = await catchesProvider.updateCatch(item.id, notes: notes);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '战报已更新' : '更新失败，请重试')));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除战报'),
        content: const Text('删除后无法恢复，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: context.fishermanColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await catchesProvider.deleteCatch(item.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success ? '战报已删除' : '删除失败，请重试')));
    }
  }

  Future<void> _manageSpot(SpotModel spot) async {
    final spotsProvider = context.read<SpotsProvider>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑钓点描述'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: context.fishermanColors.error,
              ),
              title: Text(
                '删除钓点',
                style: TextStyle(color: context.fishermanColors.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final controller = TextEditingController(text: spot.description);
      final description = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('编辑钓点描述'),
          content: TextField(controller: controller, maxLines: 4),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (description == null) return;
      final success = await spotsProvider.updateSpot(
        spot.id,
        description: description,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '钓点已更新' : '更新失败，请重试')));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除钓点'),
        content: const Text('删除后无法恢复，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: context.fishermanColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await spotsProvider.deleteSpot(spot.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success ? '钓点已删除' : '删除失败，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final stats = user?.stats ?? UserStats();
    final catchesProvider = Provider.of<CatchesProvider>(context);
    final spotsProvider = Provider.of<SpotsProvider>(context);

    // Filter user's catches and favorite spots
    final myCatches = catchesProvider.myCatches;
    final mySpots = spotsProvider.spots
        .where((spot) => spot.creatorId == user?.id)
        .toList();
    final favoriteSpots = spotsProvider.spots
        .where((s) => s.isFavorited)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的钓界'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '服务器配置',
            onPressed: () => _showServerSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () {
              auth.logout();
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // User Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.fishermanColors.primary,
                            Color.lerp(
                              context.fishermanColors.primary,
                              Colors.black,
                              0.16,
                            )!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: context.fishermanColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    context.fishermanColors.surface,
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      (user?.avatar.isNotEmpty ?? false)
                                      ? NetworkImage(user!.avatar)
                                      : null,
                                  child: (user?.avatar.isEmpty ?? true)
                                      ? Icon(
                                          Icons.phishing,
                                          size: 32,
                                          color:
                                              context.fishermanColors.primary,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user?.nickname ?? '钓鱼佬',
                                          style: TextStyle(
                                            color: context
                                                .fishermanColors
                                                .onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context
                                                .fishermanColors
                                                .tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${user?.fishingYears ?? 1}年钓龄',
                                            style: TextStyle(
                                              color: context
                                                  .fishermanColors
                                                  .onTertiaryContainer,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '主攻: ${user?.targetFish ?? '鲫鱼、鲤鱼'}',
                                      style: TextStyle(
                                        color: context.fishermanColors.onPrimary
                                            .withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.bio ?? '永不空军，钓获放流！',
                                      style: TextStyle(
                                        color: context.fishermanColors.onPrimary
                                            .withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: context.fishermanColors.onPrimary
                                      .withValues(alpha: 0.8),
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: user?.id ?? 0,
                                showFollowers: false,
                              ),
                            ),
                          ),
                          child: Text('关注 ${stats.followingCount}'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: user?.id ?? 0,
                                showFollowers: true,
                              ),
                            ),
                          ),
                          child: Text('粉丝 ${stats.followersCount}'),
                        ),
                      ],
                    ),

                    // Angler Stats Grid
                    Row(
                      children: [
                        _buildStatBox(
                          '累计渔获',
                          '${stats.catchesCount}尾',
                          Icons.phishing,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          '总捕获量',
                          '${stats.totalWeightKg}kg',
                          Icons.scale,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          '最大单尾',
                          '${stats.maxWeightKg}kg',
                          Icons.military_tech,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          '开拓钓点',
                          '${stats.spotsCreated}个',
                          Icons.place,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!auth.isGuest) const MyStatsChart(),

                    // Badges Wall
                    if (stats.badges.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '荣耀勋章 (${stats.badges.where((b) => b.unlocked).length}/${stats.badges.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stats.badges.map((b) {
                          return InkWell(
                            onTap: () => _showBadgeDialog(context, b),
                            borderRadius: BorderRadius.circular(10),
                            child: Opacity(
                              opacity: b.unlocked ? 1 : 0.5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: b.unlocked
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      b.icon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      b.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Card(
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: context.fishermanColors.primary,
                        ),
                        title: const Text(
                          '应用设置',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('主题、颜色与客户端下载'),
                        children: const [SettingsContent()],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab bar for Catches vs Favorites
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: context.fishermanColors.primary,
                        labelColor: context.fishermanColors.primary,
                        unselectedLabelColor:
                            context.fishermanColors.onSurfaceVariant,
                        tabs: [
                          Tab(text: '我的战报 (${myCatches.length})'),
                          Tab(text: '创建钓点 (${mySpots.length})'),
                          Tab(text: '收藏钓点 (${favoriteSpots.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Catches List
            myCatches.isEmpty
                ? Center(
                    child: Text(
                      '暂无战报，快去发布今日首条大鱼！',
                      style: TextStyle(
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: myCatches.length,
                    itemBuilder: (context, index) {
                      final item = myCatches[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.photoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            '${item.fishType} • ${item.weightKg} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.spotName} • ${item.fishingMethod}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CatchDetailScreen(catchRecord: item),
                              ),
                            );
                          },
                          onLongPress: () => _manageCatch(item),
                        ),
                      );
                    },
                  ),

            mySpots.isEmpty
                ? Center(
                    child: Text(
                      '暂无创建的钓点',
                      style: TextStyle(
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: mySpots.length,
                    itemBuilder: (context, index) {
                      final spot = mySpots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            Icons.place,
                            color: context.fishermanColors.primary,
                          ),
                          title: Text(
                            spot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(spot.address),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpotDetailScreen(spot: spot),
                            ),
                          ),
                          onLongPress: () => _manageSpot(spot),
                        ),
                      );
                    },
                  ),

            // Favorites List
            favoriteSpots.isEmpty
                ? Center(
                    child: Text(
                      '暂无收藏钓点，在地图上点击红心收藏心仪水域',
                      style: TextStyle(
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: favoriteSpots.length,
                    itemBuilder: (context, index) {
                      final spot = favoriteSpots[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              spot.imageUrl ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            spot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${spot.waterType} • ${spot.chargeType} • 水深${spot.depthMeters}m',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SpotDetailScreen(spot: spot),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: context.fishermanColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: context.fishermanColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
