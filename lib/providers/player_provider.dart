import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final StorageService _storageService;

  StreamSubscription? _statusSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerStatus _status = PlayerStatus.idle;

  PlayerProvider(this._audioService, this._storageService) {
    _status = _audioService.status;
    _statusSub = _audioService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _posSub = _audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  Song? get currentSong => _audioService.currentSong;
  List<Song> get queue => _audioService.queue;
  int get currentIndex => _audioService.currentIndex;
  Duration get position => _position;
  Duration get duration => _duration;
  PlayerStatus get status => _status;
  bool get isPlaying => _status == PlayerStatus.playing;
  bool get isLoading => _status == PlayerStatus.loading;
  bool get isShuffle => _audioService.isShuffle;
  MusciaRepeatMode get repeatMode => _audioService.repeatMode;

  bool isFavorite(String songId) {
    return _storageService.isFavorite(songId);
  }

  Future<void> playSong(Song song, {List<Song>? contextQueue, int? initialIndex}) async {
    await _audioService.playSong(song, contextQueue: contextQueue, initialIndex: initialIndex);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    await _audioService.seek(position);
  }

  Future<void> next() async {
    await _audioService.skipToNext();
    notifyListeners();
  }

  Future<void> previous() async {
    await _audioService.skipToPrevious();
    notifyListeners();
  }

  void toggleShuffle() {
    _audioService.toggleShuffle();
    notifyListeners();
  }

  void toggleRepeat() {
    _audioService.toggleRepeat();
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    await _storageService.toggleFavorite(song);
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    super.dispose();
  }
}
