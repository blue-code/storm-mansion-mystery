import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/game_state.dart';
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
    Set<String> currentEvidence,
  ) {
    final isImpact = _isImpactScene(currentNode);
    final borderColor = isImpact
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
                            child: AnimatedSwitcher(
                              duration: 250.ms,
                              child: Text(
                                currentNode.text,
                                key: ValueKey(currentNode.id),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.8,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black87, blurRadius: 8),
                                  ],
                                ),
                              ),
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
                              Container(
                                width: 16,
                                height: 1,
                                color: Colors.white24,
                              ),
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
                              Expanded(
                                child: Container(height: 1, color: Colors.white12),
                              ),
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

          return content;
        },
      ),
    );
  }
}
