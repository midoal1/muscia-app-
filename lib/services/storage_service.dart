import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class StorageService {
  static const String _favoritesKey = 'muscia_favorites';
  static const String _historyKey = 'muscia_history';
  static const String _customPlaylistsKey = 'muscia_custom_playlists';
  static const String _userNameKey = 'muscia_user_name';
  static const String _userAvatarKey = 'muscia_user_avatar';
  static const String _audioQualityKey = 'muscia_audio_quality';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // User Profile
  String getUserName() {
    return _prefs.getString(_userNameKey) ?? 'أحمد';
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  String getUserAvatar() {
    return _prefs.getString(_userAvatarKey) ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80';
  }

  Future<void> setUserAvatar(String avatarUrl) async {
    await _prefs.setString(_userAvatarKey, avatarUrl);
  }

  // Audio Quality
  String getAudioQuality() {
    return _prefs.getString(_audioQualityKey) ?? 'Ultra HD (320kbps)';
  }

  Future<void> setAudioQuality(String quality) async {
    await _prefs.setString(_audioQualityKey, quality);
  }

  // Favorites
  List<Song> getFavorites() {
    final raw = _prefs.getStringList(_favoritesKey) ?? [];
    return raw.map((item) {
      try {
        return Song.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Song>().toList();
  }

  Future<void> toggleFavorite(Song song) async {
    final favorites = getFavorites();
    final index = favorites.indexWhere((s) => s.id == song.id);

    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.insert(0, song.copyWith(isFavorite: true));
    }

    final raw = favorites.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_favoritesKey, raw);
  }

  bool isFavorite(String songId) {
    final favorites = getFavorites();
    return favorites.any((s) => s.id == songId);
  }

  // Playback History
  List<Song> getHistory() {
    final raw = _prefs.getStringList(_historyKey) ?? [];
    return raw.map((item) {
      try {
        return Song.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Song>().toList();
  }

  Future<void> addToHistory(Song song) async {
    final history = getHistory();
    history.removeWhere((s) => s.id == song.id);
    history.insert(0, song);
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    final raw = history.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_historyKey, raw);
  }

  // Custom Playlists
  List<Playlist> getCustomPlaylists() {
    final raw = _prefs.getStringList(_customPlaylistsKey) ?? [];
    return raw.map((item) {
      try {
        return Playlist.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Playlist>().toList();
  }

  Future<void> saveCustomPlaylist(Playlist playlist) async {
    final playlists = getCustomPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      playlists[index] = playlist;
    } else {
      playlists.insert(0, playlist);
    }
    final raw = playlists.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_customPlaylistsKey, raw);
  }

  Future<void> deleteCustomPlaylist(String id) async {
    final playlists = getCustomPlaylists();
    playlists.removeWhere((p) => p.id == id);
    final raw = playlists.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_customPlaylistsKey, raw);
  }
}
