import 'package:flutter_test/flutter_test.dart';

import 'package:cvora/models/resume.dart';
import 'package:cvora/utils/resume_scorer.dart';

Resume _emptyResume() {
  final now = DateTime.now();
  return Resume(
    id: '1',
    userId: 'u1',
    fullName: '',
    email: '',
    phone: '',
    location: '',
    professionalTitle: '',
    professionalSummary: '',
    resumeType: 'modern',
    template: 'template1',
    education: const [],
    experience: const [],
    skills: const [],
    projects: const [],
    achievements: const [],
    certifications: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ResumeScorer', () {
    test('an empty resume scores low and flags every missing section', () {
      final result = ResumeScorer.score(_emptyResume());

      expect(result.score, lessThan(20));
      expect(
        result.suggestions.any((s) => !s.isPositive && s.title.toLowerCase().contains('contact')),
        isTrue,
      );
    });

    test('a fully filled-out resume scores near the top', () {
      final now = DateTime.now();
      final resume = Resume(
        id: '1',
        userId: 'u1',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '555-1234',
        location: 'Cairo, Egypt',
        professionalTitle: 'Senior Backend Engineer',
        professionalSummary:
            'Backend engineer with 6 years of experience building scalable APIs '
            'and leading small teams to ship reliable, well-tested systems.',
        resumeType: 'modern',
        template: 'template1',
        education: [
          Education(
            id: 'e1',
            school: 'Cairo University',
            degree: 'B.Sc. Computer Science',
            fieldOfStudy: 'Computer Science',
            startDate: '2016',
            endDate: '2020',
            description: '',
          ),
        ],
        experience: [
          Experience(
            id: 'x1',
            jobTitle: 'Backend Engineer',
            company: 'Acme Corp',
            startDate: '2020',
            endDate: 'Present',
            description:
                'Designed and shipped microservices handling 2M+ daily requests, '
                'reducing latency by 35% through caching and query optimization.',
            isCurrentJob: true,
          ),
        ],
        skills: const ['Dart', 'Flutter', 'PostgreSQL', 'Docker', 'AWS', 'Kubernetes'],
        projects: [
          Project(
            id: 'p1',
            name: 'CVora',
            description: 'A CV and resume builder.',
            link: 'https://github.com/example/cvora',
            technologies: 'Flutter, Supabase',
            startDate: '2026',
            endDate: '',
          ),
        ],
        achievements: [
          Achievement(id: 'a1', title: 'Top Performer', description: '', date: '2024'),
        ],
        certifications: [
          Certification(
            id: 'c1',
            name: 'AWS Certified Developer',
            issuedBy: 'Amazon',
            issueDate: '2023',
            expiryDate: '',
            link: '',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final result = ResumeScorer.score(resume);
      expect(result.score, greaterThanOrEqualTo(90));
    });
  });
}
