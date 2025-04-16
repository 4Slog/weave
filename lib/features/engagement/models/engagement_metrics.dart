import 'dart:math' as math;

/// Model representing engagement metrics for a user.
///
/// This model tracks various engagement metrics such as time spent,
/// interaction counts, and activity patterns.
class EngagementMetrics {
  /// User ID associated with these metrics.
  final String userId;

  /// Total engagement time in seconds.
  final int totalEngagementTimeSeconds;

  /// Total number of interactions.
  final int interactionCount;

  /// Number of challenge attempts.
  final int challengeAttempts;

  /// Number of challenge completions.
  final int challengeCompletions;

  /// Number of story progressions.
  final int storyProgression;

  /// Counts of different activity types.
  final Map<String, int> activityCounts;

  /// Timestamp of the last interaction.
  final DateTime lastInteractionTime;

  /// Timestamp of the first recorded interaction.
  final DateTime firstInteractionTime;

  /// Number of unique days with activity.
  final int uniqueActiveDays;

  /// Educational metrics related to engagement.
  final EducationalEngagementMetrics educationalMetrics;

  /// Create a new EngagementMetrics.
  EngagementMetrics({
    required this.userId,
    this.totalEngagementTimeSeconds = 0,
    this.interactionCount = 0,
    this.challengeAttempts = 0,
    this.challengeCompletions = 0,
    this.storyProgression = 0,
    this.activityCounts = const {},
    DateTime? lastInteractionTime,
    DateTime? firstInteractionTime,
    this.uniqueActiveDays = 0,
    EducationalEngagementMetrics? educationalMetrics,
  }) :
    lastInteractionTime = lastInteractionTime ?? DateTime.now(),
    firstInteractionTime = firstInteractionTime ?? DateTime.now(),
    educationalMetrics = educationalMetrics ?? EducationalEngagementMetrics();

