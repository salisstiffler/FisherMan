import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginUsernameController = TextEditingController(text: 'diaoyu1');
  final _loginPasswordController = TextEditingController(text: '123456');

  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regNicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regNicknameController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _loginUsernameController.text.trim(),
      _loginPasswordController.text.trim(),
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '登录失败，请检查账号密码')),
      );
    }
  }

  void _onRegister() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      _regUsernameController.text.trim(),
      _regPasswordController.text.trim(),
      _regNicknameController.text.trim(),
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '注册失败，请检查填写内容')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo & Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.phishing, color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppConstants.appSlogan,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Tab Switcher
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: '账号登录'),
                      Tab(text: '新钓友注册'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Views
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Login View
                      Column(
                        children: [
                          TextField(
                            controller: _loginUsernameController,
                            decoration: const InputDecoration(
                              labelText: '用户名',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _loginPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: '密码',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _onLogin,
                              child: auth.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('立即登录'),
                            ),
                          ),
                        ],
                      ),

                      // Register View
                      Column(
                        children: [
                          TextField(
                            controller: _regUsernameController,
                            decoration: const InputDecoration(
                              labelText: '用户名 (字母/数字)',
                              prefixIcon: Icon(Icons.account_circle_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _regNicknameController,
                            decoration: const InputDecoration(
                              labelText: '钓友昵称 (如: 钱塘江老钓手)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _regPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: '设置密码',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _onRegister,
                              child: auth.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('完成注册并进入'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Guest Mode & Demo credentials
                const Divider(),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.explore_outlined, color: AppColors.secondary),
                  label: const Text(
                    '免注册一键体验 (游客模式)',
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    auth.enterGuestMode();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
