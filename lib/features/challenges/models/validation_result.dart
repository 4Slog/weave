import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'challenge_model.dart';

/// Enhanced model for challenge validation results with educational feedback.
///
/// This model represents the result of validating a user's solution to a challenge,
/// including detailed educational feedback and assessment.
class ValidationResult {
  /// Whether the solution meets the success criteria.
  final bool success;

  /// The challenge that was validated.
  final ChallengeModel challenge;

  /// The user's solution.
  final PatternModel solution;

  /// Feedback for the user.
  final ValidationFeedback feedback;

  /// Assessment of the solution against the rubric.
  final SolutionAssessment assessment;

  /// Specific issues with the solution.
  final List<ValidationIssue> issues;

  /// Achievements unlocked by this solution.
  final List<Achievement> achievements;

  /// Skills demonstrated by this solution.
  final Map<String, double> skillsDemonstrated;

  /// Educational standards demonstrated by this solution.
  final List<String> standardsDemonstrated;

  /// Create a new ValidationResult.
  ValidationResult({
    required this.success,
    required this.challenge,
    required this.solution,
    required this.feedback,
    required this.assessment,
    this.issues = const [],
    this.achievements = const [],
    this.skillsDemonstrated = const {},
    this.standardsDemonstrated = const [],
  });

  /// Create a ValidationResult from a JSON map.
  factory ValidationResult.fromJson(
    Map<String, dynamic> json,
    ChallengeModel challenge,
    PatternModel solution
  ) {
    return ValidationResult(
      success: json['success'] as bool,
      challenge: challenge,
      solution: solution,
      feedback: ValidationFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
      assessment: SolutionAssessment.fromJson(json['assessment'] as Map<String, dynamic>),
      issues: (json['issues'] as List<dynamic>?)
          ?.map((e) => ValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      skillsDemonstrated: (json['skillsDemonstrated'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
      standardsDemonstrated: (json['standardsDemonstrated'] as List<dynamic>?)
          ?.cast<String>() ?? [],
    );
  }

  /// Convert this ValidationResult to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'challengeId': challenge.id,
      'solutionId': solution.id,
      'feedback': feedback.toJson(),
      'assessment': assessment.toJson(),
      'issues': issues.map((e) => e.toJson()).toList(),
      'achievements': achievements.map((e) => e.toJson()).toList(),
      'skillsDemonstrated': skillsDemonstrated,
      'standardsDemonstrated': standardsDemonstrated,
    };
  }

  /// Get the achievement level of the solution.
  String get achievementLevel => assessment.achievementLevel;

  /// Get the total points earned for this solution.
  int get pointsEarned => assessment.pointsEarned;

  /// Check if the solution demonstrates a specific skill.
  bool demonstratesSkill(String skillId) {
    return skillsDemonstrated.containsKey(skillId);
  }

  /// Get the skill level demonstrated for a specific skill.
  double getSkillLevel(String skillId) {
    return skillsDemonstrated[skillId] ?? 0.0;
  }

  /// Check if the solution demonstrates a specific standard.
  bool demonstratesStandard(String standardId) {
    return standardsDemonstrated.contains(standardId);
  }

  /// Get a list of missing block types.
  List<String> get missingBlockTypes {
    return issues
        .where((issue) => issue.type == 'missing_block_type')
        .map((issue) => issue.details['blockType'] as String)
        .toList();
  }

  /// Get the connection count.
  int get connectionCount {
    final connectionIssue = issues.firstWhere(
      (issue) => issue.type == 'insufficient_connections',
      orElse: () => ValidationIssue(
        type: 'connection_info',
        message: 'Connection information',
        details: {'connectionCount': solution.connectionCount},
      ),
    );

    return connectionIssue.details['connectionCount'] as int? ?? solution.connectionCount;
  }

  /// Get the required connection count.
  int get requiredConnectionCount {
    final connectionIssue = issues.firstWhere(
      (issue) => issue.type == 'insufficient_connections',
      orElse: () => ValidationIssue(
        type: 'connection_info',
        message: 'Connection information',
        details: {'requiredConnectionCount': challenge.successCriteria.minConnections},
      ),
    );

    return connectionIssue.details['requiredConnectionCount'] as int? ??
           challenge.successCriteria.minConnections;
  }
}

/// Model for validation feedback.
class ValidationFeedback {
  /// Title of the feedback.
  final String title;

