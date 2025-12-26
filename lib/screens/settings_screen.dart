import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/providers/music_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 播放设置
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('播放设置', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text('播放模式'),
                  trailing: DropdownButton<String>(
                    value: provider.isRepeat
                        ? 'repeat'
                        : provider.isShuffle
                            ? 'shuffle'
                            : 'order',
                    onChanged: (value) {
                      if (value != null) {
                        provider.setPlayMode(mode: value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'order', child: Text('顺序播放')),
                      DropdownMenuItem(value: 'repeat', child: Text('单曲循环')),
                      DropdownMenuItem(value: 'shuffle', child: Text('随机播放')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 音效设置
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('音效设置', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.equalizer),
                  title: const Text('均衡器预设'),
                  trailing: DropdownButton<String>(
                    value: provider.equalizer,
                    onChanged: (value) {
                      if (value != null) {
                        provider.setEqualizer(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('正常')),
                      DropdownMenuItem(value: 'rock', child: Text('摇滚')),
                      DropdownMenuItem(value: 'pop', child: Text('流行')),
                      DropdownMenuItem(value: 'classical', child: Text('古典')),
                      DropdownMenuItem(value: 'folk', child: Text('民谣')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 界面设置
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('界面设置', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  title: const Text('深色主题'),
                  value: provider.isDarkTheme,
                  onChanged: (value) => provider.toggleTheme(),
                  secondary: const Icon(Icons.dark_mode),
                ),
                ListTile(
                  leading: const Icon(Icons.view_list),
                  title: const Text('列表显示样式'),
                  trailing: Text(provider.viewStyle == 'list' ? '列表视图' : '网格视图'),
                  onTap: () => provider.toggleViewStyle(),
                ),
              ],
            ),
          ),

          // 音频设置
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('音频设置', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.headphones),
                  title: const Text('耳机线控'),
                  trailing: const Switch(value: true, onChanged: null),
                ),
                ListTile(
                  leading: const Icon(Icons.audio_file),
                  title: const Text('默认播放格式'),
                  trailing: DropdownButton<String>(
                    value: 'mp3',
                    onChanged: (value) {},
                    items: const [
                      DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'aac', child: Text('AAC')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 睡眠模式
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('睡眠模式', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('定时关闭'),
                  trailing: DropdownButton<String>(
                    value: 'off',
                    onChanged: (value) {},
                    items: const [
                      DropdownMenuItem(value: 'off', child: Text('关闭')),
                      DropdownMenuItem(value: '10', child: Text('10分钟')),
                      DropdownMenuItem(value: '30', child: Text('30分钟')),
                      DropdownMenuItem(value: '60', child: Text('1小时')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 缓存与清理
          Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                const ListTile(
                  title: Text('缓存与清理', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('清理缓存'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认清理'),
                        content: const Text('确定要清理缓存文件吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.cleanCache();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('缓存清理成功')),
                              );
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
