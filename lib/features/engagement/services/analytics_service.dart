import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import '../models/engagement_event.dart';
import '../models/engagement_metrics.dart';
import '../models/engagement_milestone.dart';
import '../repositories/engagement_repository.dart';
import 'dart:math' as math;

/// Service for processing engagement data and generating analytics.
///
/// This service provides methods for analyzing engagement data,
/// calculating metrics, and generating insights.
class AnalyticsService {
  final EngagementRepository _repository;

  /// Create a new AnalyticsService.
  AnalyticsService({
    EngagementRepository? repository,
  }) : _repository = repository ?? EngagementRepository(StorageService().storage);

  /// Initialize the service.
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// Process an engagement event and update metrics.
  ///
  /// [event] is the engagement event to process.
  ///
  /// Returns the updated engagement metrics.
  Future<EngagementMetrics> processEvent(EngagementEvent event) async {
    // Save the event
    await _repository.saveEvent(event);

    // Get current metrics
    final userId = event.userId;
    EngagementMetrics metrics = await _repository.getMetrics(userId) ??
                               EngagementMetrics(userId: userId);

    // Update metrics based on the event
    metrics = await _updateMetricsForEvent(metrics, event);

    // Save updated metrics
    await _repository.saveMetrics(metrics);

    // Check for milestones
    await _checkMilestones(userId, metrics);

    return metrics;
  }

  /// Process multiple engagement events and update metrics.
  ///
  /// [events] is the list of engagement events to process.
  ///
  /// Returns the updated engagement metrics.
  Future<EngagementMetrics> processEvents(List<EngagementEvent> events) async {
    if (events.isEmpty) return EngagementMetrics(userId: '');

    // Save all events
    await _repository.saveEvents(events);

    // Get current metrics
    final userId = events.first.userId;
    EngagementMetrics metrics = await _repository.getMetrics(userId) ??
                               EngagementMetrics(userId: userId);

    // Update metrics for each event
    for (final event in events) {
      metrics = await _updateMetricsForEvent(metrics, event);
    }

    // Save updated metrics
    await _repository.saveMetrics(metrics);

    // Check for milestones
    await _checkMilestones(userId, metrics);

    return metrics;
  }

  /// Get engagement metrics for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the engagement metrics for the user.
  Future<EngagementMetrics> getMetrics(String userId) async {
    final metrics = await _repository.getMetrics(userId);
    return metrics ?? EngagementMetrics(userId: userId);
  }

  /// Get engagement summary for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a summary of engagement metrics for the user.
  Future<Map<String, dynamic>> getEngagementSummary(String userId) async {
    final metrics = await getMetrics(userId);
    return metrics.getEngagementSummary();
  }

  /// Get educational metrics for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the educational engagement metrics for the user.
  Future<EducationalEngagementMetrics> getEducationalMetrics(String userId) async {
    final metrics = await getMetrics(userId);
    return metrics.educationalMetrics;
  }

  /// Get engagement score for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the engagement score for the user.
  Future<double> getEngagementScore(String userId) async {
    final metrics = await getMetrics(userId);
    return metrics.calculateEngagementScore();
  }

  /// Get engagement milestones for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of all engagement milestones for the user.
  Future<List<EngagementMilestone>> getMilestones(String userId) async {
    return _repository.getAllMilestones(userId);
  }

  /// Get reached engagement milestones for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of reached engagement milestones for the user.
  Future<List<EngagementMilestone>> getReachedMilestones(String userId) async {
    return _repository.getReachedMilestones(userId);
  }

  /// Get next milestones for a user.
  ///
  /// [userId] is the ID of the user.
  /// [limit] is the maximum number of milestones to return.
  ///
  /// Returns a list of upcoming milestones for the user.
  Future<List<EngagementMilestone>> getNextMilestones(
    String userId, {
    int limit = 3,
  }) async {
    final unreachedMilestones = await _repository.getUnreachedMilestones(userId);
    final metrics = await getMetrics(userId);

    // Sort milestones by how close they are to being reached
    unreachedMilestones.sort((a, b) {
      final aProgress = _calculateMilestoneProgress(a, metrics);
      final bProgress = _calculateMilestoneProgress(b, metrics);
      return bProgress.compareTo(aProgress);
    });

    return unreachedMilestones.take(limit).toList();
  }

