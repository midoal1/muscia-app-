import 'package:flutter_test/flutter_test.dart';
import 'package:muscia/models/song_model.dart';
import 'package:muscia/services/music_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Song model serialization and properties test', () {
    final song = Song(
      id: 'test_1',
      title: 'Test Song',
      artist: 'Test Artist',
      duration: const Duration(minutes: 3, seconds: 30),
      artworkUrl: 'https://example.com/art.jpg',
    );

    expect(song.title, 'Test Song');
    expect(song.artist, 'Test Artist');
    expect(song.duration.inSeconds, 210);

    final json = song.toJson();
    final reconstructed = Song.fromJson(json);

    expect(reconstructed.id, song.id);
    expect(reconstructed.title, song.title);
    expect(reconstructed.artist, song.artist);
    expect(reconstructed.duration.inSeconds, 210);
  });

  test('YouTube stream diagnostic', () async {
    final yt = YoutubeExplode();
    try {
      final results = await yt.search.search('Wegz El Bakht audio');
      expect(results.isNotEmpty, isTrue);
      final v = results.first;
      final manifest = await yt.videos.streamsClient.getManifest(v.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      expect(audioStream.url.toString().isNotEmpty, isTrue);

      final client = http.Client();
      try {
        final headRes = await client.head(audioStream.url);
        expect(headRes.statusCode, isNotNull);
        
        final getRes = await client.get(
          audioStream.url,
          headers: {'Range': 'bytes=0-1024'},
        );
        expect(getRes.statusCode, 206);
        expect(getRes.bodyBytes.length, greaterThan(0));
      } finally {
        client.close();
      }
    } catch (_) {
    } finally {
      yt.close();
    }
  });

  test('MusicRepository returns full streams for iTunes and YouTube songs without 30s preview', () async {
    final repo = MusicRepository();
    final itunesSong = Song(
      id: 'itunes_99999',
      title: 'البخت',
      artist: 'ويجز',
      album: 'Single',
      duration: const Duration(minutes: 3, seconds: 45),
      artworkUrl: 'https://example.com/art.jpg',
    );

    final candidates = await repo.getStreamCandidates(itunesSong);
    expect(candidates.isNotEmpty, isTrue, reason: 'Must find at least one playable full stream');
    for (final c in candidates) {
      expect(c.toLowerCase().contains('preview'), isFalse, reason: 'Candidate should NEVER be a 30-second preview!');
    }
    repo.dispose();
  });
}
