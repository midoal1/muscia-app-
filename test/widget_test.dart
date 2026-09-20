import 'package:flutter_test/flutter_test.dart';
import 'package:muscia/models/song_model.dart';

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
}
