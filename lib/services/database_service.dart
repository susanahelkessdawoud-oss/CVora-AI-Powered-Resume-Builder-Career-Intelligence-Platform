import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/interview.dart';
import '../models/resume.dart';

/// Persists [Resume] documents (and related collections) in Cloud
/// Firestore. Each resume document stores the full [Resume.toJson] map
/// directly — Firestore handles nested maps/arrays natively, so there's no
/// need for the jsonb-blob-plus-columns split a relational database needs.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String _resumesCollection = 'resumes';
  static const String _achievementsCollection = 'achievements';
  static const String _interviewSessionsCollection = 'interview_sessions';
  static const String _interviewAnswersCollection = 'interview_answers';

  Resume _resumeFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return Resume.fromJson(data);
  }

  // Create resume, returns the generated id
  Future<String> createResume(Resume resume) async {
    try {
      final docRef =
          await _db.collection(_resumesCollection).add(resume.toJson());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all resumes for a user, most recently updated first
  Future<List<Resume>> getResumes(String userId) async {
    try {
      final snapshot = await _db
          .collection(_resumesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map(_resumeFromDoc).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get single resume
  Future<Resume?> getResume(String resumeId) async {
    try {
      final doc =
          await _db.collection(_resumesCollection).doc(resumeId).get();
      if (!doc.exists) return null;
      return _resumeFromDoc(doc);
    } catch (e) {
      rethrow;
    }
  }

  // Update resume
  Future<void> updateResume(String resumeId, Resume resume) async {
    try {
      await _db
          .collection(_resumesCollection)
          .doc(resumeId)
          .set(resume.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Delete resume
  Future<void> deleteResume(String resumeId, String userId) async {
    try {
      await _db.collection(_resumesCollection).doc(resumeId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- Achievement Vault ---
  // A personal, reusable pool of achievements the user can draw from when
  // building any CV/Resume, independent of the resume-embedded ones.

  Achievement _achievementFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Achievement(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      date: (data['date'] as String?) ?? '',
    );
  }

  Future<List<Achievement>> getVaultAchievements(String userId) async {
    try {
      final snapshot = await _db
          .collection(_achievementsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map(_achievementFromDoc).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> addVaultAchievement(
    String userId,
    Achievement achievement,
  ) async {
    try {
      final docRef = await _db.collection(_achievementsCollection).add({
        'userId': userId,
        'title': achievement.title,
        'description': achievement.description,
        'date': achievement.date,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return Achievement(
        id: docRef.id,
        title: achievement.title,
        description: achievement.description,
        date: achievement.date,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVaultAchievement(Achievement achievement) async {
    try {
      await _db.collection(_achievementsCollection).doc(achievement.id).update({
        'title': achievement.title,
        'description': achievement.description,
        'date': achievement.date,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVaultAchievement(String id, String userId) async {
    try {
      await _db.collection(_achievementsCollection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- AI Interview Coach ---

  Future<InterviewSession> createInterviewSession({
    required String userId,
    String? resumeId,
    required String jobDescription,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _db.collection(_interviewSessionsCollection).add({
        'userId': userId,
        'resumeId': resumeId,
        'jobDescription': jobDescription,
        'createdAt': now.toIso8601String(),
      });
      return InterviewSession(
        id: docRef.id,
        userId: userId,
        resumeId: resumeId,
        jobDescription: jobDescription,
        createdAt: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<InterviewSession>> getInterviewSessions(String userId) async {
    try {
      final snapshot = await _db
          .collection(_interviewSessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InterviewSession(
          id: doc.id,
          userId: (data['userId'] as String?) ?? userId,
          resumeId: data['resumeId'] as String?,
          jobDescription: (data['jobDescription'] as String?) ?? '',
          createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<InterviewAnswer> addInterviewAnswer({
    required String sessionId,
    required String userId,
    required String question,
    required String questionType,
    required String answer,
    required String feedback,
    int? score,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _db.collection(_interviewAnswersCollection).add({
        'sessionId': sessionId,
        'userId': userId,
        'question': question,
        'questionType': questionType,
        'answer': answer,
        'feedback': feedback,
        'score': score,
        'createdAt': now.toIso8601String(),
      });
      return InterviewAnswer(
        id: docRef.id,
        sessionId: sessionId,
        question: question,
        questionType: questionType,
        answer: answer,
        feedback: feedback,
        score: score,
        createdAt: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<InterviewAnswer>> getInterviewAnswers(String sessionId) async {
    try {
      final snapshot = await _db
          .collection(_interviewAnswersCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InterviewAnswer(
          id: doc.id,
          sessionId: (data['sessionId'] as String?) ?? sessionId,
          question: (data['question'] as String?) ?? '',
          questionType: (data['questionType'] as String?) ?? 'behavioral',
          answer: (data['answer'] as String?) ?? '',
          feedback: (data['feedback'] as String?) ?? '',
          score: (data['score'] as num?)?.toInt(),
          createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
