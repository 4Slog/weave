import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';

/// Represents a real-time learning session with performance metrics
///
/// This model tracks user performance during an active learning session,
/// enabling real-time adaptation and difficulty adjustment.
class LearningSession {
  /// Unique identifier for the session
  final String sessionId;

  /// User ID associated with this session
  final String userId;

  /// When the session started
  final DateTime startTime;

  /// When the session ended (null if still active)
  final DateTime? endTime;

  /// Total time spent in minutes
  final int timeSpentMinutes;

  /// Number of challenges attempted
  final int challengesAttempted;

  /// Number of challenges completed successfully
  final int challengesCompleted;

  /// Number of hints requested
  final int hintsRequested;

  /// Number of errors made
  final int errorsMade;

  /// Current engagement score (0.0 to 1.0)
  final double engagementScore;

  /// Current frustration level (0.0 to 1.0)
  final double frustrationLevel;

  /// Current mastery level (0.0 to 1.0)
  final double masteryLevel;

  /// Learning path type for this session
  final LearningPathType learningPathType;

  /// Current difficulty level (1 to 5)
  final int difficultyLevel;

  /// Detailed performance metrics
  final Map<String, dynamic> performanceMetrics;

  /// History of actions in this session
  final List<Map<String, dynamic>> actionHistory;

