import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/providers/music_provider.dart';
import 'package:music_player/models/music.dart';
import 'package:path/path.dart' as path;

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final TextEditingController playlistNameController =
        TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('创建播放列表'),
                  content: TextField(
                    controller: playlistNameController,
                    decoration: const InputDecoration(hintText: '输入播放列表名称'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (playlistNameController.text.isNotEmpty) {
                          provider.createPlaylist(playlistNameController.text);
                          playlistNameController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('创建'),
                    ),
                  ],
                ),
              );
            },
            tooltip: '创建播放列表',
          ),
        ],
      ),
      body: provider.playlists.isEmpty
          ? const Center(child: Text('暂无播放列表，点击右上角创建'))
          : ListView.builder(
              itemCount: provider.playlists.length,
              itemBuilder: (context, index) {
                final playlistName = provider.playlists[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(playlistName),
                    subtitle: Text(
                      '${provider.playlistSongs[playlistName]?.length ?? 0} 首歌曲',
                    ),
                    leading: const Icon(Icons.playlist_play),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          // 重命名播放列表
                          final TextEditingController renameController =
                              TextEditingController(text: playlistName);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('重命名播放列表'),
                              content: TextField(
                                controller: renameController,
                                decoration: const InputDecoration(
                                  hintText: '输入新名称',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (renameController.text.isNotEmpty) {
                                      provider.renamePlaylist(
                                        playlistName,
                                        renameController.text,
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('重命名'),
                                ),
                              ],
                            ),
                          );
                        } else if (value == 'delete') {
                          // 删除播放列表
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('删除播放列表'),
                              content: Text('确定要删除播放列表 "$playlistName" 吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.deletePlaylist(playlistName);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('重命名'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                    onTap: () {
                      // 进入播放列表详情
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            PlaylistDetailScreen(playlistName: playlistName),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// 播放列表详情屏幕
class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final playlistSongs = provider.playlistSongs[playlistName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: playlistSongs.isEmpty
          ? const Center(child: Text('播放列表为空'))
          : ListView.builder(
              itemCount: playlistSongs.length,
              itemBuilder: (context, index) {
                final songPath = playlistSongs[index];
                // 查找对应的音乐文件
                final song = provider.musicFiles.firstWhere(
                  (music) => music.path == songPath,
                  orElse: () => Music(
                    id: index,
                    title: path.basename(songPath),
                    artist: '未知歌手',
                    album: '未知专辑',
                    genre: '未知曲风',
                    path: songPath,
                    duration: 0,
                    fileName: path.basename(songPath),
                    folder: path.dirname(songPath),
                  ),
                );

                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  leading: const Icon(Icons.music_note),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.removeSongFromPlaylist(
                      playlistName,
                      song.path,
                    ),
                  ),
                  onTap: () => provider.playMusic(song),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加歌曲到播放列表
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                AddToPlaylistScreen(playlistName: playlistName),
          );
        },
        tooltip: '添加歌曲',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 添加歌曲到播放列表屏幕
class AddToPlaylistScreen extends StatelessWidget {
  final String playlistName;

  const AddToPlaylistScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final playlistSongs = provider.playlistSongs[playlistName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加歌曲到播放列表'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: provider.musicFiles.length,
        itemBuilder: (context, index) {
          final song = provider.musicFiles[index];
          final isInPlaylist = playlistSongs.contains(song.path);

          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist),
            leading: const Icon(Icons.music_note),
            trailing: Checkbox(
              value: isInPlaylist,
              onChanged: (value) {
                if (value == true) {
                  provider.addSongToPlaylist(playlistName, song.path);
                } else {
                  provider.removeSongFromPlaylist(playlistName, song.path);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