  /// Create an EngagementMetrics from a JSON map.
  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      userId: json['user_id'] as String,
      totalEngagementTimeSeconds: json['total_engagement_time_seconds'] as int? ?? 0,
      interactionCount: json['total_interactions'] as int? ?? 0,
      challengeAttempts: json['challenge_attempts'] as int? ?? 0,
      challengeCompletions: json['challenge_completions'] as int? ?? 0,
      storyProgression: json['story_progression'] as int? ?? 0,
      activityCounts: (json['activity_counts'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ) ?? {},
      lastInteractionTime: json['last_interaction_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_interaction_time'] as int)
          : DateTime.now(),
      firstInteractionTime: json['first_interaction_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['first_interaction_time'] as int)
          : DateTime.now(),
      uniqueActiveDays: json['unique_active_days'] as int? ?? 0,
      educationalMetrics: json['educational_metrics'] != null
          ? EducationalEngagementMetrics.fromJson(json['educational_metrics'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert this EngagementMetrics to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_engagement_time_seconds': totalEngagementTimeSeconds,
      'total_interactions': interactionCount,
      'challenge_attempts': challengeAttempts,
      'challenge_completions': challengeCompletions,
      'story_progression': storyProgression,
      'activity_counts': activityCounts,
      'last_interaction_time': lastInteractionTime.millisecondsSinceEpoch,
      'first_interaction_time': firstInteractionTime.millisecondsSinceEpoch,
      'unique_active_days': uniqueActiveDays,
      'educational_metrics': educationalMetrics.toJson(),
    };
  }

  /// Create a copy of this EngagementMetrics with some fields replaced.
  EngagementMetrics copyWith({
    String? userId,
    int? totalEngagementTimeSeconds,
    int? interactionCount,
    int? challengeAttempts,
    int? challengeCompletions,
    int? storyProgression,
    Map<String, int>? activityCounts,
    DateTime? lastInteractionTime,
    DateTime? firstInteractionTime,
    int? uniqueActiveDays,
    EducationalEngagementMetrics? educationalMetrics,
  }) {
    return EngagementMetrics(
      userId: userId ?? this.userId,
      totalEngagementTimeSeconds: totalEngagementTimeSeconds ?? this.totalEngagementTimeSeconds,
      interactionCount: interactionCount ?? this.interactionCount,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      challengeCompletions: challengeCompletions ?? this.challengeCompletions,
      storyProgression: storyProgression ?? this.storyProgression,
      activityCounts: activityCounts ?? this.activityCounts,
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
      firstInteractionTime: firstInteractionTime ?? this.firstInteractionTime,
      uniqueActiveDays: uniqueActiveDays ?? this.uniqueActiveDays,
      educationalMetrics: educationalMetrics ?? this.educationalMetrics,
    );
  }

  /// Get the total engagement time in hours.
  double get totalEngagementTimeHours => totalEngagementTimeSeconds / 3600;

  /// Get the challenge completion rate.
  double get challengeCompletionRate {
    if (challengeAttempts == 0) return 0;
    return challengeCompletions / challengeAttempts;
  }

  /// Get the number of days since the first interaction.
  int get daysSinceFirstInteraction {
    return DateTime.now().difference(firstInteractionTime).inDays;
  }

  /// Get the number of days since the last interaction.
  int get daysSinceLastInteraction {
    return DateTime.now().difference(lastInteractionTime).inDays;
  }

  /// Check if the user is a new user (less than 7 days).
  bool get isNewUser {
    return daysSinceFirstInteraction < 7;
  }

  /// Check if the user is active (interacted in the last 7 days).
  bool get isActiveUser {
    return daysSinceLastInteraction < 7;
  }

  /// Get the average daily engagement time in minutes.
  double get averageDailyEngagementMinutes {
    if (uniqueActiveDays == 0) return 0;
    return (totalEngagementTimeSeconds / 60) / uniqueActiveDays;
  }

  /// Get the average interactions per session.
  double get averageInteractionsPerSession {
    final sessionCount = activityCounts['session_start'] ?? 0;
    if (sessionCount == 0) return 0;
    return interactionCount / sessionCount;
  }

  /// Calculate the engagement score based on various metrics.
  double calculateEngagementScore() {
    // Base score components
    double timeScore = math.min(totalEngagementTimeSeconds / 3600, 10) * 10; // Max 10 hours = 100 points
    double interactionScore = math.min(interactionCount / 1000, 10) * 10; // Max 1000 interactions = 100 points
    double challengeScore = math.min(challengeCompletions / 50, 10) * 10; // Max 50 completions = 100 points
    double storyScore = math.min(storyProgression / 20, 10) * 10; // Max 20 stories = 100 points

    // Calculate frequency and recency bonuses
    double frequencyBonus = math.min(uniqueActiveDays * 5, 25); // Up to 25 points for 5+ unique days

    // Bonus for recency (used in last 2 days)
    double recencyBonus = daysSinceLastInteraction < 2 ? 25 : 0; // 25 points for recent use

    // Calculate overall score (maximum 400 + 50 = 450)
    final overallScore = timeScore + interactionScore + challengeScore + storyScore + frequencyBonus + recencyBonus;

    // Return normalized score out of 100
    return math.min((overallScore / 450) * 100, 100);
  }

  /// Get the most frequent activity types.
  List<MapEntry<String, int>> getMostFrequentActivities({int limit = 5}) {
    final sortedActivities = activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedActivities.take(limit).toList();
  }

  /// Get the engagement summary as a map.
  Map<String, dynamic> getEngagementSummary() {
    return {
      'total_engagement_time_hours': totalEngagementTimeHours,
      'total_interactions': interactionCount,
      'challenge_attempts': challengeAttempts,
      'challenge_completions': challengeCompletions,
      'challenge_completion_rate': challengeCompletionRate,
      'story_progression': storyProgression,
      'days_since_first_interaction': daysSinceFirstInteraction,
      'days_since_last_interaction': daysSinceLastInteraction,
      'is_new_user': isNewUser,
      'is_active_user': isActiveUser,
      'unique_active_days': uniqueActiveDays,
      'average_daily_engagement_minutes': averageDailyEngagementMinutes,
      'engagement_score': calculateEngagementScore(),
      'educational_metrics': educationalMetrics.getSummary(),
    };
  }

  @override
  String toString() {
    return 'EngagementMetrics(userId: $userId, totalEngagementTimeHours: $totalEngagementTimeHours, interactionCount: $interactionCount)';
  }
}

/// Model representing educational engagement metrics.
class EducationalEngagementMetrics {
  /// Map of concept IDs to mastery levels (0.0 to 1.0).
  final Map<String, double> conceptMasteryLevels;

  /// Map of standard IDs to demonstration counts.
  final Map<String, int> standardsDemonstrated;

  /// Map of learning objectives to completion status.
  final Map<String, bool> learningObjectivesCompleted;

