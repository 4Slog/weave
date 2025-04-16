import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/engagement_event.dart';
import '../models/engagement_metrics.dart';
import 'analytics_service.dart';
import 'dart:math' as math;

/// Service for tracking educational metrics and correlating engagement with learning outcomes.
///
/// This service provides methods for analyzing educational progress,
/// correlating engagement with learning outcomes, and generating
/// educational insights.
class EducationalMetricsService {
  final AnalyticsService _analyticsService;
  final StorageService _storageService;

  /// Create a new EducationalMetricsService.
  EducationalMetricsService({
    AnalyticsService? analyticsService,
    StorageService? storageService,
  }) :
    _analyticsService = analyticsService ?? AnalyticsService(),
    _storageService = storageService ?? StorageService();

  /// Initialize the service.
  Future<void> initialize() async {
    await _analyticsService.initialize();
  }

  /// Track a learning event.
  ///
  /// [userId] is the ID of the user.
  /// [eventType] is the type of learning event.
  /// [details] is additional details about the event.
  /// [educationalContext] is the educational context of the event.
  ///
  /// Returns the updated educational engagement metrics.
  Future<EducationalEngagementMetrics> trackLearningEvent({
    required String userId,
    required String eventType,
    Map<String, dynamic> details = const {},
    String? educationalContext,
  }) async {
    // Create an engagement event
    final event = EngagementEvent(
      id: '${eventType}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType,
      timestamp: DateTime.now(),
      userId: userId,
      details: details,
      educationalContext: educationalContext,
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    return metrics.educationalMetrics;
  }

  /// Track concept mastery.
  ///
  /// [userId] is the ID of the user.
  /// [conceptId] is the ID of the concept.
  /// [masteryLevel] is the mastery level (0.0 to 1.0).
  /// [context] is the context in which the concept was demonstrated.
  ///
  /// Returns the updated educational engagement metrics.
  Future<EducationalEngagementMetrics> trackConceptMastery({
    required String userId,
    required String conceptId,
    required double masteryLevel,
    String? context,
  }) async {
    // Create an engagement event
    final event = EngagementEvent(
      id: 'concept_mastery_${conceptId}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'concept_mastery',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        'concept_id': conceptId,
        'mastery_level': masteryLevel,
        'context': context,
      },
      educationalContext: 'Concept mastery: $conceptId',
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    // Update user skill mastery in storage
    await _storageService.saveUserSkillMastery(userId, conceptId, masteryLevel);

    return metrics.educationalMetrics;
  }

  /// Track standard demonstration.
  ///
  /// [userId] is the ID of the user.
  /// [standardId] is the ID of the standard.
  /// [context] is the context in which the standard was demonstrated.
  ///
  /// Returns the updated educational engagement metrics.
  Future<EducationalEngagementMetrics> trackStandardDemonstration({
    required String userId,
    required String standardId,
    String? context,
  }) async {
    // Create an engagement event
    final event = EngagementEvent(
      id: 'standard_demonstration_${standardId}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'standard_demonstration',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        'standard_id': standardId,
        'context': context,
      },
      educationalContext: 'Standard demonstration: $standardId',
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    return metrics.educationalMetrics;
  }

  /// Track learning objective completion.
  ///
  /// [userId] is the ID of the user.
  /// [objectiveId] is the ID of the learning objective.
  /// [completed] indicates whether the objective was completed.
  /// [context] is the context in which the objective was completed.
  ///
  /// Returns the updated educational engagement metrics.
  Future<EducationalEngagementMetrics> trackLearningObjective({
    required String userId,
    required String objectiveId,
    required bool completed,
    String? context,
  }) async {
    // Create an engagement event
    final event = EngagementEvent(
      id: 'learning_objective_${objectiveId}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'learning_objective',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        'learning_objective': objectiveId,
        'completed': completed,
        'context': context,
      },
      educationalContext: 'Learning objective: $objectiveId',
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    return metrics.educationalMetrics;
  }

  /// Get educational metrics for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the educational engagement metrics for the user.
  Future<EducationalEngagementMetrics> getEducationalMetrics(String userId) async {
    return _analyticsService.getEducationalMetrics(userId);
  }

  /// Get educational metrics summary for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a summary of educational metrics for the user.
  Future<Map<String, dynamic>> getEducationalMetricsSummary(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.getSummary();
  }

  /// Get concept mastery levels for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a map of concept IDs to mastery levels.
  Future<Map<String, double>> getConceptMasteryLevels(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.conceptMasteryLevels;
  }

  /// Get standards demonstrated by a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a map of standard IDs to demonstration counts.
  Future<Map<String, int>> getStandardsDemonstrated(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.standardsDemonstrated;
  }

  /// Get learning objectives completed by a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a map of learning objective IDs to completion status.
  Future<Map<String, bool>> getLearningObjectivesCompleted(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.learningObjectivesCompleted;
  }

  /// Get most mastered concepts for a user.
  ///
  /// [userId] is the ID of the user.
  /// [limit] is the maximum number of concepts to return.
  ///
  /// Returns a list of concept IDs and mastery levels.
  Future<List<MapEntry<String, double>>> getMostMasteredConcepts(
    String userId, {
    int limit = 5,
  }) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.getMostMasteredConcepts(limit: limit);
  }

