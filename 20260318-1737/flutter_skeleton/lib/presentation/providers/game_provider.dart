import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/game_state.dart';

/// 게임 전체의 상태를 관장하는 최상위 Riverpod Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  /// 선택지를 골랐을 때 호출되는 핵심 액션 함수
  void makeChoice({
    required String nextSceneId,
    int timeCost = 0,
    int dangerDelta = 0,
    List<String> newEvidence = const [],
  }) {
    // 1. 이미 죽었으면 동작 안함
    if (state.isDead) return;

    // 2. 새로운 단서(Set) 합치기
    final updatedEvidence = List<String>.from(state.evidence);
    for (var ev in newEvidence) {
      if (!updatedEvidence.contains(ev)) {
        updatedEvidence.add(ev);
      }
    }

    // 3. 위험도 갱신 (위험도가 3 이상 누적되면 사망 플래그 On)
    final newDangerLevel = state.dangerLevel + dangerDelta;
    final isNowDead = newDangerLevel >= 3;

    // 4. StateNotifier 상태 업데이트
    state = state.copyWith(
      currentSceneId: isNowDead ? 'scene_death_bad_ending' : nextSceneId,
      timeElapsed: state.timeElapsed + timeCost,
      dangerLevel: newDangerLevel,
      evidence: updatedEvidence,
      isDead: isNowDead,
    );
  }

  /// 특정 인물의 신뢰도를 올리거나 내리는 함수
  void updateTrust(String characterName, int delta) {
    if (state.isDead) return;

    final updatedTrust = Map<String, int>.from(state.trustMap);
    final currentTrust = updatedTrust[characterName] ?? 0;
    updatedTrust[characterName] = currentTrust + delta;

    state = state.copyWith(trustMap: updatedTrust);
  }
}
