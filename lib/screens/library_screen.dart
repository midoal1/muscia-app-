import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Liked, 2: History

  final List<String> _filters = ['الكل', 'المفضلة', 'سجل الاستماع'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().refreshLibrary();
    });
  }

  void _openLikedSongsPlaylist(BuildContext context, List<Song> favorites) {
    final playlist = Playlist(
      id: 'liked_songs',
      title: 'الأغاني المفضلة',
      description: 'جميع الأغاني التي قمت بالإعجاب بها',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
      songs: favorites,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final favorites = musicProvider.favorites;
    final history = musicProvider.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppColors.background,
              title: const Text(
                'مكتبتي الموسيقية',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () {
                    // Create playlist dialog
                    _showCreatePlaylistDialog(context);
                  },
                ),
              ],
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(_filters[index]),
                          selected: isSelected,
                          selectedColor: AppColors.gazelleRedBright,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.gazelleRedBright : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Liked Songs Card (Always visible on All or Liked)
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: InkWell(
                    onTap: () => _openLikedSongsPlaylist(context, favorites),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gazelleRedBright,
                            AppColors.gazelleRedDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gazelleRedDark.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الأغاني المفضلة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${favorites.length} أغنية مضافة',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.gazelleRedDark,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Content based on tab
            if (_selectedFilterIndex == 1) ...[
              // Only Favorites List
              if (favorites.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'لا توجد أغانٍ مفضلة بعد. اضغط على رمز القلب عند الاستماع لإضافتها هنا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = favorites[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SongTile(
                          song: song,
                          queue: favorites,
                          index: index,
                          showIndex: true,
                        ),
                      );
                    },
                    childCount: favorites.length,
                  ),
                ),
            ] else if (_selectedFilterIndex == 2) ...[
              // Only History List
              if (history.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'سجل الاستماع فارغ حالياً.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = history[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SongTile(
                          song: song,
                          queue: history,
                          index: index,
                          showIndex: true,
                        ),
                      );
                    },
                    childCount: history.length,
                  ),
                ),
            ] else ...[
              // All: Show Recently Played Section
              if (history.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'سجل الاستماع الأخير',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = history[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SongTile(
                          song: song,
                          queue: history,
                          index: index,
                          showIndex: false,
                        ),
                      );
                    },
                    childCount: history.take(10).length,
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إنشاء قائمة تشغيل جديدة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'اسم القائمة...',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gazelleRedBright),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gazelleRedBright),
            child: const Text('إنشاء', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