  /// Get engagement events for a user.
  ///
  /// [userId] is the ID of the user.
  /// [limit] is the maximum number of events to return.
  ///
  /// Returns a list of recent engagement events for the user.
  Future<List<EngagementEvent>> getRecentEvents(
    String userId, {
    int limit = 20,
  }) async {
    return _repository.getRecentEvents(userId, limit: limit);
  }

  /// Get engagement events by type.
  ///
  /// [userId] is the ID of the user.
  /// [eventType] is the type of events to retrieve.
  /// [limit] is the maximum number of events to return.
  ///
  /// Returns a list of engagement events of the specified type.
  Future<List<EngagementEvent>> getEventsByType(
    String userId,
    String eventType, {
    int limit = 20,
  }) async {
    return _repository.getEventsByType(userId, eventType, limit: limit);
  }

  /// Get engagement events for a specific challenge.
  ///
  /// [userId] is the ID of the user.
  /// [challengeId] is the ID of the challenge.
  ///
  /// Returns a list of engagement events for the specified challenge.
  Future<List<EngagementEvent>> getEventsForChallenge(
    String userId,
    String challengeId,
  ) async {
    return _repository.getEventsForChallenge(userId, challengeId);
  }

  /// Get engagement events for a specific story.
  ///
  /// [userId] is the ID of the user.
  /// [storyId] is the ID of the story.
  ///
  /// Returns a list of engagement events for the specified story.
  Future<List<EngagementEvent>> getEventsForStory(
    String userId,
    String storyId,
  ) async {
    return _repository.getEventsForStory(userId, storyId);
  }

  /// Get session data for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the session data for the user.
  Future<Map<String, dynamic>> getSessionData(String userId) async {
    final data = await _repository.getSessionData(userId);
    return data ?? {};
  }

  /// Start a new session for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the session data.
  Future<Map<String, dynamic>> startSession(String userId) async {
    final sessionData = {
      'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
      'start_time': DateTime.now().millisecondsSinceEpoch,
      'events': <Map<String, dynamic>>[],
    };

    await _repository.saveSessionData(userId, sessionData);

    // Create a session start event
    final event = EngagementEvent(
      id: 'session_start_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'session_start',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        'session_id': sessionData['session_id'],
      },
    );

    await processEvent(event);

