import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class MusicRepository {
  final YoutubeExplode _yt = YoutubeExplode();

  // Cache for resolved stream URLs to avoid re-fetching
  final Map<String, String> _streamCache = {};

  // Global search for any song or artist (Parallel Audius API + YouTube)
  Future<List<Song>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final futures = await Future.wait([
        searchAudius(cleanQuery),
        _searchYoutube(cleanQuery),
      ]);

      final audiusTracks = futures[0];
      final youtubeTracks = futures[1];

      final Map<String, Song> uniqueSongs = {};

      // Prioritize Audius tracks (instant streaming audio URL pre-attached)
      for (final s in audiusTracks) {
        final key = '${s.title.toLowerCase()}_${s.artist.toLowerCase()}';
        uniqueSongs[key] = s;
      }

      // Add YouTube tracks
      for (final s in youtubeTracks) {
        final key = '${s.title.toLowerCase()}_${s.artist.toLowerCase()}';
        if (!uniqueSongs.containsKey(key)) {
          uniqueSongs[key] = s;
        }
      }

      if (uniqueSongs.isNotEmpty) {
        return uniqueSongs.values.toList();
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    // Fallback search via iTunes API for instant resilience
    return _searchItunesFallback(cleanQuery);
  }

  // Dedicated Music API (Audius Music Protocol - Unblocked, 100% full songs)
  Future<List<Song>> searchAudius(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://discoveryprovider.audius.co/v1/tracks/search?query=${Uri.encodeComponent(cleanQuery)}&app_name=muscia',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final trackList = (data['data'] as List<dynamic>?) ?? [];
        final List<Song> songs = [];
        for (final item in trackList) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final title = item['title'] as String? ?? 'Song';
          final user = item['user'] as Map<String, dynamic>?;
          final artist = user != null ? (user['name'] as String? ?? 'Artist') : 'Artist';
          final durationSec = (item['duration'] as num?)?.toInt() ?? 180;
          if (durationSec > 1800) continue; // Skip DJ mixes over 30 mins
          final artworkMap = item['artwork'] as Map<String, dynamic>?;
          final artwork = artworkMap != null
              ? (artworkMap['480x480'] ?? artworkMap['150x150'] ?? '') as String
              : '';
          final streamUrl = 'https://discoveryprovider.audius.co/v1/tracks/$id/stream?app_name=muscia';

          songs.add(
            Song(
              id: 'audius_$id',
              title: _cleanTitle(title),
              artist: artist,
              album: 'Audius Stream',
              duration: Duration(seconds: durationSec),
              artworkUrl: artwork.isNotEmpty
                  ? artwork
                  : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
              audioUrl: streamUrl,
            ),
          );
        }
        return songs;
      }
    } catch (e) {
      debugPrint('Audius search error: $e');
    }
    return [];
  }

  // YouTube Search Helper
  Future<List<Song>> _searchYoutube(String query) async {
    try {
      final searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 5));
      final List<Song> songs = [];

      for (final video in searchResults.take(20)) {
        final duration = video.duration ?? Duration.zero;
        if (duration.inMinutes > 20) continue;

        songs.add(
          Song(
            id: video.id.value,
            title: _cleanTitle(video.title),
            artist: video.author,
            album: 'Single',
            duration: duration,
            artworkUrl: video.thumbnails.highResUrl.isNotEmpty
                ? video.thumbnails.highResUrl
                : video.thumbnails.standardResUrl,
          ),
        );
      }
      return songs;
    } catch (_) {
      return [];
    }
  }

  // Fallback search using iTunes open search API
  Future<List<Song>> _searchItunesFallback(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=25',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        return results.map((item) {
          final trackName = item['trackName'] as String? ?? 'Song';
          final artistName = item['artistName'] as String? ?? 'Artist';
          final artwork = (item['artworkUrl100'] as String? ?? '')
              .replaceAll('100x100bb', '600x600bb');
          final durationMs = item['trackTimeMillis'] as int? ?? 180000;

          return Song(
            id: 'itunes_${item['trackId']}',
            title: trackName,
            artist: artistName,
            album: item['collectionName'] as String? ?? 'Album',
            duration: Duration(milliseconds: durationMs),
            artworkUrl: artwork,
            audioUrl: null, // Always resolve full YouTube audio track on play
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // Resolves direct playable audio stream URL for a given song with multi-layer fallback
  Future<String?> getAudioStreamUrl(Song song) async {
    final candidates = await getStreamCandidates(song);
    return candidates.isNotEmpty ? candidates.first : null;
  }

  // Get a list of candidate playable FULL stream URLs (Never previews)
  Future<List<String>> getStreamCandidates(Song song) async {
    final List<String> candidates = [];

    // 1. Direct pre-attached audio stream (e.g. from Audius API)
    if (song.audioUrl != null &&
        song.audioUrl!.isNotEmpty &&
        !song.audioUrl!.toLowerCase().contains('preview') &&
        !song.audioUrl!.toLowerCase().contains('audiopreview')) {
      candidates.add(song.audioUrl!);
      candidates.add('https://muscia-backend.onrender.com/api/proxy?url=${Uri.encodeComponent(song.audioUrl!)}');
    }

    // 2. Direct Audius track ID stream
    if (song.id.startsWith('audius_')) {
      final cleanId = song.id.replaceFirst('audius_', '');
      final audiusUrl = 'https://discoveryprovider.audius.co/v1/tracks/$cleanId/stream?app_name=muscia';
      if (!candidates.contains(audiusUrl)) {
        candidates.insert(0, audiusUrl);
      }
      return candidates;
    }

    // 3. Cached full stream URL
    if (_streamCache.containsKey(song.id)) {
      final cached = _streamCache[song.id]!;
      if (!candidates.contains(cached)) {
        candidates.add(cached);
        candidates.add('https://muscia-backend.onrender.com/api/proxy?url=${Uri.encodeComponent(cached)}');
      }
      return candidates;
    }

    // 4. Direct YouTube manifest if it is a valid 11-character YouTube video ID
    if (!song.id.startsWith('itunes_') && !song.id.startsWith('starter_') && !song.id.startsWith('audius_') && song.id.length == 11) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(song.id).timeout(const Duration(seconds: 5));
        final streams = _extractAllAudioStreams(manifest);
        if (streams.isNotEmpty) {
          _streamCache[song.id] = streams.first;
          candidates.addAll(streams);
          // Add Render audio proxy as fail-safe
          candidates.add('https://muscia-backend.onrender.com/api/proxy?url=${Uri.encodeComponent(streams.first)}');
          return candidates;
        }
      } catch (e) {
        debugPrint('Direct manifest fetch failed for ${song.id}: $e');
      }
    }

    // 5. Audius track search by Title + Artist (Instant high-speed fail-safe)
    try {
      final cleanTitle = _cleanTitle(song.title);
      final audiusResults = await searchAudius('$cleanTitle ${song.artist}');
      if (audiusResults.isNotEmpty && audiusResults.first.audioUrl != null) {
        final audiusStream = audiusResults.first.audioUrl!;
        if (!candidates.contains(audiusStream)) {
          candidates.add(audiusStream);
        }
      }
    } catch (_) {}

    // 6. YouTube search for full track
    try {
      final cleanTitle = _cleanTitle(song.title);
      final query = '$cleanTitle ${song.artist} audio';
      final searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 5));
      for (final video in searchResults.take(3)) {
        final duration = video.duration ?? Duration.zero;
        if (duration.inMinutes > 20) continue;
        try {
          final manifest = await _yt.videos.streamsClient.getManifest(video.id).timeout(const Duration(seconds: 5));
          final streams = _extractAllAudioStreams(manifest);
          if (streams.isNotEmpty) {
            _streamCache[song.id] = streams.first;
            candidates.addAll(streams);
            candidates.add('https://muscia-backend.onrender.com/api/proxy?url=${Uri.encodeComponent(streams.first)}');
            return candidates;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Search manifest fetch failed for ${song.title}: $e');
    }

    return candidates;
  }

  // Fetch real-time synchronized lyrics via Render backend
  Future<String?> getLyrics(String title, String artist) async {
    try {
      final cleanTitle = _cleanTitle(title);
      final url = Uri.parse(
        'https://muscia-backend.onrender.com/api/lyrics?title=${Uri.encodeComponent(cleanTitle)}&artist=${Uri.encodeComponent(artist)}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['lyrics'] != null) {
          final rawLyrics = data['lyrics'] as String;
          // Clean timestamps like [00:13.13] for readable display
          return rawLyrics.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'), '').trim();
        }
      }
    } catch (_) {}
    return null;
  }

  // Extract all high-quality audio streams (prioritizing Android MP4/AAC and Opus)
  List<String> _extractAllAudioStreams(StreamManifest manifest) {
    final List<String> urls = [];
    try {
      final audioStreams = manifest.audioOnly.toList();
      if (audioStreams.isEmpty) return urls;

      // 1. Android-native MP4 (AAC) - Best compatibility and instant seek
      final mp4Streams = audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
      if (mp4Streams.isNotEmpty) {
        mp4Streams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        urls.add(mp4Streams.first.url.toString());
      }

      // 2. High-fidelity WebM (Opus)
      final webmStreams = audioStreams.where((s) => s.container.name.toLowerCase() == 'webm').toList();
      if (webmStreams.isNotEmpty) {
        webmStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        final webmUrl = webmStreams.first.url.toString();
        if (!urls.contains(webmUrl)) {
          urls.add(webmUrl);
        }
      }

      // 3. Any remaining highest bitrate stream
      final highest = audioStreams.withHighestBitrate().url.toString();
      if (!urls.contains(highest)) {
        urls.add(highest);
      }
    } catch (_) {}
    return urls;
  }

  // Get trending tracks worldwide and arabic
  Future<List<Song>> getTrendingTracks() async {
    final queries = ['Arabic top hits 2025 اغاني جديدة', 'Global Top 50 hits'];
    final List<Song> results = [];

    for (final q in queries) {
      try {
        final search = await _yt.search.search(q);
        for (final v in search.take(10)) {
          if ((v.duration ?? Duration.zero).inMinutes > 15) continue;
          results.add(
            Song(
              id: v.id.value,
              title: _cleanTitle(v.title),
              artist: v.author,
              album: 'Trending',
              duration: v.duration ?? const Duration(minutes: 3, seconds: 30),
              artworkUrl: v.thumbnails.highResUrl.isNotEmpty
                  ? v.thumbnails.highResUrl
                  : v.thumbnails.standardResUrl,
            ),
          );
        }
      } catch (_) {}
    }

    if (results.isEmpty) {
      return _getDefaultStarterTracks();
    }
    return results;
  }

  // Curated Featured Playlists
  List<Playlist> getFeaturedPlaylists() {
    return [
      Playlist(
        id: 'arabic_tarab',
        title: 'طرب وأصالة',
        description: 'أجمل روائع الطرب العربي الخالد ومشاعر الفن الأصيل',
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
        songs: [],
      ),
      Playlist(
        id: 'deep_chill',
        title: 'روقان وهدوء',
        description: 'موسيقى هادئة للأوقات الدافئة والتركيز والاسترخاء',
        coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&q=80',
        songs: [],
      ),
      Playlist(
        id: 'red_energy',
        title: 'طاقة ونشاط (Red Energy)',
        description: 'إيقاعات قوية وحماسية للتمارين والسفر',
        coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
        songs: [],
      ),
      Playlist(
        id: 'emotional_vibes',
        title: 'شجن وعاطفة (Emotional)',
        description: 'أغاني تلامس القلب والروح بأحاسيس عميقة',
        coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
        songs: [],
      ),
    ];
  }

  // Top Global & Arabic Artists
  List<Artist> getTopArtists() {
    return [
      Artist(
        id: 'amr_diab',
        name: 'عمرو دياب',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebc1dbcb5fe7d848773c3eeff8',
        monthlyListeners: '4.8M مستمع شهرياً',
        bio: 'الهضبة وسفير الموسيقى العربية المعاصرة',
      ),
      Artist(
        id: 'the_weeknd',
        name: 'The Weeknd',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb214f3cf1cbe7139c1e26ffbb',
        monthlyListeners: '105M Monthly Listeners',
        bio: 'Global superstar known for cinematic R&B & synth-pop vibes',
      ),
      Artist(
        id: 'sherine',
        name: 'شيرين عبدالوهاب',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb22be589c3686259461f8551a',
        monthlyListeners: '3.6M مستمع شهرياً',
        bio: 'صوت المشاعر والإحساس العربي العالي',
      ),
      Artist(
        id: 'billie_eilish',
        name: 'Billie Eilish',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebd8b9980db67ba10147a11004',
        monthlyListeners: '98M Monthly Listeners',
        bio: 'Atmospheric, emotive, and Grammy-winning musical sensation',
      ),
      Artist(
        id: 'wegz',
        name: 'ويجز (Wegz)',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb817bfb4fdf30cb8ea2594a97',
        monthlyListeners: '3.2M مستمع شهرياً',
        bio: 'أيقونة التراب والموسيقى المعاصرة في العالم العربي',
      ),
      Artist(
        id: 'adele',
        name: 'Adele',
        imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb68f6e5892075d7f22615bd17',
        monthlyListeners: '55M Monthly Listeners',
        bio: 'Timeless powerhouse vocal artist',
      ),
    ];
  }

  // Clean video titles from unwanted tags like (Official Video), [4K], etc.
  String _cleanTitle(String rawTitle) {
    var title = rawTitle;
    final regexes = [
      RegExp(r'\((Official\s*Music\s*Video|Official\s*Audio|Official\s*Video|Video\s*Clip|Lyric\s*Video|فيديو\s*كليب|الكليب\s*الرسمي)\)', caseSensitive: false),
      RegExp(r'\[(Official\s*Music\s*Video|Official\s*Audio|Official\s*Video|Video\s*Clip|Lyric\s*Video|فيديو\s*كليب|الكليب\s*الرسمي)\]', caseSensitive: false),
      RegExp(r'\(HD|\b4K\b|HQ\)', caseSensitive: false),
      RegExp(r'\[HD|\b4K\b|HQ\]', caseSensitive: false),
    ];
    for (final reg in regexes) {
      title = title.replaceAll(reg, '');
    }
    return title.trim();
  }

  List<Song> _getDefaultStarterTracks() {
    return [
      Song(
        id: 'u_G1NCwQZ4E',
        title: 'مكانك (Makank)',
        artist: 'عمرو دياب',
        album: 'مكانك',
        duration: const Duration(minutes: 3, seconds: 24),
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
      ),
      Song(
        id: '4NRXx6U8ABQ',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        duration: const Duration(minutes: 3, seconds: 20),
        artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
      ),
      Song(
        id: 'kXYiU_JCYtU',
        title: 'البخت (El Bakht)',
        artist: 'ويجز (Wegz)',
        album: 'Single',
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
      ),
      Song(
        id: '34Na4j8AVgA',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: const Duration(minutes: 3, seconds: 50),
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
      ),
    ];
  }

  void dispose() {
    _yt.close();
  }
}
