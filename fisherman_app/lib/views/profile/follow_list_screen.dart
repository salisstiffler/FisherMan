import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final int userId;
  final bool showFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late final Future<List<Map<String, dynamic>>> _users;

  @override
  void initState() {
    super.initState();
    _users = _loadUsers();
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final endpoint = widget.showFollowers
        ? ApiEndpoints.followers(widget.userId)
        : ApiEndpoints.following(widget.userId);
    final response = await ApiClient().get(endpoint);
    if (!response.success) throw Exception(response.message);
    if (response.data is! List) return [];
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.showFollowers ? '粉丝' : '关注')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) return const Center(child: Text('暂无用户'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final id = user['id'] as int? ?? 0;
              final nickname = user['nickname'] as String? ?? '钓友';
              final avatar = user['avatar'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.fishermanColors.primary,
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? Icon(
                          Icons.person,
                          color: context.fishermanColors.onPrimary,
                        )
                      : null,
                ),
                title: Text(nickname),
                subtitle: Text(user['bio'] as String? ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: id < 1
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: id),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
