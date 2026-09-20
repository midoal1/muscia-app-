import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'artist_detail_screen.dart';
import 'playlist_detail_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    final displayName = name.isNotEmpty ? ' يا $name' : '';
    if (hour >= 5 && hour < 12) {
      return 'صباح الخير$displayName ☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'مساء الخير$displayName 🎵';
    } else {
      return 'مساء الروقان$displayName ✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final trending = musicProvider.trendingSongs;
    final playlists = musicProvider.featuredPlaylists;
    final artists = musicProvider.topArtists;
    final userName = musicProvider.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gazelleRedBright,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await musicProvider.loadTrending();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppColors.background.withValues(alpha: 0.9),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gazelleRedBright.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getGreeting(userName),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),

            // Top Quick Grid Cards (Spotify style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.9,
                  children: [
                    _buildQuickCard(
                      context,
                      title: 'الأغاني المفضلة',
                      icon: Icons.favorite,
                      gradient: AppColors.primaryGradient,
                      onTap: () {
                        // Switch to library tab or open favorites
                      },
                    ),
                    _buildQuickCard(
                      context,
                      title: 'عمرو دياب',
                      imageUrl: artists.isNotEmpty ? artists.first.imageUrl : '',
                      onTap: () {
                        if (artists.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(artist: artists.first),
                            ),
                          );
                        }
                      },
                    ),
                    _buildQuickCard(
                      context,
                      title: 'The Weeknd',
                      imageUrl: artists.length > 1 ? artists[1].imageUrl : '',
                      onTap: () {
                        if (artists.length > 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(artist: artists[1]),
                            ),
                          );
                        }
                      },
                    ),
                    _buildQuickCard(
                      context,
                      title: 'روقان وهدوء',
                      imageUrl: playlists.length > 1 ? playlists[1].coverUrl : '',
                      onTap: () {
                        if (playlists.length > 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(playlist: playlists[1]),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Section: Featured Playlists (قوائم مميزة)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.gazelleRedBright,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'أجواء موسيقية مختارة لك',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 185,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(playlist: playlist),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 140,
                                height: 130,
                                child: CachedNetworkImage(
                                  imageUrl: playlist.coverUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => Container(
                                    color: AppColors.surfaceLight,
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              playlist.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              playlist.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Section: Top Artists (أشهر الفنانين في العالم)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.gazelleRedBright,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'أشهر الفنانين في العالم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistDetailScreen(artist: artist),
                          ),
                        );
                      },
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderHighlight,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CachedNetworkImage(
                                    imageUrl: artist.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.person, color: Colors.white54),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Section: Trending Tracks
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.gazelleRedBright,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الأكثر رواجاً في العالم (Trending Hits)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (musicProvider.isLoadingTrending)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.gazelleRedBright),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = trending[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SongTile(
                        song: song,
                        queue: trending,
                        index: index,
                        showIndex: true,
                      ),
                    );
                  },
                  childCount: trending.length,
                ),
              ),

            // Bottom space for MiniPlayer + BottomNav
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    String? imageUrl,
    IconData? icon,
    LinearGradient? gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.primaryGradient,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              )
            else if (imageUrl != null && imageUrl.isNotEmpty)
              SizedBox(
                width: 54,
                height: 54,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
