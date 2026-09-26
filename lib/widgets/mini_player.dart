import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final song = playerProvider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    if (playerProvider.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    final double progress = playerProvider.duration.inMilliseconds > 0
        ? (playerProvider.position.inMilliseconds / playerProvider.duration.inMilliseconds)
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
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: anim.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.miniPlayerGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.borderHighlight,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.gazelleRedDark.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Micro glowing progress line on top
                  Container(
                    height: 2.5,
                    width: double.infinity,
                    color: Colors.white10,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.glowingRedGradient,
                        ),
                      ),
                    ),
                  ),

                  // Mini Player Controls Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Rotating Vinyl Artwork with ambient halo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: playerProvider.isPlaying
                                        ? AppColors.gazelleRedBright.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            RotationTransition(
                              turns: _rotationController,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gazelleRedGlow.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: song.artworkUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: song.artworkUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (c, u, e) => Container(
                                            color: AppColors.gazelleRedDark,
                                            child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                          ),
                                        )
                                      : Container(
                                          color: AppColors.gazelleRedDark,
                                          child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                        ),
                                ),
                              ),
                            ),
                            // Tiny vinyl center pin
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.background,
                                border: Border.all(color: Colors.white54, width: 1),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Song Details & Animated Equalizer Indicator
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (playerProvider.isPlaying) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.graphic_eq_rounded, color: AppColors.gazelleRedGlow, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Quick Like/Favorite Button
                        IconButton(
                          icon: Icon(
                            playerProvider.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
                            color: playerProvider.isFavorite(song.id) ? AppColors.gazelleRedBright : Colors.white70,
                            size: 22,
                          ),
                          onPressed: () => playerProvider.toggleFavorite(song),
                        ),

                        // Glowing Circular Play/Pause Action
                        InkWell(
                          onTap: () => playerProvider.togglePlayPause(),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.glowingRedGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gazelleRedBright.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: playerProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(
                                      playerProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
