import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/appearance_provider.dart';

const _appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.0',
);
const _appBuildNumber = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '5',
);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(children: const [SettingsContent()]),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('设置未能保存：$error')));
  }

  Future<void> _downloadAndroidApp(BuildContext context) async {
    final uri = Uri.https(
      'fisherman.berlin2026.dpdns.org',
      '/downloads/fisherman-app.apk',
      {'v': _appBuildNumber},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开下载页面，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceProvider>();
    final theme = Theme.of(context);
    final isDark =
        appearance.themeMode == ThemeMode.dark ||
        (appearance.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: '外观',
            icon: Icons.palette_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('深色模式'),
                subtitle: Text(
                  appearance.themeMode == ThemeMode.system
                      ? '当前跟随系统设置'
                      : isDark
                      ? '已开启'
                      : '已关闭',
                ),
                value: isDark,
                onChanged: (value) async {
                  try {
                    await appearance.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    _showError(context, error);
                  }
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: appearance.themeMode == ThemeMode.system
                      ? null
                      : () async {
                          try {
                            await appearance.setThemeMode(ThemeMode.system);
                          } catch (error) {
                            if (!context.mounted) return;
                            _showError(context, error);
                          }
                        },
                  icon: const Icon(Icons.settings_suggest_outlined, size: 18),
                  label: const Text('跟随系统'),
                ),
              ),
              const Divider(height: 12),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  '主题颜色',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (
                    var index = 0;
                    index < AppColors.themePalettes.length;
                    index++
                  )
                    _ThemeColorOption(
                      color: AppColors.themePalettes[index],
                      label: AppColors.themePaletteNames[index],
                      selected:
                          appearance.accentColor.toARGB32() ==
                          AppColors.themePalettes[index].toARGB32(),
                      onSelected: () async {
                        try {
                          await appearance.setAccentColor(
                            AppColors.themePalettes[index],
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          _showError(context, error);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '客户端下载',
            icon: Icons.download_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.android),
                ),
                title: const Text('Android 安装包'),
                subtitle: const Text('下载安装 APK，版本 $_appVersion'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _downloadAndroidApp(context),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _downloadAndroidApp(context),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('下载 Android 客户端'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '关于',
            icon: Icons.info_outline,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phishing_outlined),
                title: const Text('钓鱼佬'),
                subtitle: const Text('钓点、天气与渔获记录'),
                trailing: Text(
                  'v$_appVersion+$_appBuildNumber',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ThemeColorOption extends StatelessWidget {
  const _ThemeColorOption({
    required this.color,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label主题色',
      child: InkWell(
        key: ValueKey('theme-color-$label'),
        onTap: onSelected,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color,
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
