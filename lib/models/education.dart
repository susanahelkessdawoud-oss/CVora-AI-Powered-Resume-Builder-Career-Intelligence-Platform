/// An education entry.
class Education {
  final String id;
  final String institution;
  final String degree;
  final String field;
  final int? startYear;
  final int? endYear;

  const Education({
    required this.id,
    required this.institution,
    required this.degree,
    required this.field,
    this.startYear,
    this.endYear,
  });

  String get yearRange {
    if (startYear == null && endYear == null) return '';
    if (endYear == null) return '$startYear';
    if (startYear == null) return '$endYear';
    return '$startYear – $endYear';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'field': field,
      'start_year': startYear,
      'end_year': endYear,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] as String,
      institution: (map['institution'] as String?) ?? '',
      degree: (map['degree'] as String?) ?? '',
      field: (map['field'] as String?) ?? '',
      startYear: map['start_year'] as int?,
      endYear: map['end_year'] as int?,
    );
  }

  Education copyWith({
    String? id,
    String? institution,
    String? degree,
    String? field,
    int? startYear,
    int? endYear,
  }) {
    return Education(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      field: field ?? this.field,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
    );
  }
}
