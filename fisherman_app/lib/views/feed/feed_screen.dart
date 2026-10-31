import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/fishing_navigation.dart';
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
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
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
                      Icon(
                        Icons.location_on,
                        color: context.fishermanColors.primary,
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
                      color: context.fishermanColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.spotWaterType,
                      style: TextStyle(
                        color: context.fishermanColors.primary,
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
                      color: context.fishermanColors.secondary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.spotChargeType,
                      style: TextStyle(
                        color: context.fishermanColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.spotAddress,
                      style: TextStyle(
                        color: context.fishermanColors.onSurfaceVariant,
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
                                color: context.fishermanColors.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.fishermanColors.onTertiary,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
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
                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.fishermanColors.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.near_me,
                              color: context.fishermanColors.secondary,
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
                              style: TextStyle(
                                fontSize: 12,
                                color: context.fishermanColors.onSurfaceVariant,
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
                          child: Text(
                            '复制坐标',
                            style: TextStyle(
                              color: context.fishermanColors.primary,
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
                        Icon(
                          Icons.directions_car_outlined,
                          size: 16,
                          color: context.fishermanColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '交通指引: 沿环湖大道驾车直达，水边提供钓友简易泊车位。',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.fishermanColors.onSurfaceVariant
                                  .withValues(alpha: 0.9),
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
                        FishingNavigation.open(
                          context,
                          name: item.spotName,
                          address: item.spotAddress,
                          latitude: item.spotLat,
                          longitude: item.spotLng,
                        );
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
            color: Theme.of(context).colorScheme.surface,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phishing,
                            size: 54,
                            color: context.fishermanColors.onSurfaceVariant,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '暂无此鱼种的动态，快去成为首发大师吧！',
                            style: TextStyle(
                              color: context.fishermanColors.onSurfaceVariant,
                            ),
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
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(item.id),
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds: 380 + (index % 7) * 55,
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) => Opacity(
                            opacity: progress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - progress)),
                              child: child,
                            ),
                          ),
                          child: _buildCatchCard(
                            context,
                            item,
                            catchesProvider,
                          ),
                        );
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
        selectedColor: context.fishermanColors.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: isSelected
              ? context.fishermanColors.onPrimary
              : Theme.of(context).colorScheme.onSurface,
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
                      backgroundColor: context.fishermanColors.primary,
                      child: item.userAvatar.isEmpty
                          ? Icon(
                              Icons.person,
                              color: context.fishermanColors.onPrimary,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: context.fishermanColors.onSurfaceVariant,
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
                        color: context.fishermanColors.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.fishermanColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: context.fishermanColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.spotName,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.fishermanColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.navigation,
                            size: 11,
                            color: context.fishermanColors.primary,
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
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: context.fishermanColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '详细位置: ${item.spotAddress}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.fishermanColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '查看地图与导航 >',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.fishermanColors.secondary,
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
                    color: context.fishermanColors.primary,
                    child: Icon(
                      Icons.phishing,
                      color: context.fishermanColors.onPrimary,
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
                      border: Border.all(
                        color: context.fishermanColors.tertiary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: context.fishermanColors.tertiary,
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
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.fishermanColors.onSurface,
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                  child: child,
                                ),
                            child: Icon(
                              item.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(item.isLiked),
                              size: 18,
                              color: item.isLiked
                                  ? context.fishermanColors.error
                                  : context.fishermanColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isLiked
                                  ? context.fishermanColors.error
                                  : context.fishermanColors.onSurfaceVariant,
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
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.commentsCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.fishermanColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _showSpotLocationAndNavigation(context, item),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions,
                          size: 14,
                          color: context.fishermanColors.primary,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '导航',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.fishermanColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '查看战报 >',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.fishermanColors.primary,
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
