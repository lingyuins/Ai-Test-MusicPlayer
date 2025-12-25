import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/music.dart';

class MusicProvider extends ChangeNotifier {
  // API基础URL
  static const String baseUrl = 'http://localhost:8000/api';

  // 音频播放器
  late AudioPlayer _audioPlayer;
  double _currentPosition = 0.0;

  // 状态变量
  List<Music> _musicFiles = [];
  List<Music> _filteredMusic = [];
  List<String> _playlists = [];
  Map<String, List<String>> _playlistSongs = {};
  Music? _currentSong;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _volume = 0.7;
  String _equalizer = 'normal';
  bool _isDarkTheme = false;
  String _viewStyle = 'list';
  String _searchQuery = '';

  // Getters
  List<Music> get musicFiles => _musicFiles;
  List<Music> get filteredMusic => _filteredMusic.isEmpty ? _musicFiles : _filteredMusic;
  List<String> get playlists => _playlists;
  Map<String, List<String>> get playlistSongs => _playlistSongs;
  Music? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get volume => _volume;
  String get equalizer => _equalizer;
  bool get isDarkTheme => _isDarkTheme;
  String get viewStyle => _viewStyle;
  String get searchQuery => _searchQuery;
  double get currentPosition => _currentPosition;
  AudioPlayer get audioPlayer => _audioPlayer;

