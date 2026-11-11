/// A work experience entry.
class Experience {
  final String id;
  final String company;
  final String position;
  final String description;
  final String startDate;
  final String endDate;
  final bool isCurrent;

  const Experience({
    required this.id,
    required this.company,
    required this.position,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  /// Human-readable date range for previews, e.g. "2023 – Present".
  String get dateRange {
    final end = isCurrent ? 'Present' : (endDate.isEmpty ? '' : endDate);
    if (startDate.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return startDate;
    return '$startDate – $end';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent ? 1 : 0,
    };
  }

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      id: map['id'] as String,
      company: (map['company'] as String?) ?? '',
      position: (map['position'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      startDate: (map['start_date'] as String?) ?? '',
      endDate: (map['end_date'] as String?) ?? '',
      isCurrent: (map['is_current'] as int?) == 1,
    );
  }

  Experience copyWith({
    String? id,
    String? company,
    String? position,
    String? description,
    String? startDate,
    String? endDate,
    bool? isCurrent,
  }) {
    return Experience(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
