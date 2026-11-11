import 'package:flutter_test/flutter_test.dart';

import 'package:cvora/models/resume.dart';
import 'package:cvora/utils/job_matcher.dart';

void main() {
  group('JobMatcher', () {
    test('finds keyword overlap between resume and job description', () {
      final now = DateTime.now();
      final resume = Resume(
        id: '1',
        userId: 'u1',
        fullName: 'Jane Doe',
        email: '',
        phone: '',
        location: '',
        professionalTitle: 'Flutter Developer',
        professionalSummary: 'Experienced building cross-platform mobile apps with Flutter and Dart.',
        resumeType: 'modern',
        template: 'template1',
        education: const [],
        experience: const [],
        skills: const ['Flutter', 'Dart', 'Firebase'],
        projects: const [],
        achievements: const [],
        certifications: const [],
        createdAt: now,
        updatedAt: now,
      );

      const jobDescription =
          'We are looking for a Flutter developer experienced with Dart and '
          'Firebase to join our mobile team. Kubernetes experience is a plus.';

      final result = JobMatcher.match(resume, jobDescription);

      expect(result.matchedKeywords, contains('flutter'));
      expect(result.matchedKeywords, contains('dart'));
      expect(result.matchedKeywords, contains('firebase'));
      expect(result.missingKeywords, contains('kubernetes'));
      expect(result.matchPercent, greaterThan(0));
    });

    test('returns zero match for a completely unrelated resume', () {
      final now = DateTime.now();
      final resume = Resume(
        id: '1',
        userId: 'u1',
        fullName: 'John Smith',
        email: '',
        phone: '',
        location: '',
        professionalTitle: 'Chef',
        professionalSummary: 'Passionate about cooking and running kitchens.',
        resumeType: 'modern',
        template: 'template1',
        education: const [],
        experience: const [],
        skills: const ['Cooking', 'Menu Planning'],
        projects: const [],
        achievements: const [],
        certifications: const [],
        createdAt: now,
        updatedAt: now,
      );

      const jobDescription =
          'Seeking a backend engineer skilled in Kubernetes, PostgreSQL, and '
          'distributed systems architecture.';

      final result = JobMatcher.match(resume, jobDescription);
      expect(result.matchPercent, 0);
    });
  });
}
