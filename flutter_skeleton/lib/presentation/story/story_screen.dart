import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/game_state.dart';
import '../../core/services/ad_service.dart';
import '../../data/models/scene_node.dart';
import '../investigation/investigation_sheet.dart';
import '../providers/game_provider.dart';

const bool _kScreenshotMode =
    bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

final storyNodesProvider = FutureProvider<Map<String, SceneNode>>((ref) async {
  final sceneMap = <String, SceneNode>{};

  Future<void> loadChapter(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final scenesRaw = jsonMap['scenes'] as List<dynamic>;
      for (final raw in scenesRaw) {
        final node = SceneNode.fromJson(raw as Map<String, dynamic>);
        sceneMap[node.id] = node;
      }
    } catch (e) {
      debugPrint('챕터 로드 실패 ($path): $e');
    }
  }

  await loadChapter('assets/story/chapter1.json');
  await loadChapter('assets/story/chapter2.json');
  await loadChapter('assets/story/chapter3.json');

  return sceneMap;
});

class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  late AudioPlayer bgmPlayer;
  late AudioPlayer sfxPlayer;
  final ScrollController _textScrollController = ScrollController();
  String? _currentBgm;
  String? _lastPlayedSceneId;
  int? _hintChoiceIndex;
  bool _showingHintAd = false;

  static const Set<String> _impactSceneIds = {
    'scene_murder_discovery',
    'scene_window_check',
    'scene_confront_door',
    'scene_hide_curtain',
    'scene_evelyn_hostile',
    'scene_death_bad_ending_1',
    'scene_night_explore',
    'scene_greenhouse_dark',
    'scene_greenhouse_light',
    'scene_investigate_richard_room',
    'scene_richard_room_steal',
    'scene_talk_doctor',
    'scene_doctor_hostile',
    'scene_investigate_greenhouse_trap',
    'scene_investigate_study_day2',
    'scene_day2_afternoon_event',
    'scene_day2_second_murder',
    'scene_accuse_evelyn',
    'scene_accuse_richard',
    'scene_ending_true',
    'scene_ending_evelyn_escape',
    'scene_ending_bad_richard',
    'scene_ending_unsolved',
  };

  static const _speakerColors = <String, Color>{
    '아서 블랙우드': Color(0xFFD4A76A),
    '에블린 블랙우드': Color(0xFFB898D4),
    '리처드 블랙우드': Color(0xFFE07A5F),
    '도로시 페어뱅크 박사': Color(0xFF7EB8C9),
  };

  @override
  void initState() {
    super.initState();
    bgmPlayer = AudioPlayer();
    sfxPlayer = AudioPlayer();
    bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    bgmPlayer.dispose();
    sfxPlayer.dispose();
    _textScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSound(SceneNode node) async {
    // BGM 처리
    if (node.bgm != _currentBgm) {
      _currentBgm = node.bgm;
      await bgmPlayer.stop();
      if (_currentBgm != null && _currentBgm!.isNotEmpty) {
        try {
          // mp3 우선 시도 후 wav 시도 (플레이스홀더 대응)
          await bgmPlayer.play(AssetSource('audio/$_currentBgm.mp3'));
        } catch (_) {
          try {
            await bgmPlayer.play(AssetSource('audio/$_currentBgm.wav'));
          } catch (e) {
            debugPrint('BGM 재생 실패: $_currentBgm ($e)');
          }
        }
      }
    }

    // SFX 처리
    if (node.sfx != null && node.sfx!.isNotEmpty) {
      try {
        await sfxPlayer.stop(); // 이전 SFX 중지
        await sfxPlayer.play(AssetSource('audio/${node.sfx}.mp3'));
      } catch (_) {
        try {
          await sfxPlayer.play(AssetSource('audio/${node.sfx}.wav'));
        } catch (e) {
          debugPrint('SFX 재생 실패: ${node.sfx} ($e)');
        }
      }
    }
  }

  bool _isImpactScene(SceneNode node) {
    return _impactSceneIds.contains(node.id) ||
        node.id.contains('ending') ||
        node.id.contains('death');
  }

  double _backgroundDarkness(SceneNode node) {
    if (_isImpactScene(node)) return 0.28;
    if (node.speaker != 'system') return 0.36;
    return 0.42;
  }

  Color _speakerColor(SceneNode node) {
    if (_isImpactScene(node)) return const Color(0xFFFFC88A);
    return _speakerColors[node.speaker] ?? Colors.redAccent;
  }

  List<Color> _textGradientColors(SceneNode node) {
    if (_isImpactScene(node)) {
      return [
        const Color(0xFF050608).withOpacity(0.97),
        const Color(0xE611141A),
        Colors.transparent,
      ];
    }
    return [
      const Color(0xFF080B10).withOpacity(0.94),
      const Color(0xD80D1118),
      Colors.transparent,
    ];
  }

  Color _impactFlashColor(SceneNode node) {
    if (node.id.contains('ending_true')) return const Color(0xBFF3DFA3);
    if (node.id.contains('ending')) return const Color(0x88B4122D);
    return const Color(0x70F0D9A2);
  }

  Widget _buildBackground(SceneNode node) {
    return AnimatedSwitcher(
      duration: 500.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.04, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: Stack(
        key: ValueKey(node.id),
        fit: StackFit.expand,
        children: [
          if (node.backgroundImageUrl.isNotEmpty)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(_backgroundDarkness(node)),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/images/${node.backgroundImageUrl}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            )
          else
            Container(color: const Color(0xFF080A0E)),
          // Top vignette
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA050A10),
                  Colors.transparent,
                  Color(0x55000000),
                ],
                stops: [0, 0.32, 1],
              ),
            ),
          ),
          // Radial vignette
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Color(0x22000000),
                  Color(0x99000000),
                ],
                stops: [0.45, 0.75, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactFlash(SceneNode node) {
    if (!_isImpactScene(node)) return const SizedBox.shrink();

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('impact_${node.id}'),
        tween: Tween(begin: 1, end: 0),
        duration: 600.ms,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.12),
              radius: 0.98,
              colors: [_impactFlashColor(node), Colors.transparent],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(GameState gameState) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Time indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, color: Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${gameState.timeElapsed}h',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Danger indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: gameState.dangerLevel > 0
                    ? Colors.red.withOpacity(0.15)
                    : Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gameState.dangerLevel > 0
                      ? Colors.redAccent.withOpacity(0.4)
                      : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
                    child: Icon(
                      index < gameState.dangerLevel
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: index < gameState.dangerLevel
                          ? Colors.redAccent
                          : Colors.white24,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerLabel(SceneNode node) {
    if (node.speaker == 'system') return const SizedBox.shrink();

    final color = _speakerColor(node);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            node.speaker,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(SceneNode node) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        onPressed: () {
          ref.read(gameStateProvider.notifier).makeChoice(
                nextSceneId: node.nextSceneId!,
              );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                node.continueText ?? '계속 읽기',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(
    ChoiceNode choice,
    int index,
    bool isAvailable,
    SceneNode currentNode,
    Set<String> currentEvidence, {
    bool isHinted = false,
  }) {
    final isImpact = _isImpactScene(currentNode);
    final borderColor = isHinted
        ? const Color(0xFFD4A76A).withOpacity(0.9)
        : isImpact
            ? const Color(0xFFD4A76A).withOpacity(0.4)
            : Colors.white.withOpacity(0.18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable
              ? () {
                  ref.read(gameStateProvider.notifier).makeChoice(
                        nextSceneId: choice.nextSceneId,
                        timeCost: choice.timeCost,
                        dangerDelta: choice.dangerDelta,
                        newEvidence: choice.addEvidence,
                        resetGame: choice.resetGame,
                      );
                  choice.trustDelta.forEach((charName, delta) {
                    ref
                        .read(gameStateProvider.notifier)
                        .updateTrust(charName, delta);
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.08),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isAvailable
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAvailable
                        ? borderColor.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: isAvailable ? borderColor : Colors.white12,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isAvailable ? Colors.white70 : Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAvailable
                        ? choice.text
                        : '${choice.text} (증거 부족)',
                    style: TextStyle(
                      color: isAvailable ? Colors.white.withOpacity(0.85) : Colors.white38,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (choice.dangerDelta > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.redAccent.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _requestHint(List<ChoiceNode> choices) {
    if (_showingHintAd) return;
    final evidence = ref.read(gameStateProvider).evidence.toSet();

    int? safestIndex;
    int minDanger = 999;
    for (int i = 0; i < choices.length; i++) {
      final c = choices[i];
      if (!c.requiredEvidence.every(evidence.contains)) continue;
      if (c.dangerDelta < minDanger) {
        minDanger = c.dangerDelta;
        safestIndex = i;
      }
    }

    setState(() => _showingHintAd = true);
    AdService.instance.showRewardedAd(
      onRewarded: () {
        if (!mounted) return;
        setState(() {
          _hintChoiceIndex = safestIndex;
          _showingHintAd = false;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _hintChoiceIndex = null);
        });
      },
    ).then((_) {
      if (mounted) setState(() => _showingHintAd = false);
    });
  }

  Widget _buildDeathOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dangerous_outlined, color: Color(0xFFB4122D), size: 56),
                const SizedBox(height: 16),
                const Text(
                  '탐정 사망',
                  style: TextStyle(
                    color: Color(0xFFB4122D),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '잘못된 선택이 당신의 목숨을 앗아갔습니다.',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A76A),
                      foregroundColor: const Color(0xFF1A1008),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      AdService.instance.showRewardedAd(
                        onRewarded: () {
                          if (!mounted) return;
                          ref.read(gameStateProvider.notifier).reviveGame();
                        },
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text(
                      '광고 시청 후 이어하기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(gameStateProvider.notifier).resetGame();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StoryScreen()),
                      );
                    },
                    child: Text(
                      '처음부터 시작',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final scenesAsyncValue = ref.watch(storyNodesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: scenesAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4A76A),
            strokeWidth: 2,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            '스토리 로드 실패: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (sceneMap) {
          final currentNode = sceneMap[gameState.currentSceneId];
          final currentEvidence = gameState.evidence.toSet();

          if (currentNode == null) {
            return const Center(
              child: Text(
                '오류: 장면을 찾을 수 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (_lastPlayedSceneId != currentNode.id) {
            _lastPlayedSceneId = currentNode.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleSound(currentNode);
                if (_textScrollController.hasClients) {
                  _textScrollController.jumpTo(0);
                }
              }
            });
          }

          final hasChoices = currentNode.choices.isNotEmpty;
          final textAreaHeight = hasChoices
              ? screenHeight * 0.55
              : screenHeight * 0.48;

          Widget content = Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(currentNode),
              _buildImpactFlash(currentNode),

              // Status bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildStatusBar(gameState),
              ),

              // Text area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: textAreaHeight,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: _textGradientColors(currentNode),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Speaker label
                      _buildSpeakerLabel(currentNode),

                      // Story text
                      Expanded(
                        child: Scrollbar(
                          controller: _textScrollController,
                          thumbVisibility: true,
                          thickness: 2,
                          radius: const Radius.circular(1),
                          child: SingleChildScrollView(
                            controller: _textScrollController,
                            padding: const EdgeInsets.only(right: 8),
                            child: _kScreenshotMode
                                ? Text(
                                    currentNode.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.8,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black87,
                                            blurRadius: 8),
                                      ],
                                    ),
                                  )
                                : AnimatedTextKit(
                                    key: ValueKey(currentNode.id),
                                    animatedTexts: [
                                      TyperAnimatedText(
                                        currentNode.text,
                                        speed: const Duration(milliseconds: 30),
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.8,
                                          letterSpacing: 0.2,
                                          shadows: [
                                            Shadow(
                                                color: Colors.black87,
                                                blurRadius: 8),
                                          ],
                                        ),
                                      ),
                                    ],
                                    isRepeatingAnimation: false,
                                    displayFullTextOnTap: true,
                                  ),
                          ),
                        ),
                      ),

                      // Choices or continue button
                      if (!hasChoices && currentNode.nextSceneId != null)
                        _buildContinueButton(currentNode),

                      if (hasChoices) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Row(
                            children: [
                              Container(width: 16, height: 1, color: Colors.white24),
                              const SizedBox(width: 8),
                              Text(
                                '선택',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Container(height: 1, color: Colors.white12)),
                              if (!_kScreenshotMode) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showingHintAd ? null : () => _requestHint(currentNode.choices),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4A76A).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFD4A76A).withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 11, color: const Color(0xFFD4A76A).withOpacity(0.8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          _showingHintAd ? '로딩…' : '힌트',
                                          style: TextStyle(
                                            color: const Color(0xFFD4A76A).withOpacity(0.8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ...currentNode.choices.asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final choice = entry.value;
                            final isAvailable = choice.requiredEvidence
                                .every(currentEvidence.contains);
                            return _buildChoiceButton(
                              choice,
                              index,
                              isAvailable,
                              currentNode,
                              currentEvidence,
                              isHinted: _hintChoiceIndex == index,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );

          if (gameState.dangerLevel > 0) {
            content = content
                .animate(
                    key: ValueKey(
                        'danger_${gameState.dangerLevel}_${currentNode.id}'))
                .shake(hz: 8, duration: 500.ms);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (gameState.isDead) _buildDeathOverlay(),
              if (!_kScreenshotMode && !gameState.isDead)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => showInvestigationMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_outlined, color: Colors.white60, size: 15),
                          SizedBox(width: 5),
                          Text(
                            '단서장',
                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