  /// Create a learning session
  LearningSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.timeSpentMinutes = 0,
    this.challengesAttempted = 0,
    this.challengesCompleted = 0,
    this.hintsRequested = 0,
    this.errorsMade = 0,
    this.engagementScore = 0.5,
    this.frustrationLevel = 0.0,
    this.masteryLevel = 0.0,
    required this.learningPathType,
    this.difficultyLevel = 1,
    this.performanceMetrics = const {},
    this.actionHistory = const [],
  });

  /// Create a new learning session
  factory LearningSession.start({
    required String userId,
    required LearningPathType learningPathType,
    int initialDifficulty = 1,
  }) {
    return LearningSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      startTime: DateTime.now(),
      learningPathType: learningPathType,
      difficultyLevel: initialDifficulty,
      performanceMetrics: {},
      actionHistory: [],
    );
  }

  /// Create a learning session from a map
  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      sessionId: map['sessionId'] as String,
      userId: map['userId'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      timeSpentMinutes: map['timeSpentMinutes'] as int? ?? 0,
      challengesAttempted: map['challengesAttempted'] as int? ?? 0,
      challengesCompleted: map['challengesCompleted'] as int? ?? 0,
      hintsRequested: map['hintsRequested'] as int? ?? 0,
      errorsMade: map['errorsMade'] as int? ?? 0,
      engagementScore: map['engagementScore'] as double? ?? 0.5,
      frustrationLevel: map['frustrationLevel'] as double? ?? 0.0,
      masteryLevel: map['masteryLevel'] as double? ?? 0.0,
      learningPathType: LearningPathType.values.firstWhere(
        (type) => type.toString().split('.').last == map['learningPathType'],
        orElse: () => LearningPathType.logicBased,
      ),
      difficultyLevel: map['difficultyLevel'] as int? ?? 1,
      performanceMetrics: Map<String, dynamic>.from(map['performanceMetrics'] ?? {}),
      actionHistory: List<Map<String, dynamic>>.from(
        (map['actionHistory'] as List<dynamic>? ?? []).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      ),
    );
  }

  /// Convert this learning session to a map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'timeSpentMinutes': timeSpentMinutes,
      'challengesAttempted': challengesAttempted,
      'challengesCompleted': challengesCompleted,
      'hintsRequested': hintsRequested,
      'errorsMade': errorsMade,
      'engagementScore': engagementScore,
      'frustrationLevel': frustrationLevel,
      'masteryLevel': masteryLevel,
      'learningPathType': learningPathType.toString().split('.').last,
      'difficultyLevel': difficultyLevel,
      'performanceMetrics': performanceMetrics,
      'actionHistory': actionHistory,
    };
  }

  /// Create a copy with updated fields
  LearningSession copyWith({
    String? sessionId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? timeSpentMinutes,
    int? challengesAttempted,
    int? challengesCompleted,
    int? hintsRequested,
    int? errorsMade,
    double? engagementScore,
    double? frustrationLevel,
    double? masteryLevel,
    LearningPathType? learningPathType,
    int? difficultyLevel,
    Map<String, dynamic>? performanceMetrics,
    List<Map<String, dynamic>>? actionHistory,
  }) {
    return LearningSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      challengesAttempted: challengesAttempted ?? this.challengesAttempted,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      hintsRequested: hintsRequested ?? this.hintsRequested,
      errorsMade: errorsMade ?? this.errorsMade,
      engagementScore: engagementScore ?? this.engagementScore,
      frustrationLevel: frustrationLevel ?? this.frustrationLevel,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      learningPathType: learningPathType ?? this.learningPathType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      actionHistory: actionHistory ?? this.actionHistory,
    );
  }

  /// Record a challenge attempt
  LearningSession recordChallengeAttempt({
    required bool successful,
    int? difficultyLevel,
    int? timeSpentSeconds,
    int? errorsCount,
    int? hintsUsed,
  }) {
    // Create a copy of action history
    final newActionHistory = List<Map<String, dynamic>>.from(actionHistory);

    // Add new action
    newActionHistory.add({
      'type': 'challenge_attempt',
      'timestamp': DateTime.now().toIso8601String(),
      'successful': successful,
      'difficultyLevel': difficultyLevel ?? this.difficultyLevel,
      'timeSpentSeconds': timeSpentSeconds,
      'errorsCount': errorsCount,
      'hintsUsed': hintsUsed,
    });

    // Calculate new metrics
    final newChallengesAttempted = challengesAttempted + 1;
    final newChallengesCompleted = successful ? challengesCompleted + 1 : challengesCompleted;
    final newErrorsMade = errorsMade + (errorsCount ?? 0);
    final newHintsRequested = hintsRequested + (hintsUsed ?? 0);

    // Calculate new time spent
    final newTimeSpent = timeSpentMinutes + ((timeSpentSeconds ?? 0) / 60).round();

    // Calculate new engagement score
    double newEngagementScore = engagementScore;
    if (successful) {
      // Success increases engagement
      newEngagementScore = (newEngagementScore + 0.1).clamp(0.0, 1.0);
    } else {
      // Failure slightly decreases engagement
      newEngagementScore = (newEngagementScore - 0.05).clamp(0.0, 1.0);
    }

    // Calculate new frustration level
    double newFrustrationLevel = frustrationLevel;
    if (successful) {
      // Success decreases frustration
      newFrustrationLevel = (newFrustrationLevel - 0.2).clamp(0.0, 1.0);
    } else {
      // Failure increases frustration
      newFrustrationLevel = (newFrustrationLevel + 0.1).clamp(0.0, 1.0);

      // More hints or errors increase frustration further
      if ((errorsCount ?? 0) > 3) {
        newFrustrationLevel = (newFrustrationLevel + 0.1).clamp(0.0, 1.0);
      }
      if ((hintsUsed ?? 0) > 2) {
        newFrustrationLevel = (newFrustrationLevel + 0.05).clamp(0.0, 1.0);
      }
    }

    // Calculate new mastery level
    double newMasteryLevel = masteryLevel;
    if (successful) {
      // Success increases mastery
      final difficultyFactor = ((difficultyLevel ?? this.difficultyLevel) / 5.0) * 0.2;
      newMasteryLevel = (newMasteryLevel + difficultyFactor).clamp(0.0, 1.0);
    }

    // Calculate new difficulty level based on performance
    int newDifficultyLevel = difficultyLevel ?? this.difficultyLevel;
    if (successful && newFrustrationLevel < 0.3) {
      // If successful and not frustrated, consider increasing difficulty
      if (newMasteryLevel > 0.7) {
        newDifficultyLevel = (newDifficultyLevel + 1).clamp(1, 5);
      }
    } else if (!successful && newFrustrationLevel > 0.6) {
      // If unsuccessful and frustrated, decrease difficulty
      newDifficultyLevel = (newDifficultyLevel - 1).clamp(1, 5);
    }

    // Update performance metrics
    final newPerformanceMetrics = Map<String, dynamic>.from(performanceMetrics);
    newPerformanceMetrics['successRate'] = newChallengesCompleted / newChallengesAttempted;
    newPerformanceMetrics['averageErrorsPerChallenge'] = newErrorsMade / newChallengesAttempted;
    newPerformanceMetrics['averageHintsPerChallenge'] = newHintsRequested / newChallengesAttempted;

    return copyWith(
      challengesAttempted: newChallengesAttempted,
      challengesCompleted: newChallengesCompleted,
      errorsMade: newErrorsMade,
      hintsRequested: newHintsRequested,
      timeSpentMinutes: newTimeSpent,
      engagementScore: newEngagementScore,
      frustrationLevel: newFrustrationLevel,
      masteryLevel: newMasteryLevel,
      difficultyLevel: newDifficultyLevel,
      performanceMetrics: newPerformanceMetrics,
      actionHistory: newActionHistory,
    );
  }

  /// Record a hint request
  LearningSession recordHintRequest() {
    // Create a copy of action history
    final newActionHistory = List<Map<String, dynamic>>.from(actionHistory);

    // Add new action
    newActionHistory.add({
      'type': 'hint_request',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update metrics
    final newHintsRequested = hintsRequested + 1;

    // Slight increase in frustration when requesting hints
    final newFrustrationLevel = (frustrationLevel + 0.05).clamp(0.0, 1.0);

    return copyWith(
      hintsRequested: newHintsRequested,
      frustrationLevel: newFrustrationLevel,
      actionHistory: newActionHistory,
    );
  }

  /// Record an error
  LearningSession recordError() {
    // Create a copy of action history
    final newActionHistory = List<Map<String, dynamic>>.from(actionHistory);

    // Add new action
    newActionHistory.add({
      'type': 'error',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update metrics
    final newErrorsMade = errorsMade + 1;

    // Increase in frustration when making errors
    final newFrustrationLevel = (frustrationLevel + 0.1).clamp(0.0, 1.0);

    return copyWith(
      errorsMade: newErrorsMade,
      frustrationLevel: newFrustrationLevel,
      actionHistory: newActionHistory,
    );
  }

  /// End the session
  LearningSession end() {
    if (endTime != null) {
      return this; // Already ended
    }

    final now = DateTime.now();
    final sessionDuration = now.difference(startTime);
    final totalMinutes = (sessionDuration.inSeconds / 60).round();

    return copyWith(
      endTime: now,
      timeSpentMinutes: totalMinutes,
    );
  }

  /// Check if the session is active
  bool get isActive => endTime == null;

  /// Get the success rate for this session
  double get successRate =>
      challengesAttempted > 0 ? challengesCompleted / challengesAttempted : 0.0;

  /// Get the average number of hints per challenge
  double get averageHintsPerChallenge =>
      challengesAttempted > 0 ? hintsRequested / challengesAttempted : 0.0;

  /// Get the average number of errors per challenge
  double get averageErrorsPerChallenge =>
      challengesAttempted > 0 ? errorsMade / challengesAttempted : 0.0;

  /// Check if the user is struggling
  bool get isUserStruggling =>
      frustrationLevel > 0.7 || (successRate < 0.3 && challengesAttempted > 2);

  /// Check if the user is excelling
  bool get isUserExcelling =>
      masteryLevel > 0.8 && successRate > 0.8 && challengesAttempted > 2;

  /// Get recommended difficulty adjustment
  int get recommendedDifficultyAdjustment {
    if (isUserStruggling) {
      return -1; // Decrease difficulty
    } else if (isUserExcelling) {
      return 1; // Increase difficulty
    } else {
      return 0; // Maintain current difficulty
    }
  }
}
