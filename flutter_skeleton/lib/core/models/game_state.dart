import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    @Default('scene_101') String currentSceneId,
    @Default(0) int timeElapsed,
    @Default(0) int dangerLevel,
    @Default([]) List<String> evidence,
    @Default({}) Map<String, int> trustMap,
    @Default(false) bool isDead,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);
}
