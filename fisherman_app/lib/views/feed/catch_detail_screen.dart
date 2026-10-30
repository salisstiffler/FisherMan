import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/catch_model.dart';
import '../../models/spot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catches_provider.dart';
import '../map/spot_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class CatchDetailScreen extends StatefulWidget {
  final CatchModel catchRecord;

  const CatchDetailScreen({super.key, required this.catchRecord});

  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  CatchComment? _replyTo;

  @override
  void initState() {
    super.initState();
    context.read<CatchesProvider>().fetchCatchDetail(widget.catchRecord.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final catchesProvider = Provider.of<CatchesProvider>(
      context,
      listen: false,
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
    final success = await catchesProvider.addComment(
      widget.catchRecord.id,
      text,
      parentId: _replyTo?.id,
    );
    if (!mounted) return;
    setState(() => _replyTo = null);
    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('评论发送失败，请重试')));
    }
  }

  Future<void> _deleteComment(CatchComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<CatchesProvider>().deleteComment(
      widget.catchRecord.id,
      comment.id,
    );
    if (mounted && !success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除评论失败，请重试')));
    }
  }

  void _showNavigationModal(BuildContext context, CatchModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            Text(
              '详细位置: ${item.spotAddress}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'GPS 坐标: ${item.spotLat.toStringAsFixed(4)}, ${item.spotLng.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '请选择导航方式：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('高德地图 (AMap)'),
              subtitle: const Text('规划最佳自驾出钓路线'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已唤起高德地图导航前往【${item.spotName}】')),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.explore, color: Colors.green),
              title: const Text('腾讯地图 / 微信定位'),
              subtitle: const Text('周边水系与停车指引'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已唤起腾讯地图导航前往【${item.spotName}】')),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('复制精确 GPS 坐标'),
              onTap: () {
                Navigator.pop(ctx);
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatchesProvider>(
      builder: (context, catchesProvider, child) {
        final item = catchesProvider.catches.firstWhere(
          (c) => c.id == widget.catchRecord.id,
          orElse: () => widget.catchRecord,
        );

        final spotCoords = LatLng(item.spotLat, item.spotLng);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            title: const Text('渔获战报'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: '分享战报',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '已生成【${item.userNickname}】的 ${item.fishType} (${item.weightKg}kg) 战报海报！',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Catch Photo & Watermark
                      Stack(
                        children: [
                          Image.network(
                            item.photoUrl ?? 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 280,
                              color: AppColors.primaryDark,
                              child: const Icon(
                                Icons.phishing,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Big Fish Trophy Tag Badge
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.goldenFish,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.military_tech,
                                    color: AppColors.goldenFish,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.fishType} ${item.weightKg} kg',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (item.lengthCm > 0)
                                    Text(
                                      ' / ${item.lengthCm}cm',
                                      style: const TextStyle(
                                        color: AppColors.goldenLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Angler Info Row
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfileScreen(userId: item.userId),
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: item.userAvatar.isNotEmpty
                                    ? NetworkImage(item.userAvatar)
                                    : null,
                                backgroundColor: AppColors.primary,
                                child: item.userAvatar.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserProfileScreen(
                                          userId: item.userId,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      item.userNickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '钓龄 ${item.userFishingYears} 年 • ${item.createdAt ?? '刚刚'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: Icon(
                                item.isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_alt_outlined,
                                size: 16,
                                color: item.isLiked
                                    ? AppColors.goldenFish
                                    : AppColors.primary,
                              ),
                              label: Text('${item.likesCount} 点赞'),
                              onPressed: () =>
                                  catchesProvider.toggleLike(item.id),
                            ),
                          ],
                        ),
                      ),

                      // Fishing Parameters Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildParam(
                                    '钓法',
                                    item.fishingMethod,
                                    Icons.phishing,
                                  ),
                                  _buildParam(
                                    '作钓水深',
                                    '${item.depthM} 米',
                                    Icons.straighten,
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  _buildParam(
                                    '饵料/拟饵',
                                    item.bait,
                                    Icons.bubble_chart_outlined,
                                  ),
                                  _buildParam(
                                    '作钓水域',
                                    item.spotName,
                                    Icons.location_on_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dedicated Location & Navigation Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.spotName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    icon: const Icon(
                                      Icons.navigation,
                                      size: 14,
                                    ),
                                    label: const Text('导航前往'),
                                    onPressed: () =>
                                        _showNavigationModal(context, item),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '详细位置: ${item.spotAddress}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Mini Map
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: spotCoords,
                                      initialZoom: 13.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.fisherman.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: spotCoords,
                                            width: 44,
                                            height: 44,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.goldenFish,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.phishing,
                                                  color: Colors.white,
                                                  size: 22,
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
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'GPS: ${item.spotLat.toStringAsFixed(4)}, ${item.spotLng.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final spot = SpotModel(
                                        id: item.spotId ?? 1,
                                        name: item.spotName,
                                        description:
                                            '近期大鱼战报: ${item.fishType} (${item.weightKg}kg)。${item.notes}',
                                        lat: item.spotLat,
                                        lng: item.spotLng,
                                        waterType: item.spotWaterType,
                                        chargeType: item.spotChargeType,
                                        address: item.spotAddress,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SpotDetailScreen(spot: spot),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      '查看该钓点全部鱼情 >',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notes / Story
                      if (item.notes.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 16.0,
                            top: 16.0,
                            right: 16.0,
                          ),
                          child: Text(
                            '出钓心路战报',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: Text(
                              item.notes,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Comments Section
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          top: 16.0,
                          right: 16.0,
                        ),
                        child: Text(
                          '钓友热议 (${item.comments.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (item.comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              '暂无评论，快来抢首条大鱼沙发！',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: item.comments.length,
                          itemBuilder: (context, idx) {
                            final comment = item.comments[idx];
                            final currentUserId = context
                                .read<AuthProvider>()
                                .currentUser
                                ?.id;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: 12,
                                left: comment.parentId == null ? 0 : 24,
                              ),
                              child: GestureDetector(
                                onLongPress: comment.userId == currentUserId
                                    ? () => _deleteComment(comment)
                                    : null,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserProfileScreen(
                                            userId: comment.userId,
                                          ),
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          comment.userNickname.isNotEmpty
                                              ? comment.userNickname[0]
                                              : '钓',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        UserProfileScreen(
                                                          userId:
                                                              comment.userId,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  comment.userNickname,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                comment.createdAt,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.content,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => setState(
                                                () => _replyTo = comment,
                                              ),
                                              child: const Text(
                                                '回复',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Comment Input Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: _replyTo == null
                                ? '说两句，向大师请教或点个赞...'
                                : '回复 ${_replyTo!.userNickname}...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.lightBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: _sendComment,
                      ),
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

  Widget _buildParam(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
