import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_player/providers/music_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<MusicProvider>(context, listen: false).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地音乐播放器'),
        actions: [
          IconButton(
            icon: Icon(provider.viewStyle == 'list' ? Icons.grid_view : Icons.list),
            onPressed: () => provider.toggleViewStyle(),
            tooltip: '切换视图',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => provider.searchSongs(value),
              decoration: InputDecoration(
                hintText: '搜索歌曲、歌手、专辑...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.searchSongs('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),

          // 音乐列表
          Expanded(
            child: provider.filteredMusic.isEmpty
                ? const Center(child: Text('暂无音乐文件'))
                : provider.viewStyle == 'list'
                    ? ListView.builder(
                        itemCount: provider.filteredMusic.length,
                        itemBuilder: (context, index) {
                          final music = provider.filteredMusic[index];
                          return ListTile(
                            title: Text(music.title),
                            subtitle: Text('${music.artist} - ${music.album}'),
                            leading: const Icon(Icons.music_note),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 添加到播放列表按钮
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (playlistName) {
                                    provider.addSongToPlaylist(playlistName, music.path);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('已添加到 $playlistName')),
                                    );
                                  },
                                  itemBuilder: (context) {
                                    if (provider.playlists.isEmpty) {
                                      return [
                                        const PopupMenuItem<String>(
                                          enabled: false,
                                          child: Text('暂无播放列表'),
                                        ),
                                      ];
                                    }
                                    return provider.playlists.map((playlist) {
                                      return PopupMenuItem<String>(
                                        value: playlist,
                                        child: Text('添加到 $playlist'),
                                      );
                                    }).toList();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(provider.isPlaying && provider.currentSong == music
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: () => provider.playMusic(music),
                                ),
                              ],
                            ),
                            onTap: () {
                              provider.playMusic(music);
                              Navigator.pushNamed(context, '/player');
                            },
                          );
                        },
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: provider.filteredMusic.length,
                        itemBuilder: (context, index) {
                          final music = provider.filteredMusic[index];
                          return InkWell(
                            onTap: () {
                              provider.playMusic(music);
                              Navigator.pushNamed(context, '/player');
                            },
                            child: Card(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.music_note, size: 64),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      music.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      music.artist,
                                      style: TextStyle(color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (playlistName) {
                                          provider.addSongToPlaylist(playlistName, music.path);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('已添加到 $playlistName')),
                                          );
                                        },
                                        itemBuilder: (context) {
                                          if (provider.playlists.isEmpty) {
                                            return [
                                              const PopupMenuItem<String>(
                                                enabled: false,
                                                child: Text('暂无播放列表'),
                                              ),
                                            ];
                                          }
                                          return provider.playlists.map((playlist) {
                                            return PopupMenuItem<String>(
                                              value: playlist,
                                              child: Text('添加到 $playlist'),
                                            );
                                          }).toList();
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(provider.isPlaying && provider.currentSong == music
                                            ? Icons.pause
                                            : Icons.play_arrow),
                                        onPressed: () => provider.playMusic(music),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 当前播放控制栏
          if (provider.currentSong != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.currentSong!.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          provider.currentSong!.artist,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () => provider.togglePlay(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => provider.playNext(),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/playlist').then((_) {
              // 返回时重置选中索引
              setState(() {
                _selectedIndex = 0;
              });
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: '播放列表',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 选择文件夹
          final result = await FilePicker.platform.getDirectoryPath();
          if (result != null) {
            await provider.addFolder(result);
          }
        },
        tooltip: '添加音乐文件夹',
        child: const Icon(Icons.add),
      ),
    );
  }
}