  /// Get most demonstrated standards for a user.
  ///
  /// [userId] is the ID of the user.
  /// [limit] is the maximum number of standards to return.
  ///
  /// Returns a list of standard IDs and demonstration counts.
  Future<List<MapEntry<String, int>>> getMostDemonstratedStandards(
    String userId, {
    int limit = 5,
  }) async {
    final metrics = await getEducationalMetrics(userId);
    return metrics.getMostDemonstratedStandards(limit: limit);
  }

  /// Get learning effectiveness for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a score representing learning effectiveness.
  Future<double> getLearningEffectiveness(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    final engagementScore = await _analyticsService.getEngagementScore(userId);

    // Calculate learning effectiveness based on engagement and educational metrics
    final conceptsMastered = metrics.conceptsMasteredCount;
    final standardsDemonstrated = metrics.standardsDemonstratedCount;
    final objectivesCompleted = metrics.learningObjectivesCompletedCount;
    final averageMastery = metrics.averageConceptMasteryLevel;

    // Normalize each component to a 0-1 scale
    final normalizedConcepts = math.min(conceptsMastered / 20, 1.0);
    final normalizedStandards = math.min(standardsDemonstrated / 20, 1.0);
    final normalizedObjectives = math.min(objectivesCompleted / 20, 1.0);

    // Calculate weighted score
    final weightedScore = (
      normalizedConcepts * 0.3 +
      normalizedStandards * 0.2 +
      normalizedObjectives * 0.2 +
      averageMastery * 0.3
    );

    // Adjust by engagement score
    final adjustedScore = weightedScore * (engagementScore / 100);

    // Return score on a 0-100 scale
    return adjustedScore * 100;
  }

  /// Get learning path recommendation for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a recommended learning path type.
  Future<LearningPathType> getLearningPathRecommendation(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    final engagementScore = await _analyticsService.getEngagementScore(userId);

    // Get user progress
    final userProgress = await _storageService.getUserProgress(userId);

    // Get current learning path type
    // Default to balanced if we can't determine the user's learning path type
    LearningPathType currentPathType = LearningPathType.balanced;

    // Try to get the learning path type from user preferences if available
    if (userProgress != null) {
      final preferences = await _storageService.getUserPreferences(userId);
      final pathTypeStr = preferences['learningPathType'] as String?;
      if (pathTypeStr != null) {
        // Convert string to enum
        if (pathTypeStr == 'logicBased') {
          currentPathType = LearningPathType.logicBased;
        } else if (pathTypeStr == 'creativityBased') {
          currentPathType = LearningPathType.creativityBased;
        } else if (pathTypeStr == 'challengeBased') {
          currentPathType = LearningPathType.challengeBased;
        }
      }
    }

    // If engagement score is low, recommend a more engaging path
    if (engagementScore < 40) {
      return LearningPathType.creativityBased;
    }

    // If concept mastery is low, recommend a more structured path
    if (metrics.averageConceptMasteryLevel < 0.4) {
      return LearningPathType.logicBased;
    }

    // If both engagement and mastery are high, recommend a more challenging path
    if (engagementScore > 70 && metrics.averageConceptMasteryLevel > 0.7) {
      return LearningPathType.challengeBased;
    }

    // Otherwise, keep the current path
    return currentPathType;
  }