    return sessionData;
  }

  /// End the current session for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the session data.
  Future<Map<String, dynamic>> endSession(String userId) async {
    final sessionData = await getSessionData(userId);

    if (sessionData.isEmpty) {
      return {};
    }

    // Calculate session duration
    final startTime = sessionData['start_time'] as int;
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final durationSeconds = (endTime - startTime) ~/ 1000;

    // Update session data
    sessionData['end_time'] = endTime;
    sessionData['duration_seconds'] = durationSeconds;

    await _repository.saveSessionData(userId, sessionData);

    // Create a session end event
    final event = EngagementEvent(
      id: 'session_end_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'session_end',
      timestamp: DateTime.now(),
      userId: userId,
      details: {
        'session_id': sessionData['session_id'],
        'duration_seconds': durationSeconds,
      },
    );

    await processEvent(event);

    // Clear session data
    await _repository.clearSessionData(userId);

    return sessionData;
  }

  /// Initialize default milestones for a user.
  ///
  /// [userId] is the ID of the user.
  Future<void> initializeDefaultMilestones(String userId) async {
    await _repository.initializeDefaultMilestones(userId);
  }

  /// Update metrics based on an engagement event.
  ///
  /// [metrics] is the current engagement metrics.
  /// [event] is the engagement event to process.
  ///
  /// Returns the updated engagement metrics.
  Future<EngagementMetrics> _updateMetricsForEvent(
    EngagementMetrics metrics,
    EngagementEvent event,
  ) async {
    // Update basic metrics
    int totalEngagementTimeSeconds = metrics.totalEngagementTimeSeconds;
    int interactionCount = metrics.interactionCount + 1;
    int challengeAttempts = metrics.challengeAttempts;
    int challengeCompletions = metrics.challengeCompletions;
    int storyProgression = metrics.storyProgression;
    Map<String, int> activityCounts = Map<String, int>.from(metrics.activityCounts);
    DateTime lastInteractionTime = event.timestamp;
    DateTime firstInteractionTime = metrics.firstInteractionTime;
    int uniqueActiveDays = metrics.uniqueActiveDays;

    // Update first interaction time if this is the first event
    if (metrics.interactionCount == 0) {
      firstInteractionTime = event.timestamp;
    }

    // Update activity counts
    final eventType = event.eventType;
    activityCounts[eventType] = (activityCounts[eventType] ?? 0) + 1;

    // Update time-based metrics
    final duration = event.getDuration();
    if (duration != null) {
      totalEngagementTimeSeconds += duration.inSeconds;
    }

    // Update challenge metrics
    if (eventType == 'challenge_attempt') {
      challengeAttempts++;
    } else if (eventType == 'challenge_complete') {
      challengeCompletions++;
    }

    // Update story metrics
    if (eventType == 'story_progress') {
      storyProgression++;
    }

    // Update unique active days
    final today = DateTime(
      event.timestamp.year,
      event.timestamp.month,
      event.timestamp.day,
    );
    final lastDay = DateTime(
      metrics.lastInteractionTime.year,
      metrics.lastInteractionTime.month,
      metrics.lastInteractionTime.day,
    );

    if (today != lastDay) {
      uniqueActiveDays++;
    }

    // Update educational metrics
    EducationalEngagementMetrics educationalMetrics = await _updateEducationalMetrics(
      metrics.educationalMetrics,
      event,
    );

    // Create updated metrics
    return metrics.copyWith(
      totalEngagementTimeSeconds: totalEngagementTimeSeconds,
      interactionCount: interactionCount,
      challengeAttempts: challengeAttempts,
      challengeCompletions: challengeCompletions,
      storyProgression: storyProgression,
      activityCounts: activityCounts,
      lastInteractionTime: lastInteractionTime,
      firstInteractionTime: firstInteractionTime,
      uniqueActiveDays: uniqueActiveDays,
      educationalMetrics: educationalMetrics,
    );
  }

  /// Update educational metrics based on an engagement event.
  ///
  /// [educationalMetrics] is the current educational engagement metrics.
  /// [event] is the engagement event to process.
  ///
  /// Returns the updated educational engagement metrics.
  Future<EducationalEngagementMetrics> _updateEducationalMetrics(
    EducationalEngagementMetrics educationalMetrics,
    EngagementEvent event,
  ) async {
    // Only update educational metrics for educational events
    if (!event.isEducationalEvent()) {
      return educationalMetrics;
    }

    // Get current values
    Map<String, double> conceptMasteryLevels = Map<String, double>.from(educationalMetrics.conceptMasteryLevels);
    Map<String, int> standardsDemonstrated = Map<String, int>.from(educationalMetrics.standardsDemonstrated);
    Map<String, bool> learningObjectivesCompleted = Map<String, bool>.from(educationalMetrics.learningObjectivesCompleted);
    int educationalMilestonesReached = educationalMetrics.educationalMilestonesReached;
    double averageTimePerEducationalActivity = educationalMetrics.averageTimePerEducationalActivity;

    // Update concept mastery levels
    final concepts = event.getEducationalConcepts();
    for (final concept in concepts) {
      // Get current mastery level
      final currentLevel = conceptMasteryLevels[concept] ?? 0.0;

      // Update mastery level based on event type
      double newLevel = currentLevel;
      if (event.eventType == 'challenge_complete' && event.getSuccessStatus() == true) {
        // Successful challenge completion increases mastery
        newLevel = math.min(currentLevel + 0.1, 1.0);
      } else if (event.eventType == 'challenge_attempt' && event.getSuccessStatus() == false) {
        // Failed challenge attempt slightly decreases mastery
        newLevel = math.max(currentLevel - 0.05, 0.0);
      } else if (event.eventType == 'story_progress') {
        // Story progression slightly increases mastery
        newLevel = math.min(currentLevel + 0.05, 1.0);
      }

      // Update mastery level
      conceptMasteryLevels[concept] = newLevel;
    }

    // Update standards demonstrated
    final standards = event.getEducationalStandards();
    for (final standard in standards) {
      standardsDemonstrated[standard] = (standardsDemonstrated[standard] ?? 0) + 1;
    }

    // Update learning objectives
    if (event.details.containsKey('learning_objective')) {
      final objective = event.details['learning_objective'] as String;
      final completed = event.details['completed'] as bool? ?? true;
      learningObjectivesCompleted[objective] = completed;
    }

    // Update educational milestones
    if (event.isMilestone() && event.isEducational) {
      educationalMilestonesReached++;
    }

    // Update average time per educational activity
    if (event.getDuration() != null) {
      final duration = event.getDuration()!.inSeconds;
      final totalActivities = educationalMetrics.standardsDemonstratedCount +
                             educationalMetrics.conceptsMasteredCount;

      if (totalActivities > 0) {
        final totalTime = averageTimePerEducationalActivity * totalActivities;
        averageTimePerEducationalActivity = (totalTime + duration) / (totalActivities + 1);
      } else {
        averageTimePerEducationalActivity = duration.toDouble();
      }
    }

    // Create updated educational metrics
    return educationalMetrics.copyWith(
      conceptMasteryLevels: conceptMasteryLevels,
      standardsDemonstrated: standardsDemonstrated,
      learningObjectivesCompleted: learningObjectivesCompleted,
      educationalMilestonesReached: educationalMilestonesReached,
      averageTimePerEducationalActivity: averageTimePerEducationalActivity,
    );
  }

  /// Check for milestones based on engagement metrics.
  ///
  /// [userId] is the ID of the user.
  /// [metrics] is the current engagement metrics.
  Future<void> _checkMilestones(String userId, EngagementMetrics metrics) async {
    // Get all milestones
    final milestones = await _repository.getAllMilestones(userId);

    // If no milestones exist, initialize default milestones
    if (milestones.isEmpty) {
      await initializeDefaultMilestones(userId);
      return;
    }

    // Check each milestone
    for (final milestone in milestones) {
      // Skip already reached milestones
      if (milestone.isReached) continue;

      // Check if milestone is reached
      bool isReached = false;

      switch (milestone.type) {
        case 'engagement_hours':
          isReached = metrics.totalEngagementTimeHours >= milestone.value;
          break;
        case 'interactions':
          isReached = metrics.interactionCount >= milestone.value;
          break;
        case 'challenges_completed':
          isReached = metrics.challengeCompletions >= milestone.value;
          break;
        case 'stories_progressed':
          isReached = metrics.storyProgression >= milestone.value;
          break;
        case 'concepts_mastered':
          isReached = metrics.educationalMetrics.conceptsMasteredCount >= milestone.value;
          break;
        case 'standards_demonstrated':
          isReached = metrics.educationalMetrics.standardsDemonstratedCount >= milestone.value;
          break;
        case 'learning_objectives_completed':
          isReached = metrics.educationalMetrics.learningObjectivesCompletedCount >= milestone.value;
          break;
      }

      // If milestone is reached, update it
      if (isReached) {
        final updatedMilestone = milestone.markAsReached();
        await _repository.saveMilestone(userId, updatedMilestone);

        // Create a milestone reached event
        final event = EngagementEvent(
          id: 'milestone_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}',
          eventType: 'milestone_reached',
          timestamp: DateTime.now(),
          userId: userId,
          details: {
            'milestone_id': milestone.id,
            'milestone_name': milestone.name,
            'milestone_type': milestone.type,
            'milestone_value': milestone.value,
          },
          educationalContext: milestone.educationalContext,
        );

        await _repository.saveEvent(event);
      }
    }
  }

  /// Calculate progress towards a milestone.
  ///
  /// [milestone] is the milestone to check.
  /// [metrics] is the current engagement metrics.
  ///
  /// Returns a value between 0.0 and 1.0 representing progress.
  double _calculateMilestoneProgress(
    EngagementMilestone milestone,
    EngagementMetrics metrics,
  ) {
    double progress = 0.0;

    switch (milestone.type) {
      case 'engagement_hours':
        progress = metrics.totalEngagementTimeHours / milestone.value;
        break;
      case 'interactions':
        progress = metrics.interactionCount / milestone.value;
        break;
      case 'challenges_completed':
        progress = metrics.challengeCompletions / milestone.value;
        break;
      case 'stories_progressed':
        progress = metrics.storyProgression / milestone.value;
        break;
      case 'concepts_mastered':
        progress = metrics.educationalMetrics.conceptsMasteredCount / milestone.value;
        break;
      case 'standards_demonstrated':
        progress = metrics.educationalMetrics.standardsDemonstratedCount / milestone.value;
        break;
      case 'learning_objectives_completed':
        progress = metrics.educationalMetrics.learningObjectivesCompletedCount / milestone.value;
        break;
    }

    return math.min(progress, 1.0);
  }
}
