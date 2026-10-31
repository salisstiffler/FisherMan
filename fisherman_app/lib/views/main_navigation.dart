import 'package:flutter/material.dart';

import 'map/spot_map_screen.dart';
import 'feed/feed_screen.dart';
import 'notifications/notifications_screen.dart';
import 'publish/publish_catch_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
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
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: 0.45),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _currentIndex,
          animationDuration: const Duration(milliseconds: 220),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 3) {
              _refreshUnreadCount();
            }
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: '钓点地图',
            ),
            NavigationDestination(
              icon: const Icon(Icons.dynamic_feed_outlined),
              selectedIcon: const Icon(Icons.dynamic_feed),
              label: '渔获动态',
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              selectedIcon: const Icon(Icons.add_circle, size: 28),
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
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error, // Use error color
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error, // Use error color
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: '消息',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: '我的钓界',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
