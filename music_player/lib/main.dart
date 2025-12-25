import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/providers/music_provider.dart';
import 'package:music_player/screens/home_screen.dart';
import 'package:music_player/screens/player_screen.dart';
import 'package:music_player/screens/settings_screen.dart';
import 'package:music_player/screens/playlist_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// 全局变量存储后端进程
Process? _backendProcess;

// 启动 Python 后端
Future<void> startBackend() async {
  try {
    // 获取可执行文件所在目录
    final exeDir = path.dirname(Platform.resolvedExecutable);
    final backendDir = path.join(exeDir, 'data', 'flutter_assets', 'assets', 'backend');
    
    // 检查后端文件是否存在
    String scriptDir = backendDir;
    if (!await Directory(backendDir).exists() || !await File(path.join(backendDir, 'main.py')).exists()) {
      // 如果打包后的路径不存在，尝试开发环境路径
      scriptDir = path.join(exeDir, '..', '..', '..', 'backend');
      if (!await File(path.join(scriptDir, 'main.py')).exists()) {
        print('Backend script not found');
        return;
      }
    }
    
    if (Platform.isWindows) {
      // Windows: 使用 VBS 脚本启动，完全隐藏窗口
      final vbsPath = path.join(scriptDir, 'start_backend.vbs');
      if (await File(vbsPath).exists()) {
        _backendProcess = await Process.start(
          'wscript',
          [vbsPath],
          workingDirectory: scriptDir,
          mode: ProcessStartMode.detached,
          runInShell: false,
        );
        print('Backend started with VBS launcher');
      } else {
        // 如果 VBS 不存在，尝试使用 pythonw
        _backendProcess = await Process.start(
          'pythonw',
          [path.join(scriptDir, 'main.py')],
          workingDirectory: scriptDir,
          mode: ProcessStartMode.detached,
          runInShell: false,
        );
        print('Backend started with pythonw');
      }
    } else {
      // Linux/Mac: 使用 python3
      _backendProcess = await Process.start(
        'python3',
        [path.join(scriptDir, 'main.py')],
        workingDirectory: scriptDir,
        mode: ProcessStartMode.detached,
        runInShell: false,
      );
      print('Backend started with python3');
    }
    
    // 等待一秒确保后端启动
    await Future.delayed(const Duration(seconds: 1));
  } catch (e) {
    print('Failed to start backend: $e');
  }
}

// 停止后端
void stopBackend() {
  if (_backendProcess != null) {
    _backendProcess!.kill();
    _backendProcess = null;
    print('Backend stopped');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启动后端
  await startBackend();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 应用退出时停止后端
      stopBackend();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _lifecycleObserver = _AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    stopBackend(); // 确保退出时停止后端
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: '本地音乐播放器',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          themeMode: provider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/player': (context) => const PlayerScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/playlist': (context) => const PlaylistScreen(),
          },
        );
      },
    );
  }
}
