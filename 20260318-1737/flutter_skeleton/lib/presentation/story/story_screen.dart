import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/game_state.dart';
import '../../data/models/scene_node.dart';
import '../providers/game_provider.dart';

// JSON 파일을 읽어 SceneNode 맵을 제공하는 프로바이더
final storyNodesProvider = FutureProvider<Map<String, SceneNode>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/story/chapter1.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  final List<dynamic> scenesRaw = jsonMap['scenes'];
  
  Map<String, SceneNode> sceneMap = {};
  for (var raw in scenesRaw) {
    final node = SceneNode.fromJson(raw);
    sceneMap[node.id] = node;
  }
  return sceneMap;
});

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Layer: 정적 배경 이미지 (에셋 최적화 전략 적용)
              if (currentNode.backgroundImageUrl.isNotEmpty)
                ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                  child: Image.asset( // Image.network나 로컬에셋 처리
                    'assets/images/${currentNode.backgroundImageUrl}.png',
                    fit: BoxFit.cover,
                    // 실제 구현 시엔 에러 빌더 추가 필요
                    errorBuilder: (_, __, ___) => Container(color: Colors.black),
                  ),
                ),

              // 2. 상단 상태바 (위험도 및 남은 시간 표시)
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

              // 3. 중앙 인물 스탠딩 레이어 (화자가 system이 아닐 경우)
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
                  height: 350,
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
                      // 본문 텍스트 (추후 타이프라이터 효과 라이브러리 교체 추천)
                      Text(
                        currentNode.text,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      
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
                            
                            // 신뢰도 로직 추가
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
        },
      ),
    );
  }
}
