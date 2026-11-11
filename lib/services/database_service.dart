import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/resume.dart';

/// Persists [Resume] documents in the Supabase `resumes` table.
///
/// Each row keeps a few real columns for filtering/sorting (`user_id`,
/// `document_type`, `full_name`, timestamps) plus the full resume payload
/// in a `data` jsonb column, so the Dart model can evolve without a
/// migration for every new field. See `supabase/schema.sql` for the DDL.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  static const String _table = 'resumes';

  SupabaseClient get _client => Supabase.instance.client;

  Resume _fromRow(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(
      (row['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    data['id'] = row['id'];
    data['userId'] = row['user_id'];
    data['createdAt'] = row['created_at'];
    data['updatedAt'] = row['updated_at'];
    return Resume.fromJson(data);
  }

  Map<String, dynamic> _toRow(Resume resume) {
    return {
      'user_id': resume.userId,
      'document_type': resume.documentType,
      'full_name': resume.fullName,
      'data': resume.toJson(),
    };
  }

  // Create resume, returns the generated id
  Future<String> createResume(Resume resume) async {
    try {
      final row = await _client
          .from(_table)
          .insert(_toRow(resume))
          .select()
          .single();
      return row['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  // Get all resumes for a user, most recently updated first
  Future<List<Resume>> getResumes(String userId) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return rows.map((row) => _fromRow(row)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get single resume
  Future<Resume?> getResume(String resumeId) async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', resumeId)
          .maybeSingle();
      if (row == null) return null;
      return _fromRow(row);
    } catch (e) {
      rethrow;
    }
  }

  // Update resume
  Future<void> updateResume(String resumeId, Resume resume) async {
    try {
      await _client.from(_table).update(_toRow(resume)).eq('id', resumeId);
    } catch (e) {
      rethrow;
    }
  }

  // Delete resume
  Future<void> deleteResume(String resumeId, String userId) async {
    try {
      await _client
          .from(_table)
          .delete()
          .eq('id', resumeId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // --- Achievement Vault ---
  // A personal, reusable pool of achievements the user can draw from when
  // building any CV/Resume, independent of the resume-embedded ones.
  static const String _achievementsTable = 'achievements';

  Achievement _achievementFromRow(Map<String, dynamic> row) {
    return Achievement(
      id: row['id'] as String,
      title: row['title'] ?? '',
      description: row['description'] ?? '',
      date: row['date'] ?? '',
    );
  }

  Future<List<Achievement>> getVaultAchievements(String userId) async {
    try {
      final rows = await _client
          .from(_achievementsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map((row) => _achievementFromRow(row)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> addVaultAchievement(
    String userId,
    Achievement achievement,
  ) async {
    try {
      final row = await _client
          .from(_achievementsTable)
          .insert({
            'user_id': userId,
            'title': achievement.title,
            'description': achievement.description,
            'date': achievement.date,
          })
          .select()
          .single();
      return _achievementFromRow(row);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVaultAchievement(Achievement achievement) async {
    try {
      await _client
          .from(_achievementsTable)
          .update({
            'title': achievement.title,
            'description': achievement.description,
            'date': achievement.date,
          })
          .eq('id', achievement.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVaultAchievement(String id, String userId) async {
    try {
      await _client
          .from(_achievementsTable)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
