/// A single skill entry on a resume.
///
/// Kept deliberately small: models hold data and know how to serialize
/// themselves, but contain no database logic (that lives in DatabaseService).
class Skill {
  final String id;
  final String name;
  final String level; // Beginner | Intermediate | Advanced | Expert

  const Skill({
    required this.id,
    required this.name,
    required this.level,
  });

  /// Column names here match the `skills` SQLite table.
  /// `resume_id` is added by DatabaseService at save time.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as String,
      name: map['name'] as String,
      level: (map['level'] as String?) ?? 'Intermediate',
    );
  }

  Skill copyWith({String? id, String? name, String? level}) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }
}
