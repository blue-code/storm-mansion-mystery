import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MysteryApp()));
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
        fontFamily: 'NotoSerif', // 명조체 계열 추천
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 (임시 색상 처리)
          Container(
            color: Colors.black87,
            child: const Center(
              child: Text(
                '폭풍 저택의 유언\nTestament of the Stormy Mansion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(color: Colors.redAccent, blurRadius: 10)
                  ]
                ),
              ),
            ),
          ),
          
          // 메뉴 버튼들
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () {
                    // TODO: StoryScreen으로 이동
                  },
                  child: const Text('새 사건 조사', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () {
                    // TODO: 이어하기 로직
                  },
                  child: const Text('기록 열람 (이어하기)', style: TextStyle(fontSize: 18, color: Colors.white70)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
