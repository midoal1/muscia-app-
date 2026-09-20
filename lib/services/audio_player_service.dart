import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';
import 'music_repository.dart';
import 'storage_service.dart';

enum PlayerStatus { idle, loading, playing, paused, error }
enum MusciaRepeatMode { off, all, one }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final MusicRepository _musicRepo;
  final StorageService _storageService;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;

  bool _isShuffle = false;
  MusciaRepeatMode _repeatMode = MusciaRepeatMode.off;

  final _statusController = StreamController<PlayerStatus>.broadcast();
  PlayerStatus _currentStatus = PlayerStatus.idle;

  AudioPlayerService(this._musicRepo, this._storageService) {
    _initListeners();
  }

  AudioPlayer get player => _player;
  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  MusciaRepeatMode get repeatMode => _repeatMode;
  PlayerStatus get status => _currentStatus;

  Stream<PlayerStatus> get statusStream => _statusController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  void _initListeners() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.loading) {
        _setStatus(PlayerStatus.loading);
      } else if (state.processingState == ProcessingState.buffering) {
        // Prevent flickering and UI jitter when buffering occurs during smooth playback
        if (!state.playing) {
          _setStatus(PlayerStatus.loading);
        }
      } else if (state.playing) {
        _setStatus(PlayerStatus.playing);
      } else if (state.processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      } else {
        _setStatus(PlayerStatus.paused);
      }
    });

    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      debugPrint('Audio Player Error: $e');
      _setStatus(PlayerStatus.error);
    });
  }

  void _setStatus(PlayerStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  // Play a single song or set queue
  Future<void> playSong(Song song, {List<Song>? contextQueue, int? initialIndex}) async {
    try {
      _setStatus(PlayerStatus.loading);
      _currentSong = song;

      if (contextQueue != null && contextQueue.isNotEmpty) {
        _queue = List.from(contextQueue);
        _currentIndex = initialIndex ?? _queue.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _queue.insert(0, song);
          _currentIndex = 0;
        }
      } else {
        if (!_queue.any((s) => s.id == song.id)) {
          _queue.add(song);
        }
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      // Add to storage history
      _storageService.addToHistory(song);

      // Fetch streaming candidates (Guaranteed 100% full songs)
      final candidates = await _musicRepo.getStreamCandidates(song);
      if (candidates.isEmpty) {
        debugPrint('No stream candidates found for ${song.title}');
        _setStatus(PlayerStatus.error);
        return;
      }

      bool playSuccess = false;

      for (final streamUrl in candidates) {
        try {
          debugPrint('Trying stream candidate: ${streamUrl.substring(0, streamUrl.length.clamp(0, 80))}...');
          _currentSong!.audioUrl = streamUrl;

          // Stop previous track before loading new source
          await _player.stop();

          // Prepare background MediaItem with browser headers to prevent 403 or throttling
          final audioSource = AudioSource.uri(
            Uri.parse(streamUrl),
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
              'Accept': '*/*',
            },
            tag: MediaItem(
              id: song.id,
              album: song.album,
              title: song.title,
              artist: song.artist,
              artUri: song.artworkUrl.isNotEmpty ? Uri.tryParse(song.artworkUrl) : null,
              duration: song.duration.inSeconds > 0 ? song.duration : null,
            ),
          );

          await _player.setAudioSource(audioSource, preload: true);
          await _player.play();
          playSuccess = true;
          debugPrint('Successfully playing: ${song.title}');
          break; // Audio started successfully!
        } catch (candidateError) {
          debugPrint('Candidate stream failed ($candidateError), trying next candidate...');
        }
      }

      if (!playSuccess) {
        _setStatus(PlayerStatus.error);
      }
    } catch (e) {
      debugPrint('Critical error playing song: $e');
      _setStatus(PlayerStatus.error);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_currentSong != null) {
        if (_currentStatus == PlayerStatus.error || _player.audioSource == null) {
          // Retry playing from scratch
          await playSong(_currentSong!);
        } else {
          await _player.play();
        }
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_isShuffle && _queue.length > 1) {
      final nextIdx = (_currentIndex + 1) % _queue.length;
      _currentIndex = nextIdx;
      await playSong(_queue[_currentIndex]);
      return;
    }

    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else if (_repeatMode == MusciaRepeatMode.all) {
      _currentIndex = 0;
      await playSong(_queue[0]);
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 4) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
  }

  void toggleRepeat() {
    if (_repeatMode == MusciaRepeatMode.off) {
      _repeatMode = MusciaRepeatMode.all;
      _player.setLoopMode(LoopMode.all);
    } else if (_repeatMode == MusciaRepeatMode.all) {
      _repeatMode = MusciaRepeatMode.one;
      _player.setLoopMode(LoopMode.one);
    } else {
      _repeatMode = MusciaRepeatMode.off;
      _player.setLoopMode(LoopMode.off);
    }
  }

  void _handleTrackCompleted() {
    if (_repeatMode == MusciaRepeatMode.one) {
      seek(Duration.zero);
      _player.play();
    } else {
      skipToNext();
    }
  }

  void dispose() {
    _statusController.close();
    _player.dispose();
  }
}
