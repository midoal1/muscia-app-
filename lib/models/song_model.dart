class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String artworkUrl;
  String? audioUrl;
  bool isFavorite;
  final String? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Single',
    required this.duration,
    required this.artworkUrl,
    this.audioUrl,
    this.isFavorite = false,
    this.lyrics,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkUrl,
    String? audioUrl,
    bool? isFavorite,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'artworkUrl': artworkUrl,
      'audioUrl': audioUrl,
      'isFavorite': isFavorite,
      'lyrics': lyrics,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'عنوان غير معروف',
      artist: json['artist'] as String? ?? 'فنان غير معروف',
      album: json['album'] as String? ?? 'ألبوم',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      artworkUrl: json['artworkUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lyrics: json['lyrics'] as String?,
    );
  }
}
