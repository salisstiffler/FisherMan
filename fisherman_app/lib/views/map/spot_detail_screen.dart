import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/fishing_share_card.dart';
import '../../models/spot_model.dart';
import '../../providers/spots_provider.dart';
import '../publish/publish_catch_screen.dart';
import '../profile/user_profile_screen.dart';

class SpotDetailScreen extends StatefulWidget {
  final SpotModel spot;

  const SpotDetailScreen({super.key, required this.spot});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  late Future<ApiResponse<dynamic>> _reviewsFuture;

  SpotModel get spot => widget.spot;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<ApiResponse<dynamic>> _loadReviews() {
    return ApiClient().get(ApiEndpoints.spotReviews(spot.id));
  }

  Future<void> _shareSpot(SpotModel item) async {
    try {
      await FishingShareCard.share(
        title: item.name,
        subtitle: '钓点推荐 · ${item.waterType} · ${item.chargeType}',
        details: [
          '地址：${item.address}',
          '水深：${item.depthMeters} m',
          '目标鱼种：${item.fishTypes.join('、')}',
          if (item.feeDesc.isNotEmpty) '费用：${item.feeDesc}',
          if (item.description.isNotEmpty) '介绍：${item.description}',
        ],
        message: '发现钓点「${item.name}」：${item.address}。',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('生成分享图片失败：$error')));
      }
    }
  }

  Future<void> _addReview() async {
    var rating = 5;
    final controller = TextEditingController();
    final review = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('评价钓点'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: '评分'),
                items: List.generate(
                  5,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} 星'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setDialogState(() => rating = value);
                },
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '评价内容（选填）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'rating': rating,
                'content': controller.text.trim(),
              }),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (review == null || !mounted) return;

    final response = await ApiClient().post(
      ApiEndpoints.spotReviews(spot.id),
      body: review,
    );
    if (!mounted) return;
    if (response.success) {
      setState(() => _reviewsFuture = _loadReviews());
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(response.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        // Find current instance for updated favorite status
        final currentSpot = spotsProvider.spots.firstWhere(
          (s) => s.id == spot.id,
          orElse: () => spot,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // Hero Image & App Bar
              SliverAppBar(
                expandedHeight: 260.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    currentSpot.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        currentSpot.imageUrl ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.primaryDark,
                          child: const Icon(
                            Icons.water,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    tooltip: '分享钓点',
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () => _shareSpot(currentSpot),
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(
                        currentSpot.isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: currentSpot.isFavorited
                            ? AppColors.danger
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      final success = await spotsProvider.toggleFavorite(
                        currentSpot.id,
                      );
                      if (!context.mounted) return;
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('收藏操作失败，请重试')),
                        );
                        return;
                      }
                      final updatedSpot = spotsProvider.spots.firstWhere(
                        (item) => item.id == currentSpot.id,
                        orElse: () => currentSpot,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            updatedSpot.isFavorited ? '已加入我的收藏钓点' : '已取消收藏',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag(
                            currentSpot.waterType,
                            AppColors.primary,
                            Icons.water_drop,
                          ),
                          _buildTag(
                            currentSpot.chargeType,
                            AppColors.secondary,
                            Icons.attach_money,
                          ),
                          _buildTag(
                            '水深 ~${currentSpot.depthMeters}米',
                            AppColors.goldenFish,
                            Icons.straighten,
                          ),
                          _buildTag(
                            '${currentSpot.likesCount} 人收藏',
                            AppColors.textSecondary,
                            Icons.favorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildReviewsSection(),
                      const SizedBox(height: 16),

                      if (currentSpot.creatorId != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage:
                                currentSpot.creatorAvatar.isNotEmpty
                                ? NetworkImage(currentSpot.creatorAvatar)
                                : null,
                            child: currentSpot.creatorAvatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(currentSpot.creatorNickname),
                          subtitle: const Text('钓点创建者 · 查看主页'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: currentSpot.creatorId!,
                              ),
                            ),
                          ),
                        ),

                      // Fee Card
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '收费与管理政策',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentSpot.feeDesc,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Target Fish Distribution
                      const Text(
                        '出鱼鱼种与标点特征',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentSpot.fishTypes.map((fish) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🐟 ',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  fish,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Spot Description & Notes
                      const Text(
                        '钓点实地环境详解',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Text(
                          currentSpot.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Angler Safety & Rules
                      const Text(
                        '作钓守则与文明约定',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.eco,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentSpot.rules,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location & Navigation
                      const Text(
                        '地理位置与导航',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      currentSpot.address,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'GPS: ${currentSpot.lat.toStringAsFixed(4)}, ${currentSpot.lng.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.navigation_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('路线导航'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '已复制钓点坐标: ${currentSpot.lat}, ${currentSpot.lng}，正在规划出钓路线',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Action Button: Publish catch at this spot
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('在此钓点打卡发布渔获'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PublishCatchScreen(
                                  preSelectedSpot: currentSpot,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return FutureBuilder<ApiResponse<dynamic>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
          return const Text('评价暂不可用');
        }
        final data = snapshot.data!.data as Map<String, dynamic>;
        final reviews = (data['reviews'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final average = (data['avgRating'] as num?)?.toDouble() ?? 0;
        final total = data['totalCount'] as int? ?? reviews.length;
        return Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '钓友评价',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('★ ${average.toStringAsFixed(1)} · $total 条'),
                    TextButton(onPressed: _addReview, child: const Text('写评价')),
                  ],
                ),
                if (reviews.isEmpty)
                  const Text('还没有评价，来分享你的作钓体验吧。')
                else
                  ...reviews
                      .take(5)
                      .map(
                        (review) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            '${review['userNickname'] ?? '钓友'} · ${review['rating']} 星',
                          ),
                          subtitle: Text(review['content'] as String? ?? ''),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
