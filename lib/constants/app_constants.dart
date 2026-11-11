class AppConstants {
  // API Endpoints
  static const String apiBaseUrl = 'https://api.cvora.com';
  static const String firebaseProjectId = 'cvora-app';

  // App Info
  static const String appName = 'CVORA';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Build professional resumes and manage your career';

  // Time Constants
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Resume Limits
  static const int maxResumes = 10;
  static const int maxSkills = 30;
  static const int maxEducation = 10;
  static const int maxExperience = 20;
  static const int maxProjects = 20;
  static const int maxAchievements = 20;
  static const int maxCertifications = 20;

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorWeakPassword =
      'Password must be at least $minPasswordLength characters.';

  // Success Messages
  static const String successLogout = 'Logged out successfully.';
  static const String successProfileUpdate = 'Profile updated successfully.';
  static const String successResumeCreated = 'Resume created successfully.';
  static const String successResumeUpdated = 'Resume updated successfully.';
  static const String successResumeDeleted = 'Resume deleted successfully.';
}