  /// Get learning style recommendation for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a recommended learning style.
  Future<String> getLearningStyleRecommendation(String userId) async {
    // Get metrics but we'll use event analysis for recommendation

    // Get recent events
    final recentEvents = await _analyticsService.getRecentEvents(userId, limit: 50);

    // Count success rates for different activity types
    int visualActivities = 0;
    int visualSuccesses = 0;
    int auditoryActivities = 0;
    int auditorySuccesses = 0;
    int kinestheticActivities = 0;
    int kinestheticSuccesses = 0;

    for (final event in recentEvents) {
      if (event.details.containsKey('activity_style')) {
        final style = event.details['activity_style'] as String;
        final success = event.getSuccessStatus() ?? false;

        if (style == 'visual') {
          visualActivities++;
          if (success) visualSuccesses++;
        } else if (style == 'auditory') {
          auditoryActivities++;
          if (success) auditorySuccesses++;
        } else if (style == 'kinesthetic') {
          kinestheticActivities++;
          if (success) kinestheticSuccesses++;
        }
      }
    }

    // Calculate success rates
    double visualRate = visualActivities > 0 ? visualSuccesses / visualActivities : 0;
    double auditoryRate = auditoryActivities > 0 ? auditorySuccesses / auditoryActivities : 0;
    double kinestheticRate = kinestheticActivities > 0 ? kinestheticSuccesses / kinestheticActivities : 0;

    // Determine the most effective style
    if (visualRate >= auditoryRate && visualRate >= kinestheticRate) {
      return 'visual';
    } else if (auditoryRate >= visualRate && auditoryRate >= kinestheticRate) {
      return 'auditory';
    } else {
      return 'kinesthetic';
    }
  }

  /// Get learning recommendations for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of learning recommendations.
  Future<List<Map<String, dynamic>>> getLearningRecommendations(String userId) async {
    final metrics = await getEducationalMetrics(userId);
    final conceptMasteryLevels = metrics.conceptMasteryLevels;

    // Get concepts that need improvement
    final conceptsToImprove = conceptMasteryLevels.entries
        .where((entry) => entry.value < 0.7)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Generate recommendations
    final recommendations = <Map<String, dynamic>>[];

    // Add concept-specific recommendations
    for (final entry in conceptsToImprove.take(3)) {
      recommendations.add({
        'type': 'concept',
        'concept_id': entry.key,
        'mastery_level': entry.value,
        'title': 'Improve ${_getConceptName(entry.key)}',
        'description': 'Practice more challenges involving ${_getConceptName(entry.key)} to improve your mastery.',
        'action': 'practice_concept',
        'action_params': {'concept_id': entry.key},
      });
    }

    // Add learning path recommendation
    final recommendedPath = await getLearningPathRecommendation(userId);
    recommendations.add({
      'type': 'learning_path',
      'path_type': recommendedPath.toString().split('.').last,
      'title': 'Try ${_getLearningPathName(recommendedPath)} Learning Path',
      'description': 'Based on your learning patterns, the ${_getLearningPathName(recommendedPath)} learning path may be more effective for you.',
      'action': 'switch_learning_path',
      'action_params': {'path_type': recommendedPath.toString().split('.').last},
    });

    // Add learning style recommendation
    final recommendedStyle = await getLearningStyleRecommendation(userId);
    recommendations.add({
      'type': 'learning_style',
      'style': recommendedStyle,
      'title': 'Try ${_getLearningStyleName(recommendedStyle)} Activities',
      'description': 'You seem to learn best with ${_getLearningStyleName(recommendedStyle)} activities.',
      'action': 'focus_learning_style',
      'action_params': {'style': recommendedStyle},
    });

    return recommendations;
  }

