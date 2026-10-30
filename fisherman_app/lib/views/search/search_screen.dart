import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/catch_model.dart';
import '../../models/spot_model.dart';
import '../../models/user_model.dart';
import '../feed/catch_detail_screen.dart';
import '../map/spot_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ApiClient _api = ApiClient();
  late final TabController _tabController;
  List<Map<String, dynamic>> _catches = [];
  List<Map<String, dynamic>> _spots = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    final response = await _api.get(
      ApiEndpoints.search,
      queryParams: {'q': query},
    );
    if (!mounted) return;
    if (!response.success || response.data is! Map) {
      setState(() {
        _error = response.message;
        _isLoading = false;
      });
      return;
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    setState(() {
      _catches = _asMaps(data['catches']);
      _spots = _asMaps(data['spots']);
      _users = _asMaps(data['users']);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _asMaps(dynamic data) {
    if (data is! List) return [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全局搜索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '搜索鱼种、钓点或钓友',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: '战报 (${_catches.length})'),
              Tab(text: '钓点 (${_spots.length})'),
              Tab(text: '用户 (${_users.length})'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : !_hasSearched
                ? const Center(child: Text('输入关键词，搜索战报、钓点和用户'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCatchResults(),
                      _buildSpotResults(),
                      _buildUserResults(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatchResults() {
    if (_catches.isEmpty) return const Center(child: Text('没有找到相关战报'));
    return ListView.builder(
      itemCount: _catches.length,
      itemBuilder: (context, index) {
        final item = CatchModel.fromJson(_catches[index]);
        return ListTile(
          leading: const Icon(Icons.phishing, color: AppColors.primary),
          title: Text('${item.fishType} · ${item.weightKg} kg'),
          subtitle: Text('${item.userNickname} · ${item.notes}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatchDetailScreen(catchRecord: item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotResults() {
    if (_spots.isEmpty) return const Center(child: Text('没有找到相关钓点'));
    return ListView.builder(
      itemCount: _spots.length,
      itemBuilder: (context, index) {
        final spot = SpotModel.fromJson(_spots[index]);
        return ListTile(
          leading: const Icon(Icons.place, color: AppColors.primary),
          title: Text(spot.name),
          subtitle: Text(spot.address),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
          ),
        );
      },
    );
  }

  Widget _buildUserResults() {
    if (_users.isEmpty) return const Center(child: Text('没有找到相关用户'));
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = UserModel.fromJson(_users[index]);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(user.nickname),
          subtitle: Text(user.bio),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: user.id),
            ),
          ),
        );
      },
    );
  }
}
