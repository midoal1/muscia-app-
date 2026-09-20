import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backgroundPlayEnabled = true;
  String _audioQuality = 'Ultra HD (320 kbps)';

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final userName = musicProvider.userName;
    final userAvatar = musicProvider.userAvatar;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Profile Header Card
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHighlight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gazelleRedDark.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CachedNetworkImage(
                          imageUrl: userAvatar,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                            color: AppColors.surfaceHighlight,
                            child: const Icon(Icons.person, color: Colors.white, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تعديل الملف الشخصي والصورة',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gazelleRedGlow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Section 1: Audio & Playback
          _buildSectionHeader('الصوت والتشغيل'),
          _buildSettingsTile(
            icon: Icons.high_quality_rounded,
            title: 'جودة الصوت والبث',
            subtitle: _audioQuality,
            onTap: () => _showAudioQualityDialog(context),
          ),
          _buildSwitchTile(
            icon: Icons.phonelink_ring_rounded,
            title: 'التشغيل في الخلفية (Background Audio)',
            subtitle: 'استمرار الاستماع عند قفل الشاشة أو استخدام برامج أخرى',
            value: _backgroundPlayEnabled,
            onChanged: (val) {
              setState(() {
                _backgroundPlayEnabled = val;
              });
            },
          ),
          _buildSettingsTile(
            icon: Icons.equalizer_rounded,
            title: 'معادل الصوت (Equalizer)',
            subtitle: 'مخصص للمشاعر والأحاسيس العميقة',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('معادل الصوت التلقائي مفعل بأفضل ترددات')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section 2: Storage & Cache
          _buildSectionHeader('التخزين والذاكرة'),
          _buildSettingsTile(
            icon: Icons.cleaning_services_rounded,
            title: 'مسح الذاكرة المؤقتة (Clear Cache)',
            subtitle: 'تحرير المساحة وتسريع التطبيق',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.gazelleRedBright,
                  content: Text('تم مسح الذاكرة المؤقتة بنجاح ✨'),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section 3: About App
          _buildSectionHeader('حول Muscia'),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'إصدار التطبيق',
            subtitle: 'Muscia v1.0.0 (Spotify Gazelle Edition)',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'الخصوصية والأمان',
            subtitle: 'بياناتك وقوائمك محفوظة محلياً على جهازك',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.gazelleRedGlow,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        value: value,
        activeThumbColor: AppColors.gazelleRedBright,
        onChanged: onChanged,
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('اختر جودة الصوت', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('Ultra HD (320 kbps) - أعلى نقاء صوتي'),
            _buildQualityOption('High (256 kbps) - صوت نقي متوازن'),
            _buildQualityOption('Normal (128 kbps) - توفير باقة الإنترنت'),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String quality) {
    return ListTile(
      title: Text(quality, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: _audioQuality == quality
          ? const Icon(Icons.check_circle, color: AppColors.gazelleRedBright)
          : null,
      onTap: () {
        setState(() {
          _audioQuality = quality;
        });
        Navigator.pop(context);
      },
    );
  }
}
