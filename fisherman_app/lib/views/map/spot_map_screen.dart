import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/spot_model.dart';
import '../../providers/spots_provider.dart';
import '../../providers/weather_provider.dart';
import 'spot_detail_screen.dart';
import 'add_spot_sheet.dart';

class SpotMapScreen extends StatefulWidget {
  final LatLng? initialFocusCenter;

  const SpotMapScreen({super.key, this.initialFocusCenter});

  @override
  State<SpotMapScreen> createState() => _SpotMapScreenState();
}

class _SpotMapScreenState extends State<SpotMapScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _isListView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialFocusCenter ?? const LatLng(30.244, 120.145);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpotsProvider>(context, listen: false).fetchSpots();
      Provider.of<WeatherProvider>(context, listen: false).fetchWeather(
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
      );
      // Automatically attempt to locate user
      _locateUser(silent: true);
    });
  }

  @override
  void didUpdateWidget(covariant SpotMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocusCenter != null &&
        widget.initialFocusCenter != oldWidget.initialFocusCenter) {
      _currentCenter = widget.initialFocusCenter!;
      _mapController.move(_currentCenter, 13.0);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locateUser({bool silent = false}) async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('设备定位服务未开启，已保持默认水域中心')));
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('定位权限已拒绝，您可通过拖拽地图进行选点')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('定位权限被永久拒绝，请在系统设置中开启')));
        }
        setState(() => _isLocating = false);
        return;
      }

      // Fetch real GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = userLatLng;
        _currentCenter = userLatLng;
      });

      _mapController.move(userLatLng, 13.0);
      if (mounted) {
        Provider.of<WeatherProvider>(
          context,
          listen: false,
        ).fetchWeather(lat: userLatLng.latitude, lng: userLatLng.longitude);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '已定位至当前位置: ${userLatLng.latitude.toStringAsFixed(4)}, ${userLatLng.longitude.toStringAsFixed(4)}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Geolocation error: $e');
      // If error occurs on desktop/emulator, set graceful simulated location
      if (_userLocation == null) {
        setState(() {
          _userLocation = const LatLng(30.244, 120.145);
        });
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('定位获取超时，已切换至周边自然水域中心')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _openAddSpotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSpotSheet(
        initialLat: _currentCenter.latitude,
        initialLng: _currentCenter.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsProvider = Provider.of<SpotsProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final spots = spotsProvider.spots;
    final weather = weatherProvider.weather;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View or List View
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: _isListView
                ? KeyedSubtree(
                    key: const ValueKey('spot-list'),
                    child: _buildListView(spots),
                  )
                : KeyedSubtree(
                    key: const ValueKey('spot-map'),
                    child: _buildMapView(spots, spotsProvider),
                  ),
          ),

          // 2. Top Header & Floating Weather Card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar with View Switcher
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.98),
                          Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.91),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.fishermanColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: context.fishermanColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: '搜索附近钓点、鱼种、水库...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (val) {
                              spotsProvider.setSearchKeyword(val.trim());
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              spotsProvider.setSearchKeyword('');
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            _isListView
                                ? Icons.map_outlined
                                : Icons.format_list_bulleted,
                            color: context.fishermanColors.primary,
                          ),
                          tooltip: _isListView ? '切换地图模式' : '切换列表模式',
                          onPressed: () {
                            setState(() {
                              _isListView = !_isListView;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Water Type Filter Pills
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: -8,
                      children: AppConstants.waterTypes.map((type) {
                        final isSelected =
                            spotsProvider.selectedWaterType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: context.fishermanColors.primary,
                          backgroundColor: Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.94),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? context.fishermanColors.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          visualDensity: const VisualDensity(
                            horizontal: -2,
                            vertical: -3,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: isSelected
                                ? context.fishermanColors.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          elevation: isSelected ? 2 : 0,
                          pressElevation: 3,
                          onSelected: (_) => spotsProvider.setWaterType(type),
                        );
                      }).toList(),
                    ),
                  ),

                  // Real-time Barometric Pressure Banner for Anglers
                  if (!_isListView)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.fishermanColors.primary.withValues(
                              alpha: 0.97,
                            ),
                            context.fishermanColors.primary.withValues(
                              alpha: 0.94,
                            ),
                            context.fishermanColors.secondary.withValues(
                              alpha: 0.9,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.fishermanColors.primary.withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (weatherProvider.errorMessage != null)
                            Expanded(
                              child: Text(
                                weatherProvider.errorMessage!,
                                style: TextStyle(
                                  color: context.fishermanColors.onPrimary,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    color: context.fishermanColors.tertiary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '气压 ${weather.pressure} · ${weather.temperature}',
                                      style: TextStyle(
                                        color:
                                            context.fishermanColors.onPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (weatherProvider.errorMessage != null)
                            IconButton(
                              tooltip: '重试天气查询',
                              onPressed: () => weatherProvider.fetchWeather(
                                lat: _currentCenter.latitude,
                                lng: _currentCenter.longitude,
                              ),
                              icon: Icon(
                                Icons.refresh,
                                color: context.fishermanColors.onTertiary,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.fishermanColors.tertiary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${weather.fishingStatus} (${weather.fishingScore}分)',
                                style: TextStyle(
                                  color: context.fishermanColors.onTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Floating GPS Location Button (定位到当前地点)
          if (!_isListView)
            Positioned(
              right: 16,
              bottom: spotsProvider.selectedSpot != null ? 180 : 96,
              child: FloatingActionButton.small(
                heroTag: 'locate_btn',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: context.fishermanColors.primary,
                tooltip: '定位到当前地点',
                onPressed: _isLocating ? null : () => _locateUser(),
                child: _isLocating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.fishermanColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

          // 4. Bottom Selected Spot Preview Card
          if (!_isListView && spotsProvider.selectedSpot != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.16),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildSpotBottomPreview(
                  spotsProvider.selectedSpot!,
                  spotsProvider,
                  key: ValueKey(spotsProvider.selectedSpot!.id),
                ),
              ),
            ),

          // 5. Center Crosshair indicator when navigating map
          if (!_isListView && spotsProvider.selectedSpot == null)
            Center(
              child: Icon(
                Icons.add_location,
                color: context.fishermanColors.primary,
                size: 28,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_spot_btn',
        onPressed: _openAddSpotSheet,
        backgroundColor: context.fishermanColors.primary,
        foregroundColor: context.fishermanColors.onPrimary,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          '标记钓点',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMapView(List<SpotModel> spots, SpotsProvider provider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: 11.5,
        onPositionChanged: (pos, hasGesture) {
          _currentCenter = pos.center;
        },
        onTap: (_, _) {
          provider.selectSpot(null);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fisherman.app',
        ),
        MarkerLayer(
          markers: _userLocation == null
              ? const []
              : [
                  Marker(
                    point: _userLocation!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.fishermanColors.secondary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.fishermanColors.secondary,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 48,
            disableClusteringAtZoom: 15,
            size: const Size(44, 44),
            maxZoom: 17,
            markers: spots.map((spot) {
              final isSelected = provider.selectedSpot?.id == spot.id;
              return Marker(
                point: LatLng(spot.lat, spot.lng),
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                child: AnimatedScale(
                  scale: isSelected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [
                                context.fishermanColors.tertiary,
                                context.fishermanColors.tertiary,
                              ]
                            : [
                                context.fishermanColors.primary,
                                context.fishermanColors.primary,
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3.5 : 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSelected
                                      ? context.fishermanColors.tertiary
                                      : context.fishermanColors.primary)
                                  .withValues(alpha: 0.4),
                          blurRadius: isSelected ? 18 : 10,
                          spreadRadius: isSelected ? 2 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.phishing,
                        color: isSelected
                            ? context.fishermanColors.onTertiary
                            : context.fishermanColors.onPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            onMarkerTap: (marker) {
              final spot = spots.firstWhere(
                (item) =>
                    item.lat == marker.point.latitude &&
                    item.lng == marker.point.longitude,
              );
              provider.selectSpot(spot);
              _mapController.move(marker.point, 12.5);
            },
            builder: (context, markers) => Container(
              decoration: BoxDecoration(
                color: context.fishermanColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${markers.length}',
                  style: TextStyle(
                    color: context.fishermanColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<SpotModel> spots) {
    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 54,
              color: context.fishermanColors.onSurfaceVariant,
            ),
            SizedBox(height: 12),
            Text(
              '未搜索到匹配的钓点，试着换个筛选条件吧',
              style: TextStyle(color: context.fishermanColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 150, bottom: 80, left: 16, right: 16),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(spot.id),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + (index % 6) * 55),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - progress)),
              child: child,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpotDetailScreen(spot: spot),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        spot.imageUrl ?? 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 90,
                          height: 90,
                          color: context.fishermanColors.primary,
                          child: Icon(
                            Icons.water,
                            color: context.fishermanColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spot.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.fishermanColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  spot.waterType,
                                  style: TextStyle(
                                    color: context.fishermanColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.fishermanColors.secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  spot.chargeType,
                                  style: TextStyle(
                                    color: context.fishermanColors.secondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '水深 ${spot.depthMeters}m',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      context.fishermanColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spot.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.fishermanColors.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotBottomPreview(
    SpotModel spot,
    SpotsProvider provider, {
    Key? key,
  }) {
    return Card(
      key: key,
      elevation: 8,
      shadowColor: context.fishermanColors.primary.withValues(alpha: 0.22),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => provider.selectSpot(null),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.place,
                    size: 14,
                    color: context.fishermanColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      spot.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${spot.catchCount} 条战绩 · ${spot.chargeType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.fishermanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '常见鱼种：${spot.fishTypes.take(3).join(' · ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.fishermanColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 420),
                        pageBuilder: (_, animation, secondaryAnimation) =>
                            SpotDetailScreen(spot: spot),
                        transitionsBuilder:
                            (_, animation, secondaryAnimation, child) {
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('详情与战绩'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
