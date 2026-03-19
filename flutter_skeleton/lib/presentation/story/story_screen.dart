import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/scene_node.dart';
import '../providers/game_provider.dart';

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

  void _handleSound(SceneNode node) {
    if (node.bgm != _currentBgm) {
      _currentBgm = node.bgm;
      if (_currentBgm != null && _currentBgm!.isNotEmpty) {
        bgmPlayer.play(AssetSource('audio/$_currentBgm.mp3'));
      } else {
        bgmPlayer.stop();
      }
    }

    if (node.sfx != null && node.sfx!.isNotEmpty) {
      sfxPlayer.play(AssetSource('audio/${node.sfx}.mp3'));
    }
  }

  bool _isImpactScene(SceneNode node) {
    return _impactSceneIds.contains(node.id) ||
        node.id.contains('ending') ||
        node.id.contains('death');
  }

  double _backgroundDarkness(SceneNode node) {
    if (_isImpactScene(node)) {
      return 0.32;
    }

    if (node.speaker != 'system') {
      return 0.4;
    }

    return 0.46;
  }

  List<Color> _textGradientColors(SceneNode node) {
    if (_isImpactScene(node)) {
      return [
        const Color(0xFF050608).withOpacity(0.96),
        const Color(0xE611141A),
        Colors.transparent,
      ];
    }

    return [
      const Color(0xFF050608).withOpacity(0.92),
      const Color(0xD811141A),
      Colors.transparent,
    ];
  }

  Color _impactFlashColor(SceneNode node) {
    if (node.id.contains('ending_true')) {
      return const Color(0xBFF3DFA3);
    }

    if (node.id.contains('ending')) {
      return const Color(0x88B4122D);
    }

    return const Color(0x70F0D9A2);
  }

  Widget _buildBackground(SceneNode node) {
    return AnimatedSwitcher(
      duration: 450.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.03, end: 1).animate(curved),
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
            Container(color: Colors.black),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8A050A10),
                  Colors.transparent,
                  Color(0x66000000),
                ],
                stops: [0, 0.38, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.18),
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  Color(0x33000000),
                  Color(0xA6000000),
                ],
                stops: [0.48, 0.78, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactFlash(SceneNode node) {
    if (!_isImpactScene(node)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('impact_${node.id}'),
        tween: Tween(begin: 1, end: 0),
        duration: 500.ms,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.12),
              radius: 0.98,
              colors: [
                _impactFlashColor(node),
                Colors.transparent,
              ],
              stops: const [0, 1],
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: scenesAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.red),
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

          Widget content = Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(currentNode),
              _buildImpactFlash(currentNode),
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '시간 경과: ${gameState.timeElapsed}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 12),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Icon(
                          Icons.warning_amber_rounded,
                          color: index < gameState.dangerLevel
                              ? Colors.redAccent
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (currentNode.speaker != 'system')
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 250,
                  child: Text(
                    '[ 인물 초상: ${currentNode.speaker} ]',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 16),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 470,
                  padding: const EdgeInsets.all(24),
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
                      if (currentNode.speaker != 'system')
                        Text(
                          currentNode.speaker,
                          style: TextStyle(
                            color: _isImpactScene(currentNode)
                                ? const Color(0xFFFFC88A)
                                : Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.only(right: 4),
                        child: Scrollbar(
                          controller: _textScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _textScrollController,
                            child: AnimatedSwitcher(
                              duration: 220.ms,
                              child: Text(
                                currentNode.text,
                                key: ValueKey(currentNode.id),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.75,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (currentNode.choices.isEmpty && currentNode.nextSceneId != null)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          ),
                          onPressed: () {
                            ref.read(gameStateProvider.notifier).makeChoice(
                                  nextSceneId: currentNode.nextSceneId!,
                                );
                          },
                          child: Text(currentNode.continueText ?? '계속 읽기'),
                        ),
                      ...currentNode.choices.map(
                        (choice) {
                          final isAvailable = choice.requiredEvidence.every(currentEvidence.contains);
                          final missingText = choice.requiredEvidence.isEmpty
                              ? ''
                              : ' (필요 증거: ${choice.requiredEvidence.join(', ')})';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isImpactScene(currentNode)
                                      ? Colors.white54
                                      : Colors.white30,
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.black.withOpacity(isAvailable ? 0.14 : 0.28),
                              ),
                              onPressed: isAvailable
                                  ? () {
                                      ref.read(gameStateProvider.notifier).makeChoice(
                                            nextSceneId: choice.nextSceneId,
                                            timeCost: choice.timeCost,
                                            dangerDelta: choice.dangerDelta,
                                            newEvidence: choice.addEvidence,
                                            resetGame: choice.resetGame,
                                          );

                                      choice.trustDelta.forEach((charName, delta) {
                                        ref.read(gameStateProvider.notifier).updateTrust(charName, delta);
                                      });
                                    }
                                  : null,
                              child: Text(
                                isAvailable ? choice.text : '${choice.text}$missingText',
                                style: TextStyle(
                                  color: isAvailable ? Colors.white70 : Colors.white38,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          if (gameState.dangerLevel > 0) {
            content = content
                .animate(key: ValueKey('danger_${gameState.dangerLevel}_${currentNode.id}'))
                .shake(hz: 8, duration: 500.ms);
          }

          return content;
        },
      ),
    );
  }
}
