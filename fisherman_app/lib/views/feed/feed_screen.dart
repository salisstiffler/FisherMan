import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/catch_model.dart';
import '../../models/spot_model.dart';
import '../../providers/catches_provider.dart';
import '../map/spot_detail_screen.dart';
import '../profile/user_profile_screen.dart';
import '../search/search_screen.dart';
import 'catch_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatchesProvider>(context, listen: false).fetchCatches();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      Provider.of<CatchesProvider>(
        context,
        listen: false,
      ).fetchCatches(loadMore: true);
    }
  }

  void _showSpotLocationAndNavigation(BuildContext context, CatchModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final spotCoords = LatLng(item.spotLat, item.spotLng);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.spotName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Full Address text
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.spotWaterType,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.spotChargeType,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.spotAddress,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mini Interactive Map of this spot
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: spotCoords,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.fisherman.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: spotCoords,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.goldenFish,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.phishing,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Navigation Card & Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '导航坐标:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.spotLat.toStringAsFixed(4)}, ${item.spotLng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: '${item.spotLat}, ${item.spotLng}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制经纬度坐标到剪贴板！')),
                            );
                          },
                          child: const Text(
                            '复制坐标',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '交通指引: 沿环湖大道驾车直达，水边提供钓友简易泊车位。',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons: Open Navigation / View Full Spot Details
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('查看钓点详情'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final spot = SpotModel(
                          id: item.spotId ?? 1,
                          name: item.spotName,
                          description:
                              '近期出鱼: ${item.fishType} (${item.weightKg}kg)。${item.notes}',
                          lat: item.spotLat,
                          lng: item.spotLng,
                          waterType: item.spotWaterType,
                          chargeType: item.spotChargeType,
                          address: item.spotAddress,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpotDetailScreen(spot: spot),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('路线导航前往'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showNavigationAppPicker(context, item);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showNavigationAppPicker(BuildContext context, CatchModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.navigation, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('出钓导航: ${item.spotName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标水域: ${item.spotAddress}'),
            const SizedBox(height: 8),
            Text(
              'GPS 坐标: ${item.spotLat.toStringAsFixed(4)}, ${item.spotLng.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 16),
            const Text(
              '请选择您常用的地图导航应用：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('高德地图 (AMap)'),
              subtitle: const Text('自驾/路线规划'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已唤起高德地图，正在规划前往【${item.spotName}】的出钓路线'),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.explore, color: Colors.green),
              title: const Text('腾讯地图 / 微信定位'),
              subtitle: const Text('实景钓点周边导航'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已唤起腾讯地图，正在规划前往【${item.spotName}】的出钓路线'),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('复制坐标并在系统地图中搜索'),
              onTap: () {
                Navigator.pop(dialogCtx);
                Clipboard.setData(
                  ClipboardData(text: '${item.spotLat}, ${item.spotLng}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已复制精确 GPS 坐标，可直接粘贴至任意地图软件开启导航！'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catchesProvider = Provider.of<CatchesProvider>(context);
    final catches = catchesProvider.catches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('钓友动态 • 渔获战报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新动态',
            onPressed: () => catchesProvider.fetchCatches(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter by Fish Species
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFishFilterChip('全部', catchesProvider),
                  ...AppConstants.popularFishList.take(8).map((fish) {
                    return _buildFishFilterChip(fish, catchesProvider);
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Catches Feed List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => catchesProvider.fetchCatches(),
              child: catches.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phishing,
                            size: 54,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '暂无此鱼种的动态，快去成为首发大师吧！',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount:
                          catches.length +
                          (catchesProvider.isLoadingMore ||
                                  catchesProvider.hasMore
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index == catches.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = catches[index];
                        return _buildCatchCard(context, item, catchesProvider);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishFilterChip(String fish, CatchesProvider provider) {
    final isSelected = provider.selectedFishFilter == fish;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(fish),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.lightBackground,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
        onSelected: (_) => provider.setFishFilter(fish),
      ),
    );
  }

  Widget _buildCatchCard(
    BuildContext context,
    CatchModel item,
    CatchesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatchDetailScreen(catchRecord: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: item.userId),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: item.userAvatar.isNotEmpty
                          ? NetworkImage(item.userAvatar)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: item.userAvatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: item.userId),
                            ),
                          ),
                          child: Text(
                            item.userNickname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${item.fishingMethod} • ${item.createdAt ?? '刚刚'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tappable Spot Badge with Navigation Hint
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showSpotLocationAndNavigation(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.spotName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.navigation,
                            size: 11,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Detailed Location Ribbon (详细位置展示)
            InkWell(
              onTap: () => _showSpotLocationAndNavigation(context, item),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppColors.lightBackground,
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '详细位置: ${item.spotAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      '查看地图与导航 >',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Catch Photo with Big Fish Weight Badge
            Stack(
              children: [
                Image.network(
                  item.photoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: AppColors.primaryDark,
                    child: const Icon(
                      Icons.phishing,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldenFish),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: AppColors.goldenFish,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.fishType}  ${item.weightKg} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Catch Story Notes
            if (item.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                child: Text(
                  item.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

            // Action Bar (Likes, Comments, Navigation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => provider.toggleLike(item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: item.isLiked
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isLiked
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontWeight: item.isLiked
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.commentsCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _showSpotLocationAndNavigation(context, item),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.directions,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '导航',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '查看战报 >',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
