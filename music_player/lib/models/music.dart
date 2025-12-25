import 'package:equatable/equatable.dart';

class Music extends Equatable {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String path;
  final int duration;
  final String fileName;
  final String folder;

  const Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.path,
    required this.duration,
    required this.fileName,
    required this.folder,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      genre: json['genre'] as String,
      path: json['path'] as String,
      duration: json['duration'] as int,
      fileName: json['file_name'] as String,
      folder: json['folder'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'path': path,
      'duration': duration,
      'file_name': fileName,
      'folder': folder,
    };
  }

  @override
  List<Object?> get props {
    return [
      id,
      title,
      artist,
      album,
      genre,
      path,
      duration,
      fileName,
      folder,
    ];
  }
}