  // 初始化
  Future<void> initialize() async {
    // 初始化音频播放器
    _audioPlayer = AudioPlayer();
    
    // 设置音频会话
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    
    // 监听播放状态变化
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    
    // 监听播放位置变化
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position.inSeconds.toDouble();
      notifyListeners();
    });
    
    // 监听播放完成事件
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          // 单曲循环
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (_isShuffle) {
          // 随机播放下一首
          _playRandom();
        } else {
          // 顺序播放下一首
          playNext();
        }
      }
    });
    
    // 初始化音量
    _audioPlayer.setVolume(_volume);
    
    // 初始化其他数据
    await fetchConfig();
    await fetchMusicFiles();
    await fetchPlaylists();
  }

  // 获取配置
  Future<void> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/config'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _volume = data['volume'] ?? 0.7;
        _equalizer = data['equalizer'] ?? 'normal';
        _isDarkTheme = data['dark_theme'] ?? false;
        _viewStyle = data['view_style'] ?? 'list';
        _isShuffle = data['play_mode'] == 'shuffle';
        _isRepeat = data['play_mode'] == 'repeat';
        notifyListeners();
      }
    } catch (e) {
      print('获取配置失败: $e');
    }
  }

  // 更新配置
  Future<void> updateConfig(Map<String, dynamic> config) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(config),
      );
      if (response.statusCode == 200) {
        await fetchConfig();
      }
    } catch (e) {
      print('更新配置失败: $e');
    }
  }

  // 扫描音乐文件
  Future<void> scanFolder(String folderPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan'),
        body: {'folder_path': folderPath},
      );
      if (response.statusCode == 200) {
        await fetchMusicFiles();
      }
    } catch (e) {
      print('扫描文件夹失败: $e');
    }
  }

  // 添加音乐文件夹
  Future<void> addFolder(String folderPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-folder'),
        body: {'folder_path': folderPath},
      );
      if (response.statusCode == 200) {
        await fetchMusicFiles();
      }
    } catch (e) {
      print('添加文件夹失败: $e');
    }
  }

  // 移除音乐文件夹
  Future<void> removeFolder(String folderPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove-folder'),
        body: {'folder_path': folderPath},
      );
      if (response.statusCode == 200) {
        await fetchMusicFiles();
      }
    } catch (e) {
      print('移除文件夹失败: $e');
    }
  }

  // 获取音乐文件列表
  Future<void> fetchMusicFiles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/music-files'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List;
        _musicFiles = files.map((file) => Music.fromJson(file)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('获取音乐文件失败: $e');
    }
  }

  // 获取播放列表
  Future<void> fetchPlaylists() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/playlists'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playlists = data['playlists'] as Map<String, dynamic>;
        _playlists = playlists.keys.toList();
        _playlistSongs = {
          for (var entry in playlists.entries)
            entry.key: List<String>.from(entry.value)
        };
        notifyListeners();
      }
    } catch (e) {
      print('获取播放列表失败: $e');
    }
  }

  // 创建播放列表
  Future<void> createPlaylist(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/create'),
        body: {'name': name},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
      }
    } catch (e) {
      print('创建播放列表失败: $e');
    }
  }

  // 删除播放列表
  Future<void> deletePlaylist(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/delete'),
        body: {'name': name},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
      }
    } catch (e) {
      print('删除播放列表失败: $e');
    }
  }

  // 重命名播放列表
  Future<void> renamePlaylist(String oldName, String newName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/rename'),
        body: {'old_name': oldName, 'new_name': newName},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
      }
    } catch (e) {
      print('重命名播放列表失败: $e');
    }
  }

  // 添加歌曲到播放列表
  Future<void> addSongToPlaylist(String playlistName, String songPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/add-song'),
        body: {'playlist_name': playlistName, 'song_path': songPath},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
      }
    } catch (e) {
      print('添加歌曲到播放列表失败: $e');
    }
  }

  // 从播放列表移除歌曲
  Future<void> removeSongFromPlaylist(String playlistName, String songPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/remove-song'),
        body: {'playlist_name': playlistName, 'song_path': songPath},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
      }
    } catch (e) {
      print('从播放列表移除歌曲失败: $e');
    }
  }

  // 搜索歌曲
  Future<void> searchSongs(String query) async {
    try {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMusic.clear();
        notifyListeners();
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        body: {'query': query},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        _filteredMusic = results.map((file) => Music.fromJson(file)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('搜索歌曲失败: $e');
    }
  }

  // 设置播放模式
  Future<void> setPlayMode({String? mode}) async {
    String playMode;
    
    if (mode != null) {
      // 直接设置指定模式
      playMode = mode;
      if (mode == 'repeat') {
        _isRepeat = true;
        _isShuffle = false;
      } else if (mode == 'shuffle') {
        _isShuffle = true;
        _isRepeat = false;
      } else {
        _isRepeat = false;
        _isShuffle = false;
      }
    } else {
      // 循环切换模式
      if (_isRepeat) {
        playMode = 'order';
        _isRepeat = false;
        _isShuffle = false;
      } else if (_isShuffle) {
        playMode = 'repeat';
        _isShuffle = false;
        _isRepeat = true;
      } else {
        playMode = 'shuffle';
        _isShuffle = true;
        _isRepeat = false;
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/play-mode'),
        body: {'mode': playMode},
      );
      if (response.statusCode == 200) {
        notifyListeners();
      }
    } catch (e) {
      print('设置播放模式失败: $e');
    }
  }

  // 设置音量
  Future<void> setVolume(double newVolume) async {
    try {
      _volume = newVolume;
      await _audioPlayer.setVolume(newVolume);
      final response = await http.post(
        Uri.parse('$baseUrl/volume'),
        body: {'volume': newVolume.toString()},
      );
      if (response.statusCode == 200) {
        notifyListeners();
      }
    } catch (e) {
      print('设置音量失败: $e');
    }
  }

  // 随机播放
  void _playRandom() {
    if (_musicFiles.isNotEmpty) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _musicFiles.length;
      _currentIndex = randomIndex;
      _currentSong = _musicFiles[randomIndex];
      _playCurrentSong();
    }
  }

  // 设置均衡器
  Future<void> setEqualizer(String preset) async {
    try {
      _equalizer = preset;
      final response = await http.post(
        Uri.parse('$baseUrl/equalizer'),
        body: {'preset': preset},
      );
      if (response.statusCode == 200) {
        notifyListeners();
      }
    } catch (e) {
      print('设置均衡器失败: $e');
    }
  }

  // 切换主题
  Future<void> toggleTheme() async {
    try {
      _isDarkTheme = !_isDarkTheme;
      final response = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dark_theme': _isDarkTheme}),
      );
      if (response.statusCode == 200) {
        notifyListeners();
      }
    } catch (e) {
      print('切换主题失败: $e');
    }
  }

  // 切换视图样式
  Future<void> toggleViewStyle() async {
    try {
      _viewStyle = _viewStyle == 'list' ? 'grid' : 'list';
      final response = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'view_style': _viewStyle}),
      );
      if (response.statusCode == 200) {
        notifyListeners();
      }
    } catch (e) {
      print('切换视图样式失败: $e');
    }
  }

  // 播放当前歌曲
  Future<void> _playCurrentSong() async {
    if (_currentSong != null) {
      try {
        await _audioPlayer.setFilePath(_currentSong!.path);
        await _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      } catch (e) {
        print('播放音乐失败: $e');
      }
    }
  }

  // 播放音乐
  void playMusic(Music song) {
    _currentSong = song;
    _currentIndex = _musicFiles.indexOf(song);
    _playCurrentSong();
  }

  // 切换播放状态
  void togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // 播放下一首
  void playNext() {
    if (_currentIndex < _musicFiles.length - 1) {
      _currentIndex++;
      _currentSong = _musicFiles[_currentIndex];
      _playCurrentSong();
    }
  }

  // 播放上一首
  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentSong = _musicFiles[_currentIndex];
      _playCurrentSong();
    }
  }

  // 更新当前播放索引
  void updateCurrentIndex(int index) {
    if (index >= 0 && index < _musicFiles.length) {
      _currentIndex = index;
      _currentSong = _musicFiles[index];
      notifyListeners();
    }
  }

  // 清理缓存
  Future<void> cleanCache() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/clean-cache'));
      if (response.statusCode == 200) {
        // 清理成功
      }
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
