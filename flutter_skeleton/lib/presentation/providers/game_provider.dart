import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/game_state.dart';

/// SharedPreferences 인스턴스를 제공하는 프로바이더
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('앱 초기화 시점에 ProviderScope에서 override 해야 합니다.');
});

/// 게임 전체의 상태를 관장하는 최상위 Riverpod Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GameStateNotifier(prefs);
});

class GameStateNotifier extends StateNotifier<GameState> {
  final SharedPreferences prefs;
  static const String _saveKey = 'game_state_save';

  GameStateNotifier(this.prefs) : super(_loadInitialState(prefs));

  static GameState _loadInitialState(SharedPreferences prefs) {
    final savedJsonString = prefs.getString(_saveKey);
    if (savedJsonString != null && savedJsonString.isNotEmpty) {
      try {
        final decoded = json.decode(savedJsonString) as Map<String, dynamic>;
        return GameState.fromJson(decoded);
      } catch (e) {
        return const GameState();
      }
    }
    return const GameState();
  }

  void _saveState() {
    prefs.setString(_saveKey, json.encode(state.toJson()));
  }

  void resetGame() {
    state = const GameState();
    _saveState();
  }

  /// 선택지를 골랐을 때 호출되는 핵심 액션 함수
  void makeChoice({
    required String nextSceneId,
    int timeCost = 0,
    int dangerDelta = 0,
    List<String> newEvidence = const [],
  }) {
    if (state.isDead) return;

    final updatedEvidence = List<String>.from(state.evidence);
    for (var ev in newEvidence) {
      if (!updatedEvidence.contains(ev)) {
        updatedEvidence.add(ev);
      }
    }

    final newDangerLevel = state.dangerLevel + dangerDelta;
    final isNowDead = newDangerLevel >= 3;

    state = state.copyWith(
      currentSceneId: isNowDead ? 'scene_death_bad_ending' : nextSceneId,
      timeElapsed: state.timeElapsed + timeCost,
      dangerLevel: newDangerLevel,
      evidence: updatedEvidence,
      isDead: isNowDead,
    );
    
    _saveState();
  }

  /// 특정 인물의 신뢰도를 올리거나 내리는 함수
  void updateTrust(String characterName, int delta) {
    if (state.isDead) return;

    final updatedTrust = Map<String, int>.from(state.trustMap);
    final currentTrust = updatedTrust[characterName] ?? 0;
    updatedTrust[characterName] = currentTrust + delta;

    state = state.copyWith(trustMap: updatedTrust);
    _saveState();
  }
}
