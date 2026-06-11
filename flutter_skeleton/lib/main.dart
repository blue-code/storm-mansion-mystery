import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/game_state.dart';
import 'core/services/ad_service.dart';
import 'presentation/investigation/investigation_sheet.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/settings/settings_sheet.dart';
import 'presentation/story/story_screen.dart';

const bool kScreenshotMode =
    bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

/// 스크린샷 캡처 시 각 씬을 보여주는 시간 (초). bash 측 캡처 주기와 일치해야 한다.
const int kScreenshotSecondsPerScene = 4;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // 광고/IDFA 초기화는 ATT 권한 요청 이후로 미룬다(아래 MysteryApp 참고).
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MysteryApp(),
    ),
  );
}

class MysteryApp extends StatefulWidget {
  const MysteryApp({super.key});

  @override
  State<MysteryApp> createState() => _MysteryAppState();
}

class _MysteryAppState extends State<MysteryApp> {
  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      // 첫 프레임이 그려진 뒤(앱 활성 상태) ATT 팝업을 띄워야 정상 표시된다.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _initTrackingThenAds());
    }
  }

  /// App Tracking Transparency: 추적 데이터(AdMob IDFA) 수집 전에
  /// 권한 요청 팝업을 먼저 띄우고, 그 다음 광고를 초기화한다.
  Future<void> _initTrackingThenAds() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // iOS가 팝업을 안정적으로 띄울 수 있도록 잠시 대기.
        await Future.delayed(const Duration(milliseconds: 400));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT 권한 요청 실패: $e');
    }
    // 권한 처리 후 광고 초기화 (IDFA 수집은 이 시점 이후)
    await AdService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '폭풍 저택의 유언',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red[900],
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'NotoSerif',
      ),
      home:
          kScreenshotMode ? const _ScreenshotRouter() : const MainMenuScreen(),
    );
  }
}

/// 스크린샷 한 컷의 사양
class _Shot {
  const _Shot.menu()
      : target = 'menu',
        state = const GameState();
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

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  AudioPlayer? _menuBgm;

  @override
  void initState() {
    super.initState();
    if (!kScreenshotMode) {
      _startMenuBgm();
    }
  }

  Future<void> _startMenuBgm() async {
    try {
      final player = AudioPlayer();
      _menuBgm = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.55);
      try {
        await player.play(AssetSource('audio/rain_and_storm.mp3'));
      } catch (_) {
        await player.play(AssetSource('audio/rain_and_storm.wav'));
      }
    } catch (e) {
      debugPrint('메뉴 BGM 재생 실패: $e');
    }
  }

  @override
  void dispose() {
    _menuBgm?.dispose();
    super.dispose();
  }

  Future<void> _enterStory({required bool reset}) async {
    if (reset) {
      ref.read(gameStateProvider.notifier).resetGame();
    }
    await _menuBgm?.stop();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 — 느린 켄번스 줌으로 생동감 부여
          Image.asset(
            'assets/images/title_screen.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                begin: 1.0,
                end: 1.12,
                duration: 18.seconds,
                curve: Curves.easeInOut,
              ),
          // 어둡게 오버레이 + 가장자리 비네트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x22000000),
                  Color(0xCC000000),
                  Color(0xF2000000),
                ],
                stops: [0, 0.32, 0.72, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.15,
                colors: [Colors.transparent, Color(0x66000000)],
                stops: [0.55, 1],
              ),
            ),
          ),
          // 타이틀 텍스트
          Positioned(
            top: size.height * 0.13,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  '폭풍 저택의 유언',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Colors.black, blurRadius: 20),
                      Shadow(
                          color: const Color(0xFFD4A76A).withOpacity(0.5),
                          blurRadius: 30),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1400.ms, delay: 300.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                // 장식용 금색 구분선
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 28,
                        height: 1,
                        color: const Color(0xFFD4A76A).withOpacity(0.5)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.diamond_outlined,
                          size: 10, color: Color(0xFFD4A76A)),
                    ),
                    Container(
                        width: 28,
                        height: 1,
                        color: const Color(0xFFD4A76A).withOpacity(0.5)),
                  ],
                ).animate().fadeIn(duration: 1600.ms, delay: 700.ms),
                const SizedBox(height: 10),
                Text(
                  'STORM MANSION MYSTERY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 5.0,
                    color: Colors.white.withOpacity(0.55),
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ).animate().fadeIn(duration: 1800.ms, delay: 900.ms),
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
                      backgroundColor: const Color(0xFFD4A76A).withOpacity(0.9),
                      foregroundColor: const Color(0xFF1A1008),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _enterStory(reset: true),
                    child: const Text(
                      '새 사건 조사',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1),
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
                    onPressed: () => _enterStory(reset: false),
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
          )
              .animate()
              .fadeIn(duration: 1400.ms, delay: 1300.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
          // 설정 (글씨 크기 등)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => showSettingsSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child:
                    const Icon(Icons.settings, color: Colors.white70, size: 20),
              ),
            ).animate().fadeIn(duration: 1200.ms, delay: 1500.ms),
          ),
        ],
      ),
    );
  }
}
