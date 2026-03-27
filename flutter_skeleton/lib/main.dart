import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/providers/game_provider.dart';
import 'presentation/story/story_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MysteryApp(),
    ),
  );
}

class MysteryApp extends StatelessWidget {
  const MysteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '폭풍 저택의 유언',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red[900],
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'NotoSerif',
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          Image.asset(
            'assets/images/title_screen.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ),
          // 어둡게 오버레이
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x44000000),
                  Color(0x22000000),
                  Color(0xBB000000),
                  Color(0xEE000000),
                ],
                stops: [0, 0.3, 0.7, 1],
              ),
            ),
          ),
          // 타이틀 텍스트
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  '폭풍 저택의 유언',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 20),
                      Shadow(color: const Color(0xFFD4A76A).withOpacity(0.5), blurRadius: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'STORM MANSION MYSTERY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 6.0,
                    color: Colors.white.withOpacity(0.5),
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 메뉴 버튼들
          Positioned(
            bottom: 60 + bottomPadding,
            left: 40,
            right: 40,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A76A).withOpacity(0.85),
                      foregroundColor: const Color(0xFF1A1008),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ref.read(gameStateProvider.notifier).resetGame();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StoryScreen()),
                      );
                    },
                    child: const Text(
                      '새 사건 조사',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StoryScreen()),
                      );
                    },
                    child: Text(
                      '기록 열람 (이어하기)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
