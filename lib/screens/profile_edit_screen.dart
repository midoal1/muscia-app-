import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _avatarUrlController;
  late String _selectedAvatar;

  // Preset aesthetic avatars
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=300&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=300&q=80',
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300&q=80',
    'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=300&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MusicProvider>();
    _nameController = TextEditingController(text: provider.userName);
    _selectedAvatar = provider.userAvatar;
    _avatarUrlController = TextEditingController(text: provider.userAvatar);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسمك')),
      );
      return;
    }

    final avatar = _avatarUrlController.text.trim().isNotEmpty
        ? _avatarUrlController.text.trim()
        : _selectedAvatar;

    context.read<MusicProvider>().updateProfile(
          name: name,
          avatarUrl: avatar,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.gazelleRedBright,
        content: Text('تم حفظ الملف الشخصي بنجاح ✨'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: AppColors.gazelleRedGlow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Main Selected Avatar Preview with Glowing Border
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gazelleRedBright.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: CachedNetworkImage(
                          imageUrl: _selectedAvatar,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.gazelleRedBright,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Profile Name Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'اسم الملف الشخصي',
                  labelStyle: TextStyle(color: AppColors.gazelleRedGlow),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Custom Avatar URL Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TextField(
                controller: _avatarUrlController,
                onChanged: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _selectedAvatar = val.trim();
                    });
                  }
                },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'رابط صورة مخصصة (Image URL)',
                  labelStyle: TextStyle(color: AppColors.textTertiary),
                  hintText: 'https://example.com/photo.jpg',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.link, color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Presets Header
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اختر صورة رمزية جاهزة:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Presets Avatar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _presetAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final avatar = _presetAvatars[index];
                final isSelected = _selectedAvatar == avatar;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                      _avatarUrlController.text = avatar;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.gazelleRedBright : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.gazelleRedBright.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gazelleRedBright,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'حفظ التغييرات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
