import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/spots_provider.dart';

class AddSpotSheet extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const AddSpotSheet({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<AddSpotSheet> createState() => _AddSpotSheetState();
}

class _AddSpotSheetState extends State<AddSpotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _feeDescController = TextEditingController(text: '免费开放自然水域');
  final _addressController = TextEditingController(text: '浙江省杭州市优质水域');
  final _rulesController = TextEditingController(text: '随手带走垃圾，倡导钓获放流，留小留大');
  final _imageUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
  );

  late double _currentLat;
  late double _currentLng;
  bool _isLocating = false;

  String _waterType = '野钓';
  String _chargeType = '免费';
  double _depth = 2.5;
  final List<String> _selectedFish = ['鲫鱼', '鲤鱼'];

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _feeDescController.dispose();
    _addressController.dispose();
    _rulesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      setState(() {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _addressController.text =
            '当前所在地 (GPS: ${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已成功更新标点位置为当前设备所在 GPS 坐标')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('获取定位失败或超时: $e，已保留当前地图中心')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFish.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请至少选择一种出鱼鱼种')));
      return;
    }

    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    final success = await spotsProvider.createSpot(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : '钓友发现的宝藏钓点，环境幽静，鱼口活跃。',
      lat: _currentLat,
      lng: _currentLng,
      waterType: _waterType,
      chargeType: _chargeType,
      feeDesc: _feeDescController.text.trim(),
      fishTypes: _selectedFish,
      depthMeters: _depth,
      rules: _rulesController.text.trim(),
      address: _addressController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🎣 钓点标记成功！感谢为钓友们开拓新标点！')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('创建钓点失败，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.fishermanColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📍 标记新钓点',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '标点坐标: ${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.fishermanColors.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: _isLocating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.my_location,
                            size: 16,
                            color: context.fishermanColors.secondary,
                          ),
                    label: Text(
                      '定位到当前位置',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.fishermanColors.secondary,
                      ),
                    ),
                    onPressed: _isLocating ? null : _fetchCurrentLocation,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Spot Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '钓点名称 *',
                  hintText: '例如: 钱塘江三桥南岸排灌口',
                  prefixIcon: Icon(
                    Icons.pin_drop,
                    color: context.fishermanColors.primary,
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? '请输入钓点名称' : null,
              ),
              const SizedBox(height: 12),

              // Water Type & Charge Type
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _waterType,
                      decoration: const InputDecoration(labelText: '水域类型'),
                      items: AppConstants.waterTypes
                          .where((t) => t != '全部')
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _waterType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _chargeType,
                      decoration: const InputDecoration(labelText: '收费形式'),
                      items: AppConstants.chargeTypes
                          .where((t) => t != '全部')
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _chargeType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Depth Slider
              Text(
                '平均水深: ${_depth.toStringAsFixed(1)} 米',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: _depth,
                min: 0.5,
                max: 12.0,
                divisions: 23,
                label: '${_depth.toStringAsFixed(1)}m',
                activeColor: context.fishermanColors.primary,
                onChanged: (val) => setState(() => _depth = val),
              ),
              const SizedBox(height: 8),

              // Target Fish
              const Text(
                '出鱼鱼种 (多选)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: AppConstants.popularFishList.take(10).map((fish) {
                  final isSelected = _selectedFish.contains(fish);
                  return FilterChip(
                    label: Text(fish),
                    selected: isSelected,
                    selectedColor: context.fishermanColors.primary.withValues(
                      alpha: 0.15,
                    ),
                    checkmarkColor: context.fishermanColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? context.fishermanColors.primary
                          : context.fishermanColors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFish.add(fish);
                        } else {
                          _selectedFish.remove(fish);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '大概地址/道路指示',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '标点水情与作钓技巧分享',
                  hintText: '如: 离岸8米处有暗坎，早晚翘嘴吃口好',
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('立即标记并在地图展示'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
