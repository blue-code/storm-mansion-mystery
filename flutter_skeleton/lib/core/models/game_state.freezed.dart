// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  String get currentSceneId => throw _privateConstructorUsedError;
  int get timeElapsed => throw _privateConstructorUsedError;
  int get dangerLevel => throw _privateConstructorUsedError;
  List<String> get evidence => throw _privateConstructorUsedError;
  Map<String, int> get trustMap => throw _privateConstructorUsedError;
  bool get isDead => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {String currentSceneId,
      int timeElapsed,
      int dangerLevel,
      List<String> evidence,
      Map<String, int> trustMap,
      bool isDead});
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSceneId = null,
    Object? timeElapsed = null,
    Object? dangerLevel = null,
    Object? evidence = null,
    Object? trustMap = null,
    Object? isDead = null,
  }) {
    return _then(_value.copyWith(
      currentSceneId: null == currentSceneId
          ? _value.currentSceneId
          : currentSceneId // ignore: cast_nullable_to_non_nullable
              as String,
      timeElapsed: null == timeElapsed
          ? _value.timeElapsed
          : timeElapsed // ignore: cast_nullable_to_non_nullable
              as int,
      dangerLevel: null == dangerLevel
          ? _value.dangerLevel
          : dangerLevel // ignore: cast_nullable_to_non_nullable
              as int,
      evidence: null == evidence
          ? _value.evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trustMap: null == trustMap
          ? _value.trustMap
          : trustMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isDead: null == isDead
          ? _value.isDead
          : isDead // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String currentSceneId,
      int timeElapsed,
      int dangerLevel,
      List<String> evidence,
      Map<String, int> trustMap,
      bool isDead});
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSceneId = null,
    Object? timeElapsed = null,
    Object? dangerLevel = null,
    Object? evidence = null,
    Object? trustMap = null,
    Object? isDead = null,
  }) {
    return _then(_$GameStateImpl(
      currentSceneId: null == currentSceneId
          ? _value.currentSceneId
          : currentSceneId // ignore: cast_nullable_to_non_nullable
              as String,
      timeElapsed: null == timeElapsed
          ? _value.timeElapsed
          : timeElapsed // ignore: cast_nullable_to_non_nullable
              as int,
      dangerLevel: null == dangerLevel
          ? _value.dangerLevel
          : dangerLevel // ignore: cast_nullable_to_non_nullable
              as int,
      evidence: null == evidence
          ? _value._evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as List<String>,
      trustMap: null == trustMap
          ? _value._trustMap
          : trustMap // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isDead: null == isDead
          ? _value.isDead
          : isDead // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateImpl implements _GameState {
  const _$GameStateImpl(
      {this.currentSceneId = 'scene_101',
      this.timeElapsed = 0,
      this.dangerLevel = 0,
      final List<String> evidence = const [],
      final Map<String, int> trustMap = const {},
      this.isDead = false})
      : _evidence = evidence,
        _trustMap = trustMap;

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  @override
  @JsonKey()
  final String currentSceneId;
  @override
  @JsonKey()
  final int timeElapsed;
  @override
  @JsonKey()
  final int dangerLevel;
  final List<String> _evidence;
  @override
  @JsonKey()
  List<String> get evidence {
    if (_evidence is EqualUnmodifiableListView) return _evidence;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_evidence);
  }

  final Map<String, int> _trustMap;
  @override
  @JsonKey()
  Map<String, int> get trustMap {
    if (_trustMap is EqualUnmodifiableMapView) return _trustMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_trustMap);
  }

  @override
  @JsonKey()
  final bool isDead;

  @override
  String toString() {
    return 'GameState(currentSceneId: $currentSceneId, timeElapsed: $timeElapsed, dangerLevel: $dangerLevel, evidence: $evidence, trustMap: $trustMap, isDead: $isDead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.currentSceneId, currentSceneId) ||
                other.currentSceneId == currentSceneId) &&
            (identical(other.timeElapsed, timeElapsed) ||
                other.timeElapsed == timeElapsed) &&
            (identical(other.dangerLevel, dangerLevel) ||
                other.dangerLevel == dangerLevel) &&
            const DeepCollectionEquality().equals(other._evidence, _evidence) &&
            const DeepCollectionEquality().equals(other._trustMap, _trustMap) &&
            (identical(other.isDead, isDead) || other.isDead == isDead));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentSceneId,
      timeElapsed,
      dangerLevel,
      const DeepCollectionEquality().hash(_evidence),
      const DeepCollectionEquality().hash(_trustMap),
      isDead);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(
      this,
    );
  }
}

abstract class _GameState implements GameState {
  const factory _GameState(
      {final String currentSceneId,
      final int timeElapsed,
      final int dangerLevel,
      final List<String> evidence,
      final Map<String, int> trustMap,
      final bool isDead}) = _$GameStateImpl;

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  @override
  String get currentSceneId;
  @override
  int get timeElapsed;
  @override
  int get dangerLevel;
  @override
  List<String> get evidence;
  @override
  Map<String, int> get trustMap;
  @override
  bool get isDead;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
