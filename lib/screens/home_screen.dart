import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
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
      return 'مساء الأنغام$displayName ✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playerProvider = context.watch<PlayerProvider>();
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
            // Elegant App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppColors.background.withValues(alpha: 0.85),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.glowingRedGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gazelleRedBright.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getGreeting(userName),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  tooltip: 'الإشعارات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'الإعدادات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
            ),

            // Hero Billboard Banner (Featured Spotlight)
            SliverToBoxAdapter(
              child: _buildHeroBillboard(context, playerProvider, trending),
            ),

            // Section: Quick Bento Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  children: [
                    _buildBentoCard(
                      context,
                      title: 'الأغاني المفضلة',
                      icon: Icons.favorite_rounded,
                      gradient: AppColors.primaryGradient,
                      onTap: () {
                        // Switch or open favorites
                      },
                    ),
                    _buildBentoCard(
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
                    _buildBentoCard(
                      context,
                      title: 'ويجز (Wegz)',
                      imageUrl: artists.length > 4 ? artists[4].imageUrl : '',
                      onTap: () {
                        if (artists.length > 4) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(artist: artists[4]),
                            ),
                          );
                        }
                      },
                    ),
                    _buildBentoCard(
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
                    _buildBentoCard(
                      context,
                      title: 'طرب وأصالة',
                      imageUrl: playlists.isNotEmpty ? playlists.first.coverUrl : '',
                      onTap: () {
                        if (playlists.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(playlist: playlists.first),
                            ),
                          );
                        }
                      },
                    ),
                    _buildBentoCard(
                      context,
                      title: 'طاقة ونشاط',
                      imageUrl: playlists.length > 2 ? playlists[2].coverUrl : '',
                      onTap: () {
                        if (playlists.length > 2) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(playlist: playlists[2]),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Section: Featured Playlists (أجواء موسيقية)
            SliverToBoxAdapter(
              child: _buildSectionHeader('أجواء موسيقية مختارة'),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 195,
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
                        width: 145,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderHighlight, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: playlist.coverUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => Container(
                                        color: AppColors.surfaceLight,
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                                    ),
                                    // Gradient overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.7),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    // Play icon overlay
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppColors.glowingRedGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gazelleRedBright.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
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

            // Section: Top Global & Arabic Artists
            SliverToBoxAdapter(
              child: _buildSectionHeader('أشهر الفنانين في العالم'),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
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
                        width: 95,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing ring
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.glowingRedGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gazelleRedBright.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                // Inner avatar
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.background, width: 2.5),
                                  ),
                                  child: ClipOval(
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
                                // Verified Badge
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.gazelleRedBright,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

            // Section: Trending Hits
            SliverToBoxAdapter(
              child: _buildSectionHeader('الأكثر رواجاً في العالم (Trending Hits)'),
            ),

            if (musicProvider.isLoadingTrending)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
              child: SizedBox(height: 130),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Spotlight Billboard Banner
  Widget _buildHeroBillboard(
    BuildContext context,
    PlayerProvider playerProvider,
    List<dynamic> trending,
  ) {
    final featuredSong = trending.isNotEmpty ? trending.first : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderHighlight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.gazelleRedDark.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Artwork
            CachedNetworkImage(
              imageUrl: featuredSong?.artworkUrl ??
                  'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
              fit: BoxFit.cover,
              errorWidget: (c, u, e) => Container(color: AppColors.gazelleRedDark),
            ),

            // Gradient Tint
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroBannerGradient,
              ),
            ),

            // Text and Play Action
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gazelleRedBright,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مختار لك اليوم (Daily Spotlight)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    featuredSong?.title ?? 'مكانك (Makank)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    featuredSong?.artist ?? 'عمرو دياب',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      if (featuredSong != null) {
                        playerProvider.playSong(featuredSong, contextQueue: trending.cast());
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.glowingRedGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gazelleRedBright.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'تشغيل الآن',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.glowingRedGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    String? imageUrl,
    IconData? icon,
    LinearGradient? gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 54,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.primaryGradient,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              )
            else if (imageUrl != null && imageUrl.isNotEmpty)
              SizedBox(
                width: 54,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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