  /// Number of educational milestones reached.
  final int educationalMilestonesReached;

  /// Average time spent per educational activity in seconds.
  final double averageTimePerEducationalActivity;

  /// Create a new EducationalEngagementMetrics.
  EducationalEngagementMetrics({
    this.conceptMasteryLevels = const {},
    this.standardsDemonstrated = const {},
    this.learningObjectivesCompleted = const {},
    this.educationalMilestonesReached = 0,
    this.averageTimePerEducationalActivity = 0,
  });

  /// Create an EducationalEngagementMetrics from a JSON map.
  factory EducationalEngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EducationalEngagementMetrics(
      conceptMasteryLevels: (json['concept_mastery_levels'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
      standardsDemonstrated: (json['standards_demonstrated'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ) ?? {},
      learningObjectivesCompleted: (json['learning_objectives_completed'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ) ?? {},
      educationalMilestonesReached: json['educational_milestones_reached'] as int? ?? 0,
      averageTimePerEducationalActivity: (json['average_time_per_educational_activity'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Convert this EducationalEngagementMetrics to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'concept_mastery_levels': conceptMasteryLevels,
      'standards_demonstrated': standardsDemonstrated,
      'learning_objectives_completed': learningObjectivesCompleted,
      'educational_milestones_reached': educationalMilestonesReached,
      'average_time_per_educational_activity': averageTimePerEducationalActivity,
    };
  }

  /// Create a copy of this EducationalEngagementMetrics with some fields replaced.
  EducationalEngagementMetrics copyWith({
    Map<String, double>? conceptMasteryLevels,
    Map<String, int>? standardsDemonstrated,
    Map<String, bool>? learningObjectivesCompleted,
    int? educationalMilestonesReached,
    double? averageTimePerEducationalActivity,
  }) {
    return EducationalEngagementMetrics(
      conceptMasteryLevels: conceptMasteryLevels ?? this.conceptMasteryLevels,
      standardsDemonstrated: standardsDemonstrated ?? this.standardsDemonstrated,
      learningObjectivesCompleted: learningObjectivesCompleted ?? this.learningObjectivesCompleted,
      educationalMilestonesReached: educationalMilestonesReached ?? this.educationalMilestonesReached,
      averageTimePerEducationalActivity: averageTimePerEducationalActivity ?? this.averageTimePerEducationalActivity,
    );
  }

  /// Get the number of concepts mastered (mastery level >= 0.8).
  int get conceptsMasteredCount {
    return conceptMasteryLevels.values.where((level) => level >= 0.8).length;
  }

  /// Get the number of standards demonstrated.
  int get standardsDemonstratedCount {
    return standardsDemonstrated.length;
  }

  /// Get the number of learning objectives completed.
  int get learningObjectivesCompletedCount {
    return learningObjectivesCompleted.values.where((completed) => completed).length;
  }

  /// Get the percentage of learning objectives completed.
  double get learningObjectivesCompletionRate {
    if (learningObjectivesCompleted.isEmpty) return 0;
    return learningObjectivesCompletedCount / learningObjectivesCompleted.length;
  }

  /// Get the average concept mastery level.
  double get averageConceptMasteryLevel {
    if (conceptMasteryLevels.isEmpty) return 0;
    final sum = conceptMasteryLevels.values.fold(0.0, (sum, level) => sum + level);
    return sum / conceptMasteryLevels.length;
  }

  /// Get the most mastered concepts.
  List<MapEntry<String, double>> getMostMasteredConcepts({int limit = 5}) {
    final sortedConcepts = conceptMasteryLevels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedConcepts.take(limit).toList();
  }

  /// Get the most demonstrated standards.
  List<MapEntry<String, int>> getMostDemonstratedStandards({int limit = 5}) {
    final sortedStandards = standardsDemonstrated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedStandards.take(limit).toList();
  }

  /// Get the educational metrics summary as a map.
  Map<String, dynamic> getSummary() {
    return {
      'concepts_mastered_count': conceptsMasteredCount,
      'standards_demonstrated_count': standardsDemonstratedCount,
      'learning_objectives_completed_count': learningObjectivesCompletedCount,
      'learning_objectives_completion_rate': learningObjectivesCompletionRate,
      'average_concept_mastery_level': averageConceptMasteryLevel,
      'educational_milestones_reached': educationalMilestonesReached,
      'average_time_per_educational_activity': averageTimePerEducationalActivity,
    };
  }
}