  /// Get a correlation between engagement and learning outcomes.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a correlation analysis.
  Future<Map<String, dynamic>> getEngagementLearningCorrelation(String userId) async {
    final metrics = await _analyticsService.getMetrics(userId);
    final educationalMetrics = metrics.educationalMetrics;

    // Get recent events
    final recentEvents = await _analyticsService.getRecentEvents(userId, limit: 100);

    // Group events by day
    final eventsByDay = <String, List<EngagementEvent>>{};
    for (final event in recentEvents) {
      final day = _formatDate(event.timestamp);
      eventsByDay[day] = (eventsByDay[day] ?? [])..add(event);
    }

    // Calculate daily engagement and learning metrics
    final dailyMetrics = <Map<String, dynamic>>[];
    for (final entry in eventsByDay.entries) {
      final day = entry.key;
      final events = entry.value;

      // Calculate engagement metrics
      int interactionCount = events.length;
      int timeSpentSeconds = events
          .map((e) => e.getDuration()?.inSeconds ?? 0)
          .fold(0, (sum, duration) => sum + duration);

      // Calculate learning metrics
      int challengesCompleted = events
          .where((e) => e.eventType == 'challenge_complete')
          .length;
      int standardsDemonstrated = events
          .where((e) => e.eventType == 'standard_demonstration')
          .length;

      dailyMetrics.add({
        'day': day,
        'interaction_count': interactionCount,
        'time_spent_minutes': timeSpentSeconds / 60,
        'challenges_completed': challengesCompleted,
        'standards_demonstrated': standardsDemonstrated,
      });
    }

    // Calculate correlation coefficients
    double interactionLearningCorrelation = _calculateCorrelation(
      dailyMetrics.map((m) => m['interaction_count'] as int).toList(),
      dailyMetrics.map((m) => (m['challenges_completed'] as int) + (m['standards_demonstrated'] as int)).toList(),
    );

    double timeSpentLearningCorrelation = _calculateCorrelation(
      dailyMetrics.map((m) => m['time_spent_minutes'] as double).toList(),
      dailyMetrics.map((m) => (m['challenges_completed'] as int) + (m['standards_demonstrated'] as int)).toList(),
    );

    return {
      'interaction_learning_correlation': interactionLearningCorrelation,
      'time_spent_learning_correlation': timeSpentLearningCorrelation,
      'average_concept_mastery': educationalMetrics.averageConceptMasteryLevel,
      'concepts_mastered_count': educationalMetrics.conceptsMasteredCount,
      'standards_demonstrated_count': educationalMetrics.standardsDemonstratedCount,
      'learning_objectives_completion_rate': educationalMetrics.learningObjectivesCompletionRate,
      'daily_metrics': dailyMetrics,
    };
  }

  /// Format a date as a string.
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate the correlation coefficient between two lists of numbers.
  double _calculateCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.isEmpty) return 0;

    // Calculate means
    double meanX = x.fold(0.0, (double sum, val) => sum + val) / x.length;
    double meanY = y.fold(0.0, (double sum, val) => sum + val) / y.length;

    // Calculate covariance and variances
    double covariance = 0;
    double varianceX = 0;
    double varianceY = 0;

    for (int i = 0; i < x.length; i++) {
      double diffX = x[i] - meanX;
      double diffY = y[i] - meanY;
      covariance += diffX * diffY;
      varianceX += diffX * diffX;
      varianceY += diffY * diffY;
    }

    // Calculate correlation coefficient
    if (varianceX == 0 || varianceY == 0) return 0;
    return covariance / (math.sqrt(varianceX) * math.sqrt(varianceY));
  }

  /// Get a human-readable name for a concept.
  String _getConceptName(String conceptId) {
    // This is a simplified implementation
    // A more sophisticated approach would use a concept repository

    final conceptNames = {
      'sequences': 'Sequences',
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'events': 'Events',
      'operators': 'Operators',
      'data': 'Data',
      'algorithms': 'Algorithms',
      'patterns': 'Patterns',
    };

    return conceptNames[conceptId] ?? conceptId;
  }

  /// Get a human-readable name for a learning path.
  String _getLearningPathName(LearningPathType pathType) {
    switch (pathType) {
      case LearningPathType.logicBased:
        return 'Logic-Based';
      case LearningPathType.creativityBased:
        return 'Creativity-Based';
      case LearningPathType.challengeBased:
        return 'Challenge-Based';
      case LearningPathType.balanced:
        return 'Balanced';
    }
  }

  /// Get a human-readable name for a learning style.
  String _getLearningStyleName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual';
      case 'auditory':
        return 'Auditory';
      case 'kinesthetic':
        return 'Hands-On';
      default:
        return 'Balanced';
    }
  }
}
