import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart' as app_models;
import '../models/engagement_event.dart';
import '../models/engagement_metrics.dart';
import '../models/engagement_milestone.dart';
import '../repositories/engagement_repository.dart';
import 'analytics_service.dart';
import 'educational_metrics_service.dart';

/// Enhanced service for tracking user engagement and educational progress.
///
/// This service provides improved engagement tracking with educational context,
/// better analytics for understanding user behavior, and more sophisticated
/// recommendations based on engagement patterns.
class EngagementServiceRefactored {
  /// Repository for engagement data
  final EngagementRepository _repository;

  /// Service for analytics
  final AnalyticsService _analyticsService;

  /// Service for educational metrics
  final EducationalMetricsService _educationalMetricsService;

  /// Storage service for user data
  final StorageService _storageService;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new EngagementServiceRefactored with optional dependencies
  EngagementServiceRefactored({
    EngagementRepository? repository,
    AnalyticsService? analyticsService,
    EducationalMetricsService? educationalMetricsService,
    StorageService? storageService,
  }) :
    _repository = repository ?? EngagementRepository(StorageService().storage),
    _analyticsService = analyticsService ?? AnalyticsService(),
    _educationalMetricsService = educationalMetricsService ?? EducationalMetricsService(),
    _storageService = storageService ?? StorageService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the repository
      await _repository.initialize();

      // Initialize the analytics service
      await _analyticsService.initialize();

      // Initialize the educational metrics service
      await _educationalMetricsService.initialize();

      _isInitialized = true;
      debugPrint('EngagementServiceRefactored initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize EngagementServiceRefactored: $e');
      throw Exception('Failed to initialize EngagementServiceRefactored: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Track a user interaction
  ///
  /// [userId] is the ID of the user
  /// [interactionType] is the type of interaction
  /// [details] is additional details about the interaction
  /// [educationalContext] is the educational context of the interaction
  ///
  /// Returns the updated engagement metrics
  Future<EngagementMetrics> trackInteraction({
    required String userId,
    required String interactionType,
    Map<String, dynamic> details = const {},
    String? educationalContext,
  }) async {
    await _ensureInitialized();

    // Create an engagement event
    final event = EngagementEvent(
      id: '${interactionType}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: interactionType,
      timestamp: DateTime.now(),
      userId: userId,
      details: details,
      educationalContext: educationalContext,
    );

    // Process the event
    return _analyticsService.processEvent(event);
  }

  /// Track a challenge attempt
  ///
  /// [userId] is the ID of the user
  /// [challengeId] is the ID of the challenge
  /// [success] indicates whether the attempt was successful
  /// [details] is additional details about the attempt
  /// [concepts] is the list of concepts involved in the challenge
  /// [standards] is the list of educational standards demonstrated
  ///
  /// Returns the updated engagement metrics
  Future<EngagementMetrics> trackChallengeAttempt({
    required String userId,
    required String challengeId,
    required bool success,
    Map<String, dynamic> details = const {},
    List<String> concepts = const [],
    List<String> standards = const [],
  }) async {
    await _ensureInitialized();

    // Create an engagement event
    final event = EngagementEvent(
      id: 'challenge_attempt_${challengeId}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: success ? 'challenge_complete' : 'challenge_attempt',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        ...details,
        'challenge_id': challengeId,
        'success': success,
        'concepts': concepts,
        'standards': standards,
      },
      educationalContext: 'Challenge ${success ? 'completion' : 'attempt'}: $challengeId',
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    // If successful, update concept mastery and standards demonstrated
    if (success) {
      for (final concept in concepts) {
        // Get current mastery level
        final currentLevel = await _storageService.getUserSkillMastery(userId, concept);

        // Increase mastery level
        final newLevel = (currentLevel + 0.1).clamp(0.0, 1.0);

        // Track concept mastery
        await _educationalMetricsService.trackConceptMastery(
          userId: userId,
          conceptId: concept,
          masteryLevel: newLevel,
          context: 'Challenge completion: $challengeId',
        );
      }

      for (final standard in standards) {
        // Track standard demonstration
        await _educationalMetricsService.trackStandardDemonstration(
          userId: userId,
          standardId: standard,
          context: 'Challenge completion: $challengeId',
        );
      }
    }

    return metrics;
  }

  /// Track story progress
  ///
  /// [userId] is the ID of the user
  /// [storyId] is the ID of the story
  /// [progress] is the progress percentage (0.0 to 1.0)
  /// [details] is additional details about the progress
  /// [concepts] is the list of concepts involved in the story
  ///
  /// Returns the updated engagement metrics
  Future<EngagementMetrics> trackStoryProgress({
    required String userId,
    required String storyId,
    required double progress,
    Map<String, dynamic> details = const {},
    List<String> concepts = const [],
  }) async {
    await _ensureInitialized();

    // Create an engagement event
    final event = EngagementEvent(
      id: 'story_progress_${storyId}_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'story_progress',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        ...details,
        'story_id': storyId,
        'progress': progress,
        'concepts': concepts,
      },
      educationalContext: 'Story progress: $storyId',
    );

    // Process the event
    final metrics = await _analyticsService.processEvent(event);

    // If progress is significant, update concept exposure
    if (progress >= 0.5) {
      for (final concept in concepts) {
        // Get current mastery level
        final currentLevel = await _storageService.getUserSkillMastery(userId, concept);

        // Slightly increase mastery level for exposure
        final newLevel = (currentLevel + 0.05).clamp(0.0, 1.0);

        // Track concept mastery
        await _educationalMetricsService.trackConceptMastery(
          userId: userId,
          conceptId: concept,
          masteryLevel: newLevel,
          context: 'Story progress: $storyId',
        );
      }
    }

    return metrics;
  }

