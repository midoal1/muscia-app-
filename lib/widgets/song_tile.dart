import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final bool showIndex;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.showIndex = false,
  });

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final isCurrent = playerProvider.currentSong?.id == song.id;
    final isPlaying = isCurrent && playerProvider.isPlaying;
    final isFavorite = playerProvider.isFavorite(song.id);

    return InkWell(
      onTap: () {
        playerProvider.playSong(song, contextQueue: queue, initialIndex: index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.surfaceLight.withValues(alpha: 0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(color: AppColors.borderHighlight, width: 1)
              : null,
        ),
        child: Row(
          children: [
            if (showIndex) ...[
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent ? AppColors.gazelleRedGlow : AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: song.artworkUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.artworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gazelleRedBright,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceHighlight,
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceHighlight,
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? AppColors.gazelleRedGlow : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Duration
            if (song.duration.inSeconds > 0) ...[
              Text(
                _formatDuration(song.duration),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Favorite Button
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.gazelleRedGlow : AppColors.textTertiary,
              ),
              onPressed: () {
                playerProvider.toggleFavorite(song);
              },
            ),

            // Playing Status Indicator
            if (isCurrent) ...[
              const SizedBox(width: 10),
              Icon(
                isPlaying ? Icons.graphic_eq : Icons.pause_circle_outline,
                size: 20,
                color: AppColors.gazelleRedGlow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
