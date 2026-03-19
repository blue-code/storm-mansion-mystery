import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/game_state.dart';
import '../../data/models/scene_node.dart';
import '../providers/game_provider.dart';

// JSON 파일을 읽어 SceneNode 맵을 제공하는 프로바이더
final storyNodesProvider = FutureProvider<Map<String, SceneNode>>((ref) async {
  Map<String, SceneNode> sceneMap = {};

  Future<void> loadChapter(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> scenesRaw = jsonMap['scenes'];
      for (var raw in scenesRaw) {
        final node = SceneNode.fromJson(raw);
        sceneMap[node.id] = node;
      }
    } catch (e) {
      debugPrint('챕터 로드 실패 ($path): $e');
    }
  }

  // 챕터 1, 2 연속 로드 (Key 충돌이 없도록 ID를 독립적으로 구성해야 함)
  await loadChapter('assets/story/chapter1.json');
  await loadChapter('assets/story/chapter2.json');

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
  String? _currentBgm;
  String? _lastPlayedSceneId;

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
    super.dispose();
  }

  void _handleSound(SceneNode node) {
    // BGM 처리
    if (node.bgm != _currentBgm) {
      _currentBgm = node.bgm;
      if (_currentBgm != null && _currentBgm!.isNotEmpty) {
        bgmPlayer.play(AssetSource('audio/$_currentBgm.mp3'));
      } else {
        bgmPlayer.stop();
      }
    }
    
    // SFX 처리
    if (node.sfx != null && node.sfx!.isNotEmpty) {
      sfxPlayer.play(AssetSource('audio/${node.sfx}.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final scenesAsyncValue = ref.watch(storyNodesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: scenesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (err, stack) => Center(child: Text('스토리 로드 실패: $err', style: const TextStyle(color: Colors.white))),
        data: (sceneMap) {
          final currentNode = sceneMap[gameState.currentSceneId];

          if (currentNode == null) {
            return const Center(child: Text('오류: 장면을 찾을 수 없습니다.', style: TextStyle(color: Colors.white)));
          }

          // 사운드 재생 로직
          if (_lastPlayedSceneId != currentNode.id) {
            _lastPlayedSceneId = currentNode.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleSound(currentNode);
            });
          }

          Widget content = Stack(
            fit: StackFit.expand,
            children: [
              // 1. Layer: 정적 배경 이미지
              if (currentNode.backgroundImageUrl.isNotEmpty)
                ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                  child: Image.asset(
                    'assets/images/${currentNode.backgroundImageUrl}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black),
                  ),
                ),

              // 2. 상단 상태바
              Positioned(
                top: 50, left: 20, right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('시간 경과: ${gameState.timeElapsed}h', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Row(
                      children: List.generate(3, (index) => Icon(
                        Icons.warning_amber_rounded,
                        color: index < gameState.dangerLevel ? Colors.red : Colors.grey.withOpacity(0.3),
                      )),
                    )
                  ],
                ),
              ),

              // 3. 중앙 인물 스탠딩 레이어
              if (currentNode.speaker != 'system')
                Positioned(
                  bottom: 250,
                  child: Center(
                    child: Text(
                      '[ 인물 초상화: ${currentNode.speaker} ]', 
                      style: const TextStyle(color: Colors.white54, fontSize: 24, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),

              // 4. 하단 텍스트 및 선택지 박스
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 380,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                    )
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 화자 이름
                      if (currentNode.speaker != 'system')
                        Text(
                          currentNode.speaker,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
                      // 타이프라이터 적용된 본문 텍스트
                      SizedBox(
                        height: 60,
                        child: AnimatedTextKit(
                          key: ValueKey(currentNode.id),
                          animatedTexts: [
                            TypewriterAnimatedText(
                              currentNode.text,
                              textStyle: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                              speed: const Duration(milliseconds: 30),
                            ),
                          ],
                          isRepeatingAnimation: false,
                          displayFullTextOnTap: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 선택지 버튼 렌더링
                      ...currentNode.choices.map((choice) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () {
                            ref.read(gameStateProvider.notifier).makeChoice(
                              nextSceneId: choice.nextSceneId,
                              timeCost: choice.timeCost,
                              dangerDelta: choice.dangerDelta,
                              newEvidence: choice.addEvidence,
                            );
                            
                            choice.trustDelta.forEach((charName, delta) {
                              ref.read(gameStateProvider.notifier).updateTrust(charName, delta);
                            });
                          },
                          child: Text(choice.text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              )
            ],
          );

          // 카메라 흔들림 연출 (위험도가 0보다 크고, 변화가 있을 때 애니메이션 렌더링)
          if (gameState.dangerLevel > 0) {
            content = content.animate(key: ValueKey('danger_${gameState.dangerLevel}'))
               .shake(hz: 8, amount: 5, duration: 500.ms);
          }

          return content;
        },
      ),
    );
  }
}