  /// Track session time
  ///
  /// [userId] is the ID of the user
  /// [durationSeconds] is the duration of the session in seconds
  /// [details] is additional details about the session
  ///
  /// Returns the updated engagement metrics
  Future<EngagementMetrics> trackSessionTime({
    required String userId,
    required int durationSeconds,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    // Create an engagement event
    final event = EngagementEvent(
      id: 'session_time_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'session_time',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        ...details,
        'duration_seconds': durationSeconds,
      },
    );

    // Process the event
    return _analyticsService.processEvent(event);
  }

  /// Start a user session
  ///
  /// [userId] is the ID of the user
  /// [details] is additional details about the session
  ///
  /// Returns the session data
  Future<Map<String, dynamic>> startSession({
    required String userId,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    // Start a session
    final sessionData = await _analyticsService.startSession(userId);

    // Add custom details
    sessionData['custom_details'] = details;

    return sessionData;
  }

  /// End a user session
  ///
  /// [userId] is the ID of the user
  /// [details] is additional details about the session
  ///
  /// Returns the session data
  Future<Map<String, dynamic>> endSession({
    required String userId,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    // Get current session data
    final sessionData = await _analyticsService.getSessionData(userId);

    // Add custom details
    if (sessionData.isNotEmpty) {
      sessionData['custom_details'] = {
        ...sessionData['custom_details'] ?? {},
        ...details,
      };
    }

    // End the session
    return _analyticsService.endSession(userId);
  }

  /// Get engagement metrics for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns the engagement metrics for the user
  Future<EngagementMetrics> getEngagementMetrics(String userId) async {
    await _ensureInitialized();

    return _analyticsService.getMetrics(userId);
  }

  /// Get engagement summary for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a summary of engagement metrics for the user
  Future<Map<String, dynamic>> getEngagementSummary(String userId) async {
    await _ensureInitialized();

    return _analyticsService.getEngagementSummary(userId);
  }

  /// Get educational metrics for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns the educational engagement metrics for the user
  Future<EducationalEngagementMetrics> getEducationalMetrics(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getEducationalMetrics(userId);
  }

  /// Get educational metrics summary for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a summary of educational metrics for the user
  Future<Map<String, dynamic>> getEducationalMetricsSummary(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getEducationalMetricsSummary(userId);
  }

  /// Get engagement score for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns the engagement score for the user
  Future<double> getEngagementScore(String userId) async {
    await _ensureInitialized();

    return _analyticsService.getEngagementScore(userId);
  }

  /// Get learning effectiveness for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a score representing learning effectiveness
  Future<double> getLearningEffectiveness(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getLearningEffectiveness(userId);
  }

  /// Get engagement milestones for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of all engagement milestones for the user
  Future<List<EngagementMilestone>> getMilestones(String userId) async {
    await _ensureInitialized();

    return _analyticsService.getMilestones(userId);
  }

  /// Get reached engagement milestones for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of reached engagement milestones for the user
  Future<List<EngagementMilestone>> getReachedMilestones(String userId) async {
    await _ensureInitialized();

    return _analyticsService.getReachedMilestones(userId);
  }

  /// Get next milestones for a user
  ///
  /// [userId] is the ID of the user
  /// [limit] is the maximum number of milestones to return
  ///
  /// Returns a list of upcoming milestones for the user
  Future<List<EngagementMilestone>> getNextMilestones(
    String userId, {
    int limit = 3,
  }) async {
    await _ensureInitialized();

    return _analyticsService.getNextMilestones(userId, limit: limit);
  }

  /// Get learning path recommendation for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a recommended learning path type
  Future<LearningPathType> getLearningPathRecommendation(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getLearningPathRecommendation(userId);
  }

  /// Get learning style recommendation for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a recommended learning style
  Future<String> getLearningStyleRecommendation(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getLearningStyleRecommendation(userId);
  }

  /// Get learning recommendations for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of learning recommendations
  Future<List<Map<String, dynamic>>> getLearningRecommendations(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getLearningRecommendations(userId);
  }

  /// Get a correlation between engagement and learning outcomes
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a correlation analysis
  Future<Map<String, dynamic>> getEngagementLearningCorrelation(String userId) async {
    await _ensureInitialized();

    return _educationalMetricsService.getEngagementLearningCorrelation(userId);
  }

  /// Get recent engagement events for a user
  ///
  /// [userId] is the ID of the user
  /// [limit] is the maximum number of events to return
  ///
  /// Returns a list of recent engagement events for the user
  Future<List<EngagementEvent>> getRecentEvents(
    String userId, {
    int limit = 20,
  }) async {
    await _ensureInitialized();

    return _analyticsService.getRecentEvents(userId, limit: limit);
  }

  /// Get engagement events by type
  ///
  /// [userId] is the ID of the user
  /// [eventType] is the type of events to retrieve
  /// [limit] is the maximum number of events to return
  ///
  /// Returns a list of engagement events of the specified type
  Future<List<EngagementEvent>> getEventsByType(
    String userId,
    String eventType, {
    int limit = 20,
  }) async {
    await _ensureInitialized();

    return _analyticsService.getEventsByType(userId, eventType, limit: limit);
  }

  /// Get engagement events for a specific challenge
  ///
  /// [userId] is the ID of the user
  /// [challengeId] is the ID of the challenge
  ///
  /// Returns a list of engagement events for the specified challenge
  Future<List<EngagementEvent>> getEventsForChallenge(
    String userId,
    String challengeId,
  ) async {
    await _ensureInitialized();

    return _analyticsService.getEventsForChallenge(userId, challengeId);
  }

  /// Get engagement events for a specific story
  ///
  /// [userId] is the ID of the user
  /// [storyId] is the ID of the story
  ///
  /// Returns a list of engagement events for the specified story
  Future<List<EngagementEvent>> getEventsForStory(
    String userId,
    String storyId,
  ) async {
    await _ensureInitialized();

    return _analyticsService.getEventsForStory(userId, storyId);
  }

  /// Initialize default milestones for a user
  ///
  /// [userId] is the ID of the user
  Future<void> initializeDefaultMilestones(String userId) async {
    await _ensureInitialized();

    await _analyticsService.initializeDefaultMilestones(userId);
  }

  /// Update user progress based on engagement metrics
  ///
  /// [userProgress] is the current user progress
  ///
  /// Returns updated user progress
  Future<app_models.UserProgress> updateUserProgress(app_models.UserProgress userProgress) async {
    await _ensureInitialized();

    final userId = userProgress.userId;

    // Get engagement metrics
    final metrics = await getEngagementMetrics(userId);

    // Get educational metrics
    final educationalMetrics = await getEducationalMetrics(userId);

    // Update user progress
    app_models.UserProgress updatedProgress = userProgress;

    // Update concepts mastered
    final conceptMasteryLevels = educationalMetrics.conceptMasteryLevels;
    final masteredConcepts = conceptMasteryLevels.entries
        .where((entry) => entry.value >= 0.8)
        .map((entry) => entry.key)
        .toList();

    // Update concepts in progress
    final inProgressConcepts = conceptMasteryLevels.entries
        .where((entry) => entry.value >= 0.3 && entry.value < 0.8)
        .map((entry) => entry.key)
        .toList();

    // Update completed challenges
    final completedChallenges = metrics.challengeCompletions > 0
        ? await _getCompletedChallengeIds(userId)
        : userProgress.completedChallenges;

    // Update completed milestones
    // We're not using reachedMilestones in this version of the app model
    // but we'll keep the code for future reference
    // final reachedMilestones = await getReachedMilestones(userId);
    // We're not using completedMilestones in this version of the app model
    // but we'll keep the code for future reference
    // final completedMilestones = reachedMilestones
    //     .map((milestone) => milestone.id)
    //     .toList();

    // Get learning path recommendation
    // We're not using recommendedPath in this version of the app model
    // but we'll keep the code for future reference
    // final recommendedPath = await getLearningPathRecommendation(userId);

    // Create updated progress
    // Create a new UserProgress with updated values
    updatedProgress = app_models.UserProgress(
      userId: userProgress.userId,
      name: userProgress.name,
      conceptsMastered: masteredConcepts,
      conceptsInProgress: inProgressConcepts,
      completedChallenges: completedChallenges,
      // Copy other fields from the original userProgress
      completedStories: userProgress.completedStories,
      completedStoryBranches: userProgress.completedStoryBranches,
      earnedBadges: userProgress.earnedBadges,
      storyMetrics: userProgress.storyMetrics,
      storyDecisions: userProgress.storyDecisions,
      learningMetrics: userProgress.learningMetrics,
      narrativeContext: userProgress.narrativeContext,
      skills: userProgress.skills,
      skillProficiency: userProgress.skillProficiency,
      challengeAttempts: userProgress.challengeAttempts,
      preferredLearningStyle: userProgress.preferredLearningStyle,
      learningStyleConfidence: userProgress.learningStyleConfidence,
      experiencePoints: userProgress.experiencePoints,
      level: userProgress.level,
      streak: userProgress.streak,
      lastActiveDate: userProgress.lastActiveDate,
      preferences: userProgress.preferences,
      engagementMetrics: userProgress.engagementMetrics,
      sessionHistory: userProgress.sessionHistory,
      totalTimeSpentMinutes: userProgress.totalTimeSpentMinutes,
    );

    // Save updated progress
    await _storageService.saveUserProgress(updatedProgress);

    return updatedProgress;
  }

  /// Get completed challenge IDs for a user
  Future<List<String>> _getCompletedChallengeIds(String userId) async {
    // This is a simplified implementation
    // A more sophisticated approach would use the challenge repository

    final events = await getEventsByType(userId, 'challenge_complete', limit: 100);

    return events
        .where((event) => event.details.containsKey('challenge_id'))
        .map((event) => event.details['challenge_id'] as String)
        .toSet()
        .toList();
  }
}
