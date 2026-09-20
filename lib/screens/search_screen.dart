import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _genres = [
    {
      'title': 'طرب وأصالة',
      'query': 'أغاني طرب عربي أصيل',
      'colors': [const Color(0xFF8B0021), const Color(0xFF4A0012)],
      'icon': Icons.music_note,
    },
    {
      'title': 'بوب عالمي (Pop)',
      'query': 'Global Pop Hits 2025',
      'colors': [const Color(0xFFB31336), const Color(0xFF670C1D)],
      'icon': Icons.star,
    },
    {
      'title': 'هيب هوب وتراب',
      'query': 'Arabic Hip Hop Trap',
      'colors': [const Color(0xFF5B1020), const Color(0xFF26040C)],
      'icon': Icons.graphic_eq,
    },
    {
      'title': 'شجن ورومانسية',
      'query': 'أغاني رومانسية حزينة هادئة',
      'colors': [const Color(0xFF7A1D32), const Color(0xFF3B0B16)],
      'icon': Icons.favorite,
    },
    {
      'title': 'روقان وهدوء',
      'query': 'Chill Acoustic Vibes',
      'colors': [const Color(0xFF8F1E3A), const Color(0xFF450D19)],
      'icon': Icons.spa,
    },
    {
      'title': 'طاقة وتمارين (Workout)',
      'query': 'Workout Music EDM Gym',
      'colors': [const Color(0xFFC41C42), const Color(0xFF780B23)],
      'icon': Icons.fitness_center,
    },
    {
      'title': 'كلاسيكيات الزمن الجميل',
      'query': 'أم كلثوم عبد الحليم فيروز',
      'colors': [const Color(0xFF691526), const Color(0xFF2E070F)],
      'icon': Icons.album,
    },
    {
      'title': 'روك وموسيقى بديلة (Rock)',
      'query': 'Rock Alternative Top Hits',
      'colors': [const Color(0xFF9E1433), const Color(0xFF500818)],
      'icon': Icons.speaker,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      context.read<MusicProvider>().clearSearch();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      context.read<MusicProvider>().search(clean);
    });
  }

  void _searchGenre(String query, String title) {
    _controller.text = title;
    _debounceTimer?.cancel();
    context.read<MusicProvider>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final isSearching = musicProvider.isSearching;
    final results = musicProvider.searchResults;
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'بحث في عالم الموسيقى',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasQuery ? AppColors.gazelleRedBright : Colors.white12,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearchChanged,
                  onSubmitted: (val) {
                    _debounceTimer?.cancel();
                    if (val.trim().isNotEmpty) {
                      context.read<MusicProvider>().search(val.trim());
                    }
                  },
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن أي فنان، أغنية، أو ألبوم في العالم...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gazelleRedBright),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () {
                              _controller.clear();
                              _debounceTimer?.cancel();
                              musicProvider.clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Fast, non-blocking loading indicator
            const SizedBox(height: 6),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  child: LinearProgressIndicator(
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gazelleRedBright),
                  ),
                ),
              )
            else
              const SizedBox(height: 2.5),

            const SizedBox(height: 8),

            // Search Content / Results
            Expanded(
              child: hasQuery
                  ? results.isEmpty && !isSearching
                      ? const Center(
                          child: Text(
                            'لم يتم العثور على نتائج، جرب كلمات بحث أخرى',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: results.length + 1,
                          itemBuilder: (context, index) {
                            if (index == results.length) {
                              return const SizedBox(height: 120);
                            }
                            final song = results[index];
                            return SongTile(
                              song: song,
                              queue: results,
                              index: index,
                              showIndex: false,
                            );
                          },
                        )
                  : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تصفح كل الأنواع الموسيقية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _genres.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.8,
                                ),
                                itemBuilder: (context, index) {
                                  final genre = _genres[index];
                                  final colors = genre['colors'] as List<Color>;
                                  return InkWell(
                                    onTap: () => _searchGenre(genre['query'], genre['title']),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: colors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.first.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              genre['title'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Transform.rotate(
                                              angle: -0.2,
                                              child: Icon(
                                                genre['icon'] as IconData,
                                                size: 38,
                                                color: Colors.white.withValues(alpha: 0.35),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