  /// Main feedback message.
  final String message;

  /// Detailed explanation of the feedback.
  final String details;

  /// Suggestions for improvement.
  final List<String> suggestions;

  /// Educational context of the feedback.
  final String educationalContext;

  /// Create a new ValidationFeedback.
  ValidationFeedback({
    required this.title,
    required this.message,
    this.details = '',
    this.suggestions = const [],
    this.educationalContext = '',
  });

  /// Create a ValidationFeedback from a JSON map.
  factory ValidationFeedback.fromJson(Map<String, dynamic> json) {
    return ValidationFeedback(
      title: json['title'] as String,
      message: json['message'] as String,
      details: json['details'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? [],
      educationalContext: json['educationalContext'] as String? ?? '',
    );
  }

  /// Convert this ValidationFeedback to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'details': details,
      'suggestions': suggestions,
      'educationalContext': educationalContext,
    };
  }
}

/// Model for solution assessment.
class SolutionAssessment {
  /// Achievement level of the solution (basic, proficient, advanced).
  final String achievementLevel;

  /// Points earned for this solution.
  final int pointsEarned;

  /// Criteria met at each achievement level.
  final Map<String, List<String>> criteriaMet;

  /// Create a new SolutionAssessment.
  SolutionAssessment({
    required this.achievementLevel,
    required this.pointsEarned,
    this.criteriaMet = const {},
  });

  /// Create a SolutionAssessment from a JSON map.
  factory SolutionAssessment.fromJson(Map<String, dynamic> json) {
    return SolutionAssessment(
      achievementLevel: json['achievementLevel'] as String,
      pointsEarned: json['pointsEarned'] as int,
      criteriaMet: (json['criteriaMet'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ) ?? {},
    );
  }

  /// Convert this SolutionAssessment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'achievementLevel': achievementLevel,
      'pointsEarned': pointsEarned,
      'criteriaMet': criteriaMet,
    };
  }

  /// Get criteria met at a specific achievement level.
  List<String> getCriteriaMet(String level) {
    return criteriaMet[level] ?? [];
  }
}

/// Model for validation issues.
class ValidationIssue {
  /// Type of issue (e.g., 'missing_block_type', 'insufficient_connections').
  final String type;

  /// Human-readable message describing the issue.
  final String message;

  /// Additional details about the issue.
  final Map<String, dynamic> details;

  /// Severity of the issue (info, warning, error).
  final String severity;

  /// Create a new ValidationIssue.
  ValidationIssue({
    required this.type,
    required this.message,
    this.details = const {},
    this.severity = 'warning',
  });

  /// Create a ValidationIssue from a JSON map.
  factory ValidationIssue.fromJson(Map<String, dynamic> json) {
    return ValidationIssue(
      type: json['type'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      severity: json['severity'] as String? ?? 'warning',
    );
  }

  /// Convert this ValidationIssue to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'details': details,
      'severity': severity,
    };
  }
}

/// Model for achievements.
class Achievement {
  /// Unique identifier for the achievement.
  final String id;

  /// Display name of the achievement.
  final String name;

  /// Description of the achievement.
  final String description;

  /// Points earned for this achievement.
  final int points;

  /// Type of achievement (e.g., 'challenge', 'skill', 'milestone').
  final String type;

  /// Create a new Achievement.
  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.type,
  });

  /// Create an Achievement from a JSON map.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      type: json['type'] as String,
    );
  }

  /// Convert this Achievement to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'type': type,
    };
  }
}
