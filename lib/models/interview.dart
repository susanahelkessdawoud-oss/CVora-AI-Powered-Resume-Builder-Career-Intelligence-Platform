class InterviewSession {
  final String id;
  final String userId;
  final String? resumeId;
  final String jobDescription;
  final DateTime createdAt;

  InterviewSession({
    required this.id,
    required this.userId,
    this.resumeId,
    required this.jobDescription,
    required this.createdAt,
  });

  factory InterviewSession.fromRow(Map<String, dynamic> row) {
    return InterviewSession(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      resumeId: row['resume_id'] as String?,
      jobDescription: (row['job_description'] as String?) ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

class InterviewAnswer {
  final String id;
  final String sessionId;
  final String question;
  final String questionType;
  final String answer;
  final String feedback;
  final int? score;
  final DateTime createdAt;

  InterviewAnswer({
    required this.id,
    required this.sessionId,
    required this.question,
    required this.questionType,
    required this.answer,
    required this.feedback,
    this.score,
    required this.createdAt,
  });

  factory InterviewAnswer.fromRow(Map<String, dynamic> row) {
    return InterviewAnswer(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      question: (row['question'] as String?) ?? '',
      questionType: (row['question_type'] as String?) ?? 'behavioral',
      answer: (row['answer'] as String?) ?? '',
      feedback: (row['feedback'] as String?) ?? '',
      score: (row['score'] as num?)?.toInt(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
