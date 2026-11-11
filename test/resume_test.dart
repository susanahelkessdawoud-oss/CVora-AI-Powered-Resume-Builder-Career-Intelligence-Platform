import 'package:cvora/models/education.dart';
import 'package:cvora/models/experience.dart';
import 'package:cvora/models/resume.dart';
import 'package:cvora/models/skill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Resume completion score', () {
    test('empty resume scores 0', () {
      final resume = Resume.create('user-1');
      expect(resume.completionScore, 0);
      expect(resume.scoreLabel, 'Getting started');
    });

    test('score rises as sections are filled', () {
      var resume = Resume.create('user-1').copyWith(
        fullName: 'Ada Lovelace', // 15
        email: 'ada@example.com', // 10
      );
      expect(resume.completionScore, 25);

      resume = resume.copyWith(
        jobTitle: 'Engineer', // 10
        summary: 'Builds things.', // 15
        skills: [
          const Skill(id: '1', name: 'Dart', level: 'Advanced'),
          const Skill(id: '2', name: 'Flutter', level: 'Advanced'),
          const Skill(id: '3', name: 'SQL', level: 'Intermediate'),
        ], // 15
      );
      expect(resume.completionScore, 65);
      expect(resume.scoreLabel, 'Good');
    });
  });

  group('Serialization round-trips', () {
    test('Resume toMap/fromMap preserves core fields', () {
      final original = Resume.create('user-1').copyWith(
        fullName: 'Grace Hopper',
        jobTitle: 'Rear Admiral',
        email: 'grace@navy.mil',
      );

      final restored = Resume.fromMap(original.toMap());
      expect(restored.fullName, 'Grace Hopper');
      expect(restored.jobTitle, 'Rear Admiral');
      expect(restored.email, 'grace@navy.mil');
      expect(restored.id, original.id);
    });

    test('Experience round-trips including isCurrent flag', () {
      const exp = Experience(
        id: 'e1',
        company: 'ACME',
        position: 'Developer',
        description: 'Wrote code.',
        startDate: '2023',
        endDate: '',
        isCurrent: true,
      );
      final restored = Experience.fromMap(exp.toMap());
      expect(restored.company, 'ACME');
      expect(restored.isCurrent, true);
      expect(restored.dateRange, '2023 – Present');
    });

    test('Education round-trips year fields', () {
      const edu = Education(
        id: 'ed1',
        institution: 'MIT',
        degree: 'BSc',
        field: 'CS',
        startYear: 2020,
        endYear: 2024,
      );
      final restored = Education.fromMap(edu.toMap());
      expect(restored.startYear, 2020);
      expect(restored.yearRange, '2020 – 2024');
    });
  });
}
