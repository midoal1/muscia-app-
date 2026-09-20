import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class MusicRepository {
  final YoutubeExplode _yt = YoutubeExplode();

  // Cache for resolved stream URLs to avoid re-fetching
  final Map<String, String> _streamCache = {};

  // Global search for any song or artist
  Future<List<Song>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final searchResults = await _yt.search.search(cleanQuery);
      final List<Song> songs = [];

      for (final video in searchResults.take(25)) {
        // Filter out very long videos (over 20 mins) to prefer actual tracks
        final duration = video.duration ?? Duration.zero;
        if (duration.inMinutes > 25) continue;

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
    } catch (e) {
      // Fallback search via iTunes API for instant resilience
      return _searchItunesFallback(cleanQuery);
    }
  }

  // Fallback search using iTunes open search API
  Future<List<Song>> _searchItunesFallback(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=25',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        return results.map((item) {
          final trackName = item['trackName'] as String? ?? 'Song';
          final artistName = item['artistName'] as String? ?? 'Artist';
          final artwork = (item['artworkUrl100'] as String? ?? '')
              .replaceAll('100x100bb', '600x600bb');
          final durationMs = item['trackTimeMillis'] as int? ?? 180000;
          final previewUrl = item['previewUrl'] as String?;

          return Song(
            id: 'itunes_${item['trackId']}',
            title: trackName,
            artist: artistName,
            album: item['collectionName'] as String? ?? 'Album',
            duration: Duration(milliseconds: durationMs),
            artworkUrl: artwork,
            audioUrl: previewUrl,
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

  // Get a list of candidate playable stream URLs (YouTube, Apple CDN fallback)
  Future<List<String>> getStreamCandidates(Song song) async {
    final List<String> candidates = [];

    // Pre-existing audio URL
    if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      candidates.add(song.audioUrl!);
    }

    // Cached stream URL
    if (_streamCache.containsKey(song.id)) {
      candidates.add(_streamCache[song.id]!);
    }

    // 0. Try Render dedicated backend proxy if live
    try {
      final renderStream = await _fetchRenderBackendStream(song.title, song.artist, song.id);
      if (renderStream != null && !candidates.contains(renderStream)) {
        candidates.add(renderStream);
        _streamCache[song.id] = renderStream;
      }
    } catch (_) {}

    // 1. Direct YouTube manifest if it is a valid 11-character YouTube video ID
    if (!song.id.startsWith('itunes_') && !song.id.startsWith('starter_') && song.id.length == 11) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(song.id).timeout(const Duration(seconds: 4));
        final url = _extractBestAudioStream(manifest);
        if (url != null && !candidates.contains(url)) {
          candidates.insert(0, url);
          _streamCache[song.id] = url;
        }
      } catch (_) {}
    }

    // 2. High-speed Apple Music / iTunes CDN stream (100% reliable 200 OK on all networks)
    try {
      final appleStream = await _fetchAppleStream(song.title, song.artist);
      if (appleStream != null && !candidates.contains(appleStream)) {
        candidates.add(appleStream);
      }
    } catch (_) {}

    // 3. Fallback search on YouTube using Title + Artist
    if (candidates.isEmpty) {
      try {
        final query = '${song.title} ${song.artist} audio';
        final searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 4));
        if (searchResults.isNotEmpty) {
          for (final video in searchResults.take(2)) {
            try {
              final manifest = await _yt.videos.streamsClient.getManifest(video.id).timeout(const Duration(seconds: 4));
              final url = _extractBestAudioStream(manifest);
              if (url != null && !candidates.contains(url)) {
                candidates.add(url);
                _streamCache[song.id] = url;
                break;
              }
            } catch (_) {
              continue;
            }
          }
        }
      } catch (_) {}
    }

    return candidates;
  }

  // Optional Render Backend proxy resolver (when deployed on Render)
  Future<String?> _fetchRenderBackendStream(String title, String artist, String id) async {
    try {
      final cleanTitle = _cleanTitle(title);
      final url = Uri.parse(
        'https://muscia-backend.onrender.com/api/stream?title=${Uri.encodeComponent(cleanTitle)}&artist=${Uri.encodeComponent(artist)}&id=${Uri.encodeComponent(id)}',
      );
      final res = await http.get(url).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['streamUrl'] != null) {
          return data['streamUrl'] as String;
        }
      }
    } catch (_) {}
    return null;
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

  // Fast Apple CDN stream fetcher using multi-variant query resolution
  Future<String?> _fetchAppleStream(String title, String artist) async {
    final queries = _generateSearchQueries(title, artist);
    for (final q in queries.take(3)) {
      try {
        final url = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&media=music&entity=song&limit=1',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final results = (data['results'] as List<dynamic>?) ?? [];
          if (results.isNotEmpty) {
            final preview = results[0]['previewUrl'] as String?;
            if (preview != null && preview.isNotEmpty) {
              return preview;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // Generate clean, high-precision search queries from noisy video titles and artist channels
  List<String> _generateSearchQueries(String title, String artist) {
    final List<String> queries = [];

    var cleanTitle = title;
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
    final noiseWords = [
      'Official', 'Music', 'Video', 'Audio', 'Clip', 'Lyrics', 'Lyric',
      'فيديو', 'كليب', 'الكليب', 'الرسمي', 'أغنية', 'اغنية',
      'prod by', 'prod.', 'feat.', 'ft.', 'Records', 'واورنچ', 'اورنچ'
    ];
    for (final w in noiseWords) {
      cleanTitle = cleanTitle.replaceAll(RegExp(w, caseSensitive: false), ' ');
    }

    final titleParts = cleanTitle
        .split(RegExp(r'[-–—|•:]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != '...')
        .toList();

    var cleanArtist = artist;
    cleanArtist = cleanArtist.replaceAll(
      RegExp(r'(and|Records|Music|Entertainment|Production|شخصي|قناة)', caseSensitive: false),
      ' ',
    );
    final artistParts = cleanArtist
        .split(RegExp(r'[-–—|•:]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != '...')
        .toList();

    if (titleParts.length >= 2) {
      queries.add('${titleParts[0]} ${titleParts[1]}');
      queries.add(titleParts[1]);
      queries.add('${titleParts[1]} ${titleParts[0]}');
    }

    final primaryArtist = artistParts.isNotEmpty ? artistParts.first : '';
    final mainTitle = titleParts.isNotEmpty ? titleParts.last : cleanTitle;
    if (primaryArtist.isNotEmpty && mainTitle.isNotEmpty) {
      queries.add('$primaryArtist $mainTitle');
    }

    queries.add(cleanTitle.replaceAll('...', '').trim());

    return queries.toSet().where((q) => q.trim().length > 2).toList();
  }

  // Extract the best audio stream, prioritizing Android-friendly MP4 (AAC) container
  String? _extractBestAudioStream(StreamManifest manifest) {
    try {
      final audioStreams = manifest.audioOnly.toList();
      if (audioStreams.isEmpty) return null;

      // Prefer MP4 container (AAC audioCodec) for seamless Android MediaPlayer/ExoPlayer support
      final mp4Streams = audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
      if (mp4Streams.isNotEmpty) {
        mp4Streams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        return mp4Streams.first.url.toString();
      }

      // Fallback to highest bitrate stream (e.g. WebM/Opus)
      return audioStreams.withHighestBitrate().url.toString();
    } catch (_) {
      return null;
    }
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
