import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';
import '../services/music_repository.dart';
import '../services/storage_service.dart';

class MusicProvider extends ChangeNotifier {
  final MusicRepository _musicRepo;
  final StorageService _storageService;

  List<Song> _trendingSongs = [];
  List<Playlist> _featuredPlaylists = [];
  List<Artist> _topArtists = [];
  List<Song> _searchResults = [];
  List<Song> _favorites = [];
  List<Song> _history = [];

  bool _isLoadingTrending = false;
  bool _isSearching = false;
  String _currentQuery = '';

  final Map<String, List<Song>> _searchCache = {};
  String _userName = 'أحمد';
  String _userAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80';

  MusicProvider(this._musicRepo, this._storageService) {
    _userName = _storageService.getUserName();
    _userAvatar = _storageService.getUserAvatar();
    _initData();
  }

  List<Song> get trendingSongs => _trendingSongs;
  List<Playlist> get featuredPlaylists => _featuredPlaylists;
  List<Artist> get topArtists => _topArtists;
  List<Song> get searchResults => _searchResults;
  List<Song> get favorites => _favorites;
  List<Song> get history => _history;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  String get userName => _userName;
  String get userAvatar => _userAvatar;

  Future<void> updateProfile({required String name, required String avatarUrl}) async {
    _userName = name;
    _userAvatar = avatarUrl;
    await _storageService.setUserName(name);
    await _storageService.setUserAvatar(avatarUrl);
    notifyListeners();
  }

  Future<String?> getLyrics(String title, String artist) => _musicRepo.getLyrics(title, artist);

  Future<void> _initData() async {
    _featuredPlaylists = _musicRepo.getFeaturedPlaylists();
    _topArtists = _musicRepo.getTopArtists();
    refreshLibrary();
    await loadTrending();
  }

  void refreshLibrary() {
    _favorites = _storageService.getFavorites();
    _history = _storageService.getHistory();
    notifyListeners();
  }

  Future<void> loadTrending() async {
    _isLoadingTrending = true;
    notifyListeners();

    try {
      _trendingSongs = await _musicRepo.getTrendingTracks();
    } catch (e) {
      debugPrint('Error loading trending: $e');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    _currentQuery = clean;
    if (clean.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Instant return from cache (0ms delay!)
    if (_searchCache.containsKey(clean)) {
      _searchResults = _searchCache[clean]!;
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _musicRepo.search(clean);
      if (_currentQuery == clean) {
        _searchCache[clean] = results;
        _searchResults = results;
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (_currentQuery == clean) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
