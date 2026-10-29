import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late TextEditingController _yearsController;
  late TextEditingController _targetFishController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _yearsController = TextEditingController(text: (user?.fishingYears ?? 1).toString());
    _targetFishController = TextEditingController(text: user?.targetFish ?? '鲫鱼、鲤鱼');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _targetFishController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final years = int.tryParse(_yearsController.text) ?? 1;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      fishingYears: years,
      targetFish: _targetFishController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('个人资料保存成功！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存资料失败，请稍后再试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改钓友资料'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '钓友昵称 *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? '昵称不能为空' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '钓龄 (年)',
                prefixIcon: Icon(Icons.hourglass_bottom_outlined),
                suffixText: '年',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetFishController,
              decoration: const InputDecoration(
                labelText: '主攻鱼种',
                hintText: '如: 翘嘴、鳜鱼、大板鲫',
                prefixIcon: Icon(Icons.phishing),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '个性钓语 / 签名',
                hintText: '写下你的钓鱼哲学或誓言...',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _save,
              child: const Text('保存个人档案'),
            ),
          ],
        ),
      ),
    );
  }
}
