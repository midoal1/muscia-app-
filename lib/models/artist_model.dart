import 'song_model.dart';

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String monthlyListeners;
  final String bio;
  final List<Song> topSongs;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.monthlyListeners = '',
    this.bio = '',
    this.topSongs = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'monthlyListeners': monthlyListeners,
      'bio': bio,
      'topSongs': topSongs.map((s) => s.toJson()).toList(),
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'فنان',
      imageUrl: json['imageUrl'] as String? ?? '',
      monthlyListeners: json['monthlyListeners'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      topSongs: (json['topSongs'] as List<dynamic>?)
              ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
