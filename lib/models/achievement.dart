/// A single achievement / award / certification entry stored in the vault,
/// independent of any one resume so it can be reused.
class Achievement {
  final String id;
  final String userId;
  final String title;
  final String organization;
  final String dateLabel;
  final String description;

  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    required this.organization,
    required this.dateLabel,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'organization': organization,
      'date_label': dateLabel,
      'description': description,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: (map['title'] as String?) ?? '',
      organization: (map['organization'] as String?) ?? '',
      dateLabel: (map['date_label'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
    );
  }

  Achievement copyWith({
    String? title,
    String? organization,
    String? dateLabel,
    String? description,
  }) {
    return Achievement(
      id: id,
      userId: userId,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      dateLabel: dateLabel ?? this.dateLabel,
      description: description ?? this.description,
    );
  }
}
