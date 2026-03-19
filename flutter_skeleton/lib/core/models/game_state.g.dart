// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      currentSceneId: json['currentSceneId'] as String? ?? 'scene_101',
      timeElapsed: (json['timeElapsed'] as num?)?.toInt() ?? 0,
      dangerLevel: (json['dangerLevel'] as num?)?.toInt() ?? 0,
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trustMap: (json['trustMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      isDead: json['isDead'] as bool? ?? false,
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'currentSceneId': instance.currentSceneId,
      'timeElapsed': instance.timeElapsed,
      'dangerLevel': instance.dangerLevel,
      'evidence': instance.evidence,
      'trustMap': instance.trustMap,
      'isDead': instance.isDead,
    };
