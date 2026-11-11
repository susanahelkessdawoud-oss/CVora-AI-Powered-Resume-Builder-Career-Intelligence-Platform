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
}
