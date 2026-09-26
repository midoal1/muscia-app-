import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isDraggingSlider = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showQueueSheet(BuildContext context, PlayerProvider playerProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final queue = playerProvider.queue;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'قائمة الانتظار (Queue)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${queue.length} أغنية',
                    style: const TextStyle(
                      color: AppColors.gazelleRedGlow,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = index == playerProvider.currentIndex;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: CachedNetworkImage(
                            imageUrl: song.artworkUrl,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.music_note, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AppColors.gazelleRedGlow : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.graphic_eq, color: AppColors.gazelleRedGlow)
                          : null,
                      onTap: () {
                        playerProvider.playSong(song, contextQueue: queue, initialIndex: index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, PlayerProvider playerProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final remaining = playerProvider.duration - playerProvider.position;
        final options = [
          {'title': 'إيقاف بعد 15 دقيقة', 'duration': const Duration(minutes: 15)},
          {'title': 'إيقاف بعد 30 دقيقة', 'duration': const Duration(minutes: 30)},
          {'title': 'إيقاف بعد 45 دقيقة', 'duration': const Duration(minutes: 45)},
          {'title': 'إيقاف بعد ساعة (60 دقيقة)', 'duration': const Duration(minutes: 60)},
          if (remaining.inSeconds > 5)
            {'title': 'إيقاف عند نهاية الأغنية الحالية', 'duration': remaining},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'مؤقت النوم (Sleep Timer)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (playerProvider.isSleepTimerActive)
                    TextButton(
                      onPressed: () {
                        playerProvider.setSleepTimer(null);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إلغاء مؤقت النوم'),
                            backgroundColor: AppColors.surfaceLight,
                          ),
                        );
                      },
                      child: const Text('إلغاء المؤقت', style: TextStyle(color: AppColors.gazelleRedBright)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final dur = opt['duration'] as Duration;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.timer_outlined, color: AppColors.gazelleRedGlow),
                  title: Text(opt['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    playerProvider.setSleepTimer(dur);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم ضبط مؤقت النوم: ${opt['title']}'),
                        backgroundColor: AppColors.gazelleRedDark,
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showLyricsSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.emotionalPlayerGradient,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.gazelleRedGlow,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  FutureBuilder<String?>(
                    future: context.read<MusicProvider>().getLyrics(song.title, song.artist),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.gazelleRedBright),
                          ),
                        );
                      }
                      final lyrics = snapshot.data;
                      if (lyrics != null && lyrics.trim().isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderHighlight),
                          ),
                          child: Text(
                            lyrics,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 2.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderHighlight),
                        ),
                        child: const Text(
                          '♪ استمع واستمتع بالمشاعر العميقة ♪\n\n'
                          'لم يتم العثور على كلمات مكتوبة لهذه الأغنية حتى الآن.\n\n'
                          'كل نغمة تحكي قصة،\n'
                          'وكل لحن يلامس الروح.\n'
                          'عيش اللحظة مع Muscia بأعلى جودة صوتية.',
                          style: TextStyle(
                            fontSize: 17,
                            height: 2.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final song = playerProvider.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('لا توجد أغنية قيد التشغيل')),
      );
    }

    if (playerProvider.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    final totalMs = playerProvider.duration.inMilliseconds;
    final currentMs = playerProvider.position.inMilliseconds;
    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    final screenHeight = MediaQuery.of(context).size.height;
    final artSize = (screenHeight * 0.30).clamp(180.0, 245.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic Atmospheric Blurred Artwork Background
          if (song.artworkUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
                  child: CachedNetworkImage(
                    imageUrl: song.artworkUrl,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(color: AppColors.gazelleRedDark),
                  ),
                ),
              ),
            ),

          // Deep Dark Gradient Tint Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gazelleRedDark.withValues(alpha: 0.45),
                    AppColors.background.withValues(alpha: 0.8),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        const Text(
                          'قيد التشغيل الآن',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.album,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            playerProvider.isSleepTimerActive ? Icons.bedtime : Icons.bedtime_outlined,
                            color: playerProvider.isSleepTimerActive ? AppColors.gazelleRedBright : Colors.white,
                          ),
                          tooltip: 'مؤقت النوم',
                          onPressed: () => _showSleepTimerSheet(context, playerProvider),
                        ),
                        IconButton(
                          icon: const Icon(Icons.queue_music, color: Colors.white),
                          tooltip: 'قائمة الانتظار',
                          onPressed: () => _showQueueSheet(context, playerProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Vinyl / Artwork with Swipe Gestures & pulsing Gazelle Red Glow
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -150) {
                      playerProvider.next();
                    } else if (details.primaryVelocity! > 150) {
                      playerProvider.previous();
                    }
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                    Navigator.pop(context);
                  }
                },
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient red glow behind artwork
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: artSize + 10,
                        height: artSize + 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: playerProvider.isPlaying
                                  ? AppColors.gazelleRedBright.withValues(alpha: 0.45)
                                  : AppColors.gazelleRedDark.withValues(alpha: 0.2),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),

                      // Artwork Card
                      Hero(
                        tag: 'album_art_${song.id}',
                        child: Container(
                          width: artSize,
                          height: artSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.borderHighlight,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 25,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: CachedNetworkImage(
                              imageUrl: song.artworkUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.gazelleRedBright,
                                  ),
                                ),
                              ),
                              errorWidget: (c, u, e) => Container(
                                color: AppColors.gazelleRedDark,
                                child: const Icon(
                                  Icons.music_note,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Waveform Visualizer (Emotional Musical Heartbeat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: WaveformVisualizer(
                  isPlaying: playerProvider.isPlaying,
                  barCount: 24,
                  maxHeight: 28,
                  color: AppColors.gazelleRedVibrant,
                ),
              ),

              const Spacer(),

              // Title, Artist, & Favorite Heart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 30,
                      icon: Icon(
                        playerProvider.isFavorite(song.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: playerProvider.isFavorite(song.id)
                            ? AppColors.gazelleRedGlow
                            : Colors.white70,
                      ),
                      onPressed: () => playerProvider.toggleFavorite(song),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress Scrubber Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Slider(
                      value: _isDraggingSlider
                          ? _dragValue
                          : progress.toDouble(),
                      onChanged: (val) {
                        setState(() {
                          _isDraggingSlider = true;
                          _dragValue = val;
                        });
                      },
                      onChangeEnd: (val) {
                        _isDraggingSlider = false;
                        final newPos = Duration(
                          milliseconds: (val * totalMs).round(),
                        );
                        playerProvider.seek(newPos);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerProvider.position),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            _formatDuration(playerProvider.duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Main Playback Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: playerProvider.isShuffle
                            ? AppColors.gazelleRedGlow
                            : Colors.white54,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleShuffle(),
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      onPressed: () => playerProvider.previous(),
                    ),

                    // Play / Pause Big Button
                    GestureDetector(
                      onTap: () => playerProvider.togglePlayPause(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gazelleRedBright.withValues(alpha: 0.5),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: playerProvider.isLoading
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  playerProvider.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      onPressed: () => playerProvider.next(),
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        playerProvider.repeatMode == MusciaRepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playerProvider.repeatMode != MusciaRepeatMode.off
                            ? AppColors.gazelleRedGlow
                            : Colors.white54,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleRepeat(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (playerProvider.status == PlayerStatus.error) ...[
                InkWell(
                  onTap: () => playerProvider.togglePlayPause(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gazelleRedDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gazelleRedBright, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'تعذر البث مؤقتاً، اضغط هنا للمحاولة مرة أخرى',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 8),

              // Bottom Actions: Queue & Lyrics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.queue_music, size: 20, color: AppColors.textSecondary),
                      label: const Text('قائمة الانتظار', style: TextStyle(color: AppColors.textSecondary)),
                      onPressed: () => _showQueueSheet(context, playerProvider),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.lyrics_outlined, size: 20, color: AppColors.gazelleRedGlow),
                      label: const Text('الكلمات', style: TextStyle(color: AppColors.gazelleRedGlow)),
                      onPressed: () => _showLyricsSheet(context, song),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}

