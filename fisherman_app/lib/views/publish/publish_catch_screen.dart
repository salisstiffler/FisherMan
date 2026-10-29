import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/spot_model.dart';
import '../../providers/catches_provider.dart';
import '../../providers/spots_provider.dart';

class PublishCatchScreen extends StatefulWidget {
  final SpotModel? preSelectedSpot;

  const PublishCatchScreen({super.key, this.preSelectedSpot});

  @override
  State<PublishCatchScreen> createState() => _PublishCatchScreenState();
}

class _PublishCatchScreenState extends State<PublishCatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '1.5');
  final _lengthController = TextEditingController(text: '35');
  final _baitController = TextEditingController(text: '商品饵/拟饵');
  final _notesController = TextEditingController();
  final _customSpotNameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String _activePhotoUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600';

  int? _selectedSpotId;
  String _selectedSpotName = '钱塘江野钓点';
  String _selectedSpotAddress = '浙江省杭州市钱塘江沿江湿地公园';
  double _selectedSpotLat = 30.244;
  double _selectedSpotLng = 120.145;
  String _selectedSpotWaterType = '野钓';
  String _selectedSpotChargeType = '免费';

  String _selectedFish = '鲫鱼';
  String _selectedMethod = '台钓';
  double _depth = 2.0;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedSpot != null) {
      _selectedSpotId = widget.preSelectedSpot!.id;
      _selectedSpotName = widget.preSelectedSpot!.name;
      _selectedSpotAddress = widget.preSelectedSpot!.address;
      _selectedSpotLat = widget.preSelectedSpot!.lat;
      _selectedSpotLng = widget.preSelectedSpot!.lng;
      _selectedSpotWaterType = widget.preSelectedSpot!.waterType;
      _selectedSpotChargeType = widget.preSelectedSpot!.chargeType;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _baitController.dispose();
    _notesController.dispose();
    _customSpotNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          _activePhotoUrl = file.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(source == ImageSource.camera ? '📷 拍摄照片成功！' : '🖼️ 已从相册选取大鱼实拍图！')),
          );
        }
      }
    } catch (e) {
      debugPrint('Image picking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text) ?? 1.0;
    final length = double.tryParse(_lengthController.text) ?? 0.0;
    final spotName = _customSpotNameController.text.trim().isNotEmpty
        ? _customSpotNameController.text.trim()
        : _selectedSpotName;

    final catchesProvider = Provider.of<CatchesProvider>(context, listen: false);
    final success = await catchesProvider.publishCatch(
      spotId: _selectedSpotId,
      spotName: spotName,
      spotAddress: _selectedSpotAddress,
      spotLat: _selectedSpotLat,
      spotLng: _selectedSpotLng,
      spotWaterType: _selectedSpotWaterType,
      spotChargeType: _selectedSpotChargeType,
      fishType: _selectedFish,
      weightKg: weight,
      lengthCm: length,
      fishingMethod: _selectedMethod,
      depthM: _depth,
      bait: _baitController.text.trim(),
      photoUrl: _activePhotoUrl,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : '今日出钓大丰收！大鱼出水那一刻手感太棒了！',
    );

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 恭喜大师！战报已发布！'),
            content: Text(
              '成功录入 $_selectedFish (重 ${weight.toStringAsFixed(1)} kg)！已同步更新至钓友动态流与您的个人战报册。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.preSelectedSpot != null) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('太棒了'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布战报失败，请稍后再试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsProvider = Provider.of<SpotsProvider>(context);
    final spots = spotsProvider.spots;

    return Scaffold(
      appBar: AppBar(
        title: const Text('发布渔获战报'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker Section (Camera & Gallery)
              const Text('渔获实拍照片 *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    if (_pickedBytes != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.memory(
                              _pickedBytes!,
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _pickedBytes = null;
                                    _activePhotoUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600';
                                  });
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('已选实拍照片', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.primary),
                            const SizedBox(height: 8),
                            const Text(
                              '请拍照记录或从相册选择大鱼实拍照',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '支持拍摄、相册上传与经典大鱼样本',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),

                    // Action buttons: Camera vs Gallery
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('拍照'),
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('相册上传'),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Preset Quick Sample Photos
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Row(
                        children: [
                          const Text('样本图: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSampleChip('大翘嘴', 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600'),
                                  _buildSampleChip('黄金板鲫', 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600'),
                                  _buildSampleChip('加州鲈', 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=600'),
                                  _buildSampleChip('斑斓马口', 'https://images.unsplash.com/photo-1508873696983-2df5293cb325?w=600'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fish Species Selection
              const Text('目标鱼种 *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.popularFishList.take(12).map((fish) {
                  final isSelected = _selectedFish == fish;
                  return ChoiceChip(
                    label: Text(fish),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedFish = fish),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Weight & Length Inputs
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '单尾重量 (kg) *',
                        suffixText: '公斤',
                        prefixIcon: Icon(Icons.scale, color: AppColors.primary),
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? '请输入重量' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '体长 (cm)',
                        suffixText: '厘米',
                        prefixIcon: Icon(Icons.straighten, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fishing Method Selection
              const Text('作钓钓法 *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.fishingMethods.map((method) {
                  final isSelected = _selectedMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    selectedColor: AppColors.secondary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedMethod = method),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Spot Link
              const Text('作钓水域与具体位置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (spots.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: _selectedSpotId ?? spots.first.id,
                  decoration: const InputDecoration(
                    labelText: '选择关联钓点',
                    prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  items: spots.map((s) {
                    return DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text('${s.name} (${s.waterType})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final spot = spots.firstWhere((s) => s.id == val);
                      setState(() {
                        _selectedSpotId = val;
                        _selectedSpotName = spot.name;
                        _selectedSpotAddress = spot.address;
                        _selectedSpotLat = spot.lat;
                        _selectedSpotLng = spot.lng;
                        _selectedSpotWaterType = spot.waterType;
                        _selectedSpotChargeType = spot.chargeType;
                      });
                    }
                  },
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customSpotNameController,
                decoration: InputDecoration(
                  labelText: '或自定义秘密水域名称',
                  hintText: '如: 淳安老家门前小水塘',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(height: 16),

              // Depth & Bait
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('作钓水深: ${_depth.toStringAsFixed(1)}m', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Slider(
                          value: _depth,
                          min: 0.5,
                          max: 10.0,
                          divisions: 19,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _depth = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _baitController,
                decoration: const InputDecoration(
                  labelText: '所用饵料 / 拟饵型号',
                  hintText: '例如: 918大野战 + 蓝鲫 / 10g沉水亮片',
                  prefixIcon: Icon(Icons.bubble_chart_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Notes / Fighting story
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '扬竿经过与出钓心路',
                  hintText: '分享水情、口癖、扬竿刺鱼的瞬间和喜悦...',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('发布战报 • 荣耀分享', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleChip(String label, String url) {
    final isCurrent = _activePhotoUrl == url && _pickedBytes == null;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: isCurrent ? AppColors.primary : AppColors.lightBackground,
        labelStyle: TextStyle(
          fontSize: 10,
          color: isCurrent ? Colors.white : AppColors.textPrimary,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
        onPressed: () {
          setState(() {
            _pickedBytes = null;
            _activePhotoUrl = url;
          });
        },
      ),
    );
  }
}
