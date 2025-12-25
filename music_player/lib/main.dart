import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/providers/music_provider.dart';
import 'package:music_player/screens/home_screen.dart';
import 'package:music_player/screens/player_screen.dart';
import 'package:music_player/screens/settings_screen.dart';
import 'package:music_player/screens/playlist_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
