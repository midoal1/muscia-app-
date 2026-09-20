import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final song = playerProvider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final double progress = playerProvider.duration.inMilliseconds > 0
        ? (playerProvider.position.inMilliseconds /
                playerProvider.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const NowPlayingScreen(),
            transitionsBuilder: (context, anim, secAnim, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: anim.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gazelleRedBright.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gazelleRedDark.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Album art with subtle glow
                    Hero(
                      tag: 'album_art_${song.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: song.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => Container(
                                    color: AppColors.gazelleRedDark,
                                    child: const Icon(Icons.music_note,
                                        color: Colors.white, size: 22),
                                  ),
                                )
                              : Container(
                                  color: AppColors.gazelleRedDark,
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white, size: 22),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Favorite Button
                    IconButton(
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        playerProvider.isFavorite(song.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: playerProvider.isFavorite(song.id)
                            ? AppColors.gazelleRedGlow
                            : AppColors.textTertiary,
                      ),
                      onPressed: () => playerProvider.toggleFavorite(song),
                    ),
                    const SizedBox(width: 12),

                    // Play/Pause Button
                    GestureDetector(
                      onTap: () => playerProvider.togglePlayPause(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: Center(
                          child: playerProvider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  playerProvider.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Skip Next Button
                    IconButton(
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => playerProvider.next(),
                    ),
                  ],
                ),
              ),

              // Thin Bottom Progress Bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.gazelleRedBright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
