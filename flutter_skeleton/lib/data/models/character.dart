class CharacterProfile {
  final String name;
  final int age;
  final String description;
  final String note;

  CharacterProfile({
    required this.name,
    required this.age,
    required this.description,
    required this.note,
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    return CharacterProfile(
      name: json['name'] as String,
      age: json['age'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}
