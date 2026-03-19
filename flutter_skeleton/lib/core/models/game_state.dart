// Freezed 플러그인 필요
// flutter pub add freezed_annotation
// flutter pub add dev:build_runner dev:freezed
import 'package:freezed_annotation/freezed_annotation.dart';

// part 'game_state.freezed.dart';

@freezed
class GameState {
  // 실제 환경에서는 = _GameState; 로 빌드러너를 사용합니다.
  // 코드 검증용으로 기본 생성자를 열어둡니다.
  final String currentSceneId;
  final int timeElapsed;
  final int dangerLevel;
  final List<String> evidence;
  final Map<String, int> trustMap;
  final bool isDead;

  const GameState({
    this.currentSceneId = 'scene_101',
    this.timeElapsed = 0,
    this.dangerLevel = 0,
    this.evidence = const [],
    this.trustMap = const {},
    this.isDead = false,
  });

  // 로컬 저장소(SharedPreferences, Hive) 저장을 위한 직렬화(JSON) 코드
  Map<String, dynamic> toJson() {
    return {
      'currentSceneId': currentSceneId,
      'timeElapsed': timeElapsed,
      'dangerLevel': dangerLevel,
      'evidence': evidence,
      'trustMap': trustMap,
      'isDead': isDead,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      currentSceneId: json['currentSceneId'] as String? ?? 'scene_101',
      timeElapsed: json['timeElapsed'] as int? ?? 0,
      dangerLevel: json['dangerLevel'] as int? ?? 0,
      evidence: (json['evidence'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      trustMap: (json['trustMap'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? const {},
      isDead: json['isDead'] as bool? ?? false,
    );
  }

  GameState copyWith({
    String? currentSceneId,
    int? timeElapsed,
    int? dangerLevel,
    List<String>? evidence,
    Map<String, int>? trustMap,
    bool? isDead,
  }) {
    return GameState(
      currentSceneId: currentSceneId ?? this.currentSceneId,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      evidence: evidence ?? this.evidence,
      trustMap: trustMap ?? this.trustMap,
      isDead: isDead ?? this.isDead,
    );
  }
}
