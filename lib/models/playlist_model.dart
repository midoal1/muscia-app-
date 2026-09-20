import 'song_model.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Song> songs;
  final bool isCustom;

  Playlist({
    required this.id,
    required this.title,
    this.description = '',
    required this.coverUrl,
    this.songs = const [],
    this.isCustom = false,
  });

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<Song>? songs,
    bool? isCustom,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'songs': songs.map((s) => s.toJson()).toList(),
      'isCustom': isCustom,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'قائمة تشغيل',
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      songs: (json['songs'] as List<dynamic>?)
              ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
