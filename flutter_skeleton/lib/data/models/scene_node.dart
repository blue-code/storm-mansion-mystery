class SceneNode {
  final String id;
  final String backgroundImageUrl;
  final String speaker;
  final String text;
  final String? bgm;
  final String? sfx;
  final List<ChoiceNode> choices;

  SceneNode({
    required this.id,
    required this.backgroundImageUrl,
    required this.speaker,
    required this.text,
    this.bgm,
    this.sfx,
    required this.choices,
  });

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    return SceneNode(
      id: json['id'] as String,
      backgroundImageUrl: json['background_image'] as String? ?? '',
      speaker: json['speaker'] as String? ?? 'system',
      text: json['text'] as String,
      bgm: json['bgm'] as String?,
      sfx: json['sfx'] as String?,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ChoiceNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChoiceNode {
  final String text;
  final String nextSceneId;
  final int timeCost;
  final int dangerDelta;
  final List<String> addEvidence;
  final Map<String, int> trustDelta;

  ChoiceNode({
    required this.text,
    required this.nextSceneId,
    this.timeCost = 0,
    this.dangerDelta = 0,
    this.addEvidence = const [],
    this.trustDelta = const {},
  });

  factory ChoiceNode.fromJson(Map<String, dynamic> json) {
    final effects = json['effects'] as Map<String, dynamic>? ?? {};
    final evidenceList = effects['add_evidence'] as List<dynamic>? ?? [];
    final trustMap = effects['trust_delta'] as Map<String, dynamic>? ?? {};

    return ChoiceNode(
      text: json['text'] as String,
      nextSceneId: json['next_scene_id'] as String,
      timeCost: effects['time_cost'] as int? ?? 0,
      dangerDelta: effects['danger_delta'] as int? ?? 0,
      addEvidence: evidenceList.map((e) => e.toString()).toList(),
      trustDelta: trustMap.map((key, value) => MapEntry(key, value as int)),
    );
  }
}
