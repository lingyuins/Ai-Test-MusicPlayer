import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/providers/music_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  // 格式化时间
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

    if (provider.currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('暂无播放歌曲')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放界面'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 封面图
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 150,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // 歌曲信息
              Text(
                provider.currentSong!.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Text(
                provider.currentSong!.artist,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                provider.currentSong!.album,
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 30),

              // 播放进度
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(provider.currentPosition.toInt())), // 当前播放时间
                      Text(formatTime(provider.currentSong!.duration)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: provider.currentPosition,
                    min: 0.0,
                    max: provider.currentSong!.duration.toDouble(),
                    onChanged: (value) async {
                      // 进度条拖拽处理
                      await provider.audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 播放控制
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(provider.isRepeat ? Icons.repeat_one : Icons.repeat),
                    onPressed: () => provider.setPlayMode(),
                    iconSize: 30,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => provider.playPrevious(),
                    iconSize: 40,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(
                      provider.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    ),
                    onPressed: () => provider.togglePlay(),
                    iconSize: 60,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => provider.playNext(),
                    iconSize: 40,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(provider.isShuffle ? Icons.shuffle_on : Icons.shuffle),
                    onPressed: () => provider.setPlayMode(),
                    iconSize: 30,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 音量控制
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_mute),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: provider.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) => provider.setVolume(value),
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ],
              ),

              const SizedBox(height: 20),

              // 歌词显示区域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '歌词将显示在这里',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
