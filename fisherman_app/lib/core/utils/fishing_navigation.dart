import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FishingNavigation {
  static Future<void> open(
    BuildContext context, {
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final coordinates =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final mapsUrl = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': coordinates,
      'travelmode': 'driving',
    });

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      await _showNavigationInfo(
        context,
        name: name,
        address: address,
        coordinates: coordinates,
        mapsUrl: mapsUrl,
      );
      return;
    }

    final Uri primaryUri;
    final Uri fallbackUri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      primaryUri = Uri(
        scheme: 'google.navigation',
        queryParameters: {'q': coordinates, 'mode': 'd'},
      );
      fallbackUri = Uri(
        scheme: 'geo',
        path: '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
        queryParameters: {'q': '$coordinates ($name)'},
      );
    } else {
      primaryUri = Uri.https('maps.apple.com', '/', {
        'daddr': coordinates,
        'dirflg': 'd',
      });
      fallbackUri = mapsUrl;
    }

    try {
      if (await launchUrl(primaryUri, mode: LaunchMode.externalApplication) ||
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('无法启动地图应用：$error')));
      }
      return;
    }

    if (context.mounted) {
      await _showNavigationInfo(
        context,
        name: name,
        address: address,
        coordinates: coordinates,
        mapsUrl: mapsUrl,
      );
    }
  }

  static Future<void> _showNavigationInfo(
    BuildContext context, {
    required String name,
    required String address,
    required String coordinates,
    required Uri mapsUrl,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.directions_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('前往$name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('导航目的地'),
            const SizedBox(height: 4),
            SelectableText(address),
            const SizedBox(height: 16),
            const Text('GPS 坐标'),
            const SizedBox(height: 4),
            SelectableText(coordinates),
            const SizedBox(height: 12),
            Text(
              '可复制地址或坐标到地图应用，也可以在浏览器中打开路线。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '$address\n$coordinates'),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('地址和坐标已复制')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制信息'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final launched = await launchUrl(
                mapsUrl,
                mode: LaunchMode.externalApplication,
              );
              if (!dialogContext.mounted) return;
              if (launched) {
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开地图链接，请复制目的地信息')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开路线'),
          ),
        ],
      ),
    );
  }
}
