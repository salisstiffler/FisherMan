import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'map/spot_map_screen.dart';
import 'feed/feed_screen.dart';
import 'notifications/notifications_screen.dart';
import 'publish/publish_catch_screen.dart';
import 'profile/profile_screen.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final response = await ApiClient().get(
      ApiEndpoints.notificationsUnreadCount,
    );
    if (!mounted || !response.success || response.data is! Map) return;
    setState(() {
      _unreadCount = response.data['count'] as int? ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const SpotMapScreen(),
          const FeedScreen(),
          const PublishCatchScreen(),
          NotificationsScreen(
            isActive: _currentIndex == 3,
            onRead: () => setState(() => _unreadCount = 0),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 3) {
              _refreshUnreadCount();
            }
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppColors.primary),
              label: '钓点地图',
            ),
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed, color: AppColors.primary),
              label: '渔获动态',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, size: 28),
              selectedIcon: Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 28,
              ),
              label: '发布渔获',
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, color: AppColors.primary),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: '消息',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: '我的钓界',
            ),
          ],
        ),
      ),
    );
  }
}
