import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/catch_model.dart';
import '../feed/catch_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;
  final bool isActive;

  const NotificationsScreen({super.key, this.onRead, this.isActive = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadNotifications();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await _api.get(ApiEndpoints.notifications);
    if (!mounted) return;
    if (!response.success || response.data is! Map) {
      setState(() {
        _error = response.message;
        _isLoading = false;
      });
      return;
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final unreadCount = data['unreadCount'] as int? ?? 0;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });

    if (unreadCount > 0) {
      final marked = await _api.put(ApiEndpoints.notificationsRead);
      if (!mounted) return;
      if (marked.success) {
        setState(() {
          for (final notification in _notifications) {
            notification['isRead'] = true;
          }
        });
        widget.onRead?.call();
      }
    } else {
      widget.onRead?.call();
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final targetType = notification['targetType'] as String?;
    final targetId = notification['targetId'] as int?;
    if (targetType == 'user') {
      final actorId = notification['actorId'] as int?;
      if (actorId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: actorId)),
        );
      }
    } else if (targetType == 'catch' && targetId != null) {
      final response = await _api.get(ApiEndpoints.catchDetail(targetId));
      if (!mounted) return;
      if (response.success && response.data is Map) {
        final item = CatchModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CatchDetailScreen(catchRecord: item),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _loadNotifications,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? const Center(child: Text('暂无新消息'))
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final avatar = notification['actorAvatar'] as String? ?? '';
                  final type = notification['type'] as String? ?? '';
                  return ListTile(
                    tileColor: notification['isRead'] == true
                        ? Theme.of(context).colorScheme.surface
                        : AppColors.primary.withValues(alpha: 0.06),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty
                          ? Icon(_iconForType(type), color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      notification['content'] as String? ?? '收到一条新消息',
                    ),
                    subtitle: Text(notification['createdAt'] as String? ?? ''),
                    trailing: notification['isRead'] == true
                        ? null
                        : const Icon(
                            Icons.circle,
                            size: 9,
                            color: AppColors.danger,
                          ),
                    onTap: () => _openNotification(notification),
                  );
                },
              ),
            ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
}
