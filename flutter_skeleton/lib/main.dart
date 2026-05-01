import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/game_state.dart';
import 'core/services/ad_service.dart';
import 'presentation/investigation/investigation_sheet.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/story/story_screen.dart';

const bool kScreenshotMode =
    bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

/// 스크린샷 캡처 시 각 씬을 보여주는 시간 (초). bash 측 캡처 주기와 일치해야 한다.
const int kScreenshotSecondsPerScene = 4;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (!kScreenshotMode) {
    await AdService.instance.initialize();
  }

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
      home: kScreenshotMode
          ? const _ScreenshotRouter()
          : const MainMenuScreen(),
    );
  }
}

/// 스크린샷 한 컷의 사양
class _Shot {
  const _Shot.menu() : target = 'menu', state = const GameState();
  const _Shot.investigation(this.state) : target = 'investigation';
  const _Shot.story(this.state) : target = 'story';

  final String target;
  final GameState state;
}

class _ScreenshotRouter extends ConsumerStatefulWidget {
  const _ScreenshotRouter();

  @override
  ConsumerState<_ScreenshotRouter> createState() => _ScreenshotRouterState();
}

class _ScreenshotRouterState extends ConsumerState<_ScreenshotRouter> {
  // 캡처 순서. tool/take_screenshots.sh 의 파일명 순서와 일치해야 한다.
  static const _shots = <_Shot>[
    // 01_title
    _Shot.menu(),
    // 02_intro_storm
    _Shot.story(GameState(currentSceneId: 'scene_101')),
    // 03_office_choice (선택지가 있는 분기 신)
    _Shot.story(GameState(
      currentSceneId: 'scene_day0_office',
      timeElapsed: 1,
    )),
    // 04_murder_discovery
    _Shot.story(GameState(
      currentSceneId: 'scene_murder_discovery',
      timeElapsed: 6,
      evidence: ['old_letter', 'strange_keyhole'],
    )),
    // 05_danger_shake (위험도 2)
    _Shot.story(GameState(
      currentSceneId: 'scene_doctor_hostile',
      timeElapsed: 9,
      dangerLevel: 2,
      evidence: ['old_letter', 'strange_keyhole', 'bloody_glove'],
    )),
    // 06_accusation
    _Shot.story(GameState(
      currentSceneId: 'scene_accuse_evelyn',
      timeElapsed: 14,
      dangerLevel: 1,
      evidence: [
        'old_letter',
        'strange_keyhole',
        'bloody_glove',
        'hidden_will',
      ],
    )),
    // 07_investigation_sheet
    _Shot.investigation(GameState(
      timeElapsed: 3,
      evidence: [
        '낡은 편지',
        '이상한 열쇠 구멍',
        '피 묻은 장갑',
      ],
      trustMap: {
        '에블린 블랙우드': -12,
        '리처드 블랙우드': 8,
        '도로시 페어뱅크 박사': 14,
      },
    )),
    // 08_true_ending
    _Shot.story(GameState(
      currentSceneId: 'scene_ending_true',
      timeElapsed: 18,
      dangerLevel: 1,
      evidence: [
        'old_letter',
        'strange_keyhole',
        'bloody_glove',
        'hidden_will',
        'final_proof',
      ],
    )),
  ];

  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyShot(_shots[_idx]);
    });
    _timer = Timer.periodic(
      const Duration(seconds: kScreenshotSecondsPerScene),
      (_) {
        if (_idx >= _shots.length - 1) {
          _timer?.cancel();
          return;
        }
        setState(() => _idx += 1);
        _applyShot(_shots[_idx]);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _applyShot(_Shot s) {
    ref.read(gameStateProvider.notifier).overwriteForScreenshot(s.state);
  }

  @override
  Widget build(BuildContext context) {
    final shot = _shots[_idx];
    switch (shot.target) {
      case 'story':
        return const StoryScreen();
      case 'investigation':
        return Scaffold(
          backgroundColor: const Color(0xCC000000),
          body: SafeArea(child: const Center(child: InvestigationSheet())),
        );
      case 'menu':
      default:
        return const MainMenuScreen();
    }
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
