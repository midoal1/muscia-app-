import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'title': 'أهلاً بك في عالم Muscia الموسيقي ✨',
      'body': 'استمتع الآن بملايين الأغاني لجميع فناني العالم وتشغيل غير محدود في الخلفية.',
      'time': 'الآن',
      'icon': Icons.music_note_rounded,
      'isNew': true,
    },
    {
      'title': 'جودة الصوت الفائقة Ultra HD مفعلة 🎧',
      'body': 'تم تفعيل أعلى ترددات ونقاء صوتي 320kbps لتقديم تجربة استماع شاعري غامرة.',
      'time': 'منذ ساعة',
      'icon': Icons.high_quality_rounded,
      'isNew': true,
    },
    {
      'title': 'جديد التريند العربي والعالمي 🔥',
      'body': 'تمت إضافة أحدث إصدارات عمرو دياب، ويجز، The Weeknd، وغيرهم إلى قائمة التريند.',
      'time': 'أمس',
      'icon': Icons.local_fire_department_rounded,
      'isNew': false,
    },
    {
      'title': 'التشغيل في الخلفية وشاشة القفل 🔔',
      'body': 'يمكنك الآن إقفال الهاتف أو التبديل لأي تطبيق آخر والموسيقى ستستمر بالعزف.',
      'time': 'منذ يومين',
      'icon': Icons.phonelink_lock_rounded,
      'isNew': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التنبيهات والإشعارات'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final isNew = item['isNew'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isNew ? AppColors.gazelleRedBright.withValues(alpha: 0.4) : AppColors.borderSubtle,
                width: 1,
              ),
              boxShadow: isNew
                  ? [
                      BoxShadow(
                        color: AppColors.gazelleRedDark.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNew ? AppColors.gazelleRedDark : AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: isNew ? AppColors.gazelleRedGlow : Colors.white70,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isNew ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                          Text(
                            item['time'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['body'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
