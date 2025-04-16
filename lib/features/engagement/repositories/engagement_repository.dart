import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/base_repository.dart';
import 'package:kente_codeweaver/core/services/storage/storage_strategy.dart';
import '../models/engagement_event.dart';
import '../models/engagement_metrics.dart';
import '../models/engagement_milestone.dart';

/// Repository for managing engagement data.
///
/// This repository handles the storage and retrieval of engagement events,
/// metrics, and milestones.
class EngagementRepository implements BaseRepository {
  final StorageStrategy _storage;

  static const String _eventsKeyPrefix = 'engagement_events_';
  static const String _metricsKey = 'engagement_metrics_';
  static const String _milestonesKeyPrefix = 'engagement_milestones_';
  static const String _recentEventsKey = 'recent_engagement_events_';
  static const String _sessionKeyPrefix = 'engagement_session_';

  /// Create a new EngagementRepository.
  ///
  /// [storage] is the storage strategy to use for data persistence.
  EngagementRepository(this._storage);

  @override
  StorageStrategy get storage => _storage;

  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }

  /// Save an engagement event.
  ///
  /// [event] is the engagement event to save.
  Future<void> saveEvent(EngagementEvent event) async {
    // Generate a key for the event
    final key = '${_eventsKeyPrefix}${event.userId}_${event.id}';

    // Save the event
    await _storage.saveData(key, event.toJson());

    // Update recent events
    await _updateRecentEvents(event);
  }

  /// Save multiple engagement events.
  ///
  /// [events] is the list of engagement events to save.
  Future<void> saveEvents(List<EngagementEvent> events) async {
    for (final event in events) {
      await saveEvent(event);
    }
  }

  /// Get an engagement event by ID.
  ///
  /// [userId] is the ID of the user.
  /// [eventId] is the ID of the event.
  ///
  /// Returns the engagement event if found, or null if not found.
  Future<EngagementEvent?> getEvent(String userId, String eventId) async {
    final key = '${_eventsKeyPrefix}${userId}_$eventId';
    final data = await _storage.getData(key);

    if (data == null) return null;

    try {
      return EngagementEvent.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing engagement event: $e');
      return null;
    }
  }

  /// Get recent engagement events for a user.
  ///
  /// [userId] is the ID of the user.
  /// [limit] is the maximum number of events to return.
  ///
  /// Returns a list of recent engagement events.
  Future<List<EngagementEvent>> getRecentEvents(String userId, {int limit = 20}) async {
    final key = '${_recentEventsKey}$userId';
    final data = await _storage.getData(key);

    if (data == null) return [];

    try {
      final eventsList = List<Map<String, dynamic>>.from(data);
      final events = eventsList
          .map((eventData) => EngagementEvent.fromJson(eventData))
          .toList();

      // Sort by timestamp (newest first)
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit the number of events
      return events.take(limit).toList();
    } catch (e) {
      debugPrint('Error parsing recent engagement events: $e');
      return [];
    }
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
    final recentEvents = await getRecentEvents(userId, limit: 100);

    // Filter events by type
    final filteredEvents = recentEvents
        .where((event) => event.eventType == eventType)
        .toList();

    // Sort by timestamp (newest first)
    filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Limit the number of events
    return filteredEvents.take(limit).toList();
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
    final recentEvents = await getRecentEvents(userId, limit: 100);

    // Filter events for the challenge
    return recentEvents
        .where((event) => event.isForChallenge(challengeId))
        .toList();
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
    final recentEvents = await getRecentEvents(userId, limit: 100);

    // Filter events for the story
    return recentEvents
        .where((event) => event.isForStory(storyId))
        .toList();
  }

  /// Save engagement metrics for a user.
  ///
  /// [metrics] is the engagement metrics to save.
  Future<void> saveMetrics(EngagementMetrics metrics) async {
    final key = '${_metricsKey}${metrics.userId}';
    await _storage.saveData(key, metrics.toJson());
  }

  /// Get engagement metrics for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the engagement metrics if found, or null if not found.
  Future<EngagementMetrics?> getMetrics(String userId) async {
    final key = '${_metricsKey}$userId';
    final data = await _storage.getData(key);

    if (data == null) return null;

    try {
      return EngagementMetrics.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing engagement metrics: $e');
      return null;
    }
  }

  /// Save an engagement milestone.
  ///
  /// [userId] is the ID of the user.
  /// [milestone] is the engagement milestone to save.
  Future<void> saveMilestone(String userId, EngagementMilestone milestone) async {
    final key = '${_milestonesKeyPrefix}${userId}_${milestone.id}';
    await _storage.saveData(key, milestone.toJson());

    // Update milestone list
    await _updateMilestoneList(userId, milestone.id);
  }

  /// Get an engagement milestone by ID.
  ///
  /// [userId] is the ID of the user.
  /// [milestoneId] is the ID of the milestone.
  ///
  /// Returns the engagement milestone if found, or null if not found.
  Future<EngagementMilestone?> getMilestone(String userId, String milestoneId) async {
    final key = '${_milestonesKeyPrefix}${userId}_$milestoneId';
    final data = await _storage.getData(key);

    if (data == null) return null;

    try {
      return EngagementMilestone.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing engagement milestone: $e');
      return null;
    }
  }

  /// Get all engagement milestones for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of all engagement milestones for the user.
  Future<List<EngagementMilestone>> getAllMilestones(String userId) async {
    final milestoneIds = await _getMilestoneIds(userId);
    final milestones = <EngagementMilestone>[];

    for (final id in milestoneIds) {
      final milestone = await getMilestone(userId, id);
      if (milestone != null) {
        milestones.add(milestone);
      }
    }

    return milestones;
  }

  /// Get reached engagement milestones for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of reached engagement milestones for the user.
  Future<List<EngagementMilestone>> getReachedMilestones(String userId) async {
    final allMilestones = await getAllMilestones(userId);

    // Filter reached milestones
    return allMilestones
        .where((milestone) => milestone.isReached)
        .toList();
  }

  /// Get unreached engagement milestones for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of unreached engagement milestones for the user.
  Future<List<EngagementMilestone>> getUnreachedMilestones(String userId) async {
    final allMilestones = await getAllMilestones(userId);

    // Filter unreached milestones
    return allMilestones
        .where((milestone) => !milestone.isReached)
        .toList();
  }

  /// Save session data for a user.
  ///
  /// [userId] is the ID of the user.
  /// [sessionData] is the session data to save.
  Future<void> saveSessionData(String userId, Map<String, dynamic> sessionData) async {
    final key = '${_sessionKeyPrefix}$userId';
    await _storage.saveData(key, sessionData);
  }

  /// Get session data for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns the session data if found, or null if not found.
  Future<Map<String, dynamic>?> getSessionData(String userId) async {
    final key = '${_sessionKeyPrefix}$userId';
    final data = await _storage.getData(key);

    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('Error parsing session data: $e');
      return null;
    }
  }

  /// Clear session data for a user.
  ///
  /// [userId] is the ID of the user.
  Future<void> clearSessionData(String userId) async {
    final key = '${_sessionKeyPrefix}$userId';
    await _storage.removeData(key);
  }

  /// Initialize default milestones for a user.
  ///
  /// [userId] is the ID of the user.
  Future<void> initializeDefaultMilestones(String userId) async {
    final defaultMilestones = EngagementMilestone.getDefaultMilestones();

    for (final milestone in defaultMilestones) {
      await saveMilestone(userId, milestone);
    }
  }

  /// Update the list of recent events.
  ///
  /// [event] is the new event to add to the list.
  Future<void> _updateRecentEvents(EngagementEvent event) async {
    final userId = event.userId;
    final key = '${_recentEventsKey}$userId';

    // Get existing recent events
    final data = await _storage.getData(key);
    List<Map<String, dynamic>> recentEvents = [];

    if (data != null) {
      try {
        recentEvents = List<Map<String, dynamic>>.from(data);
      } catch (e) {
        debugPrint('Error parsing recent events: $e');
      }
    }

    // Add the new event
    recentEvents.add(event.toJson());

    // Keep the list at a reasonable size (100 most recent events)
    if (recentEvents.length > 100) {
      recentEvents = recentEvents.sublist(recentEvents.length - 100);
    }

    // Save the updated list
    await _storage.saveData(key, recentEvents);
  }

  /// Update the list of milestone IDs.
  ///
  /// [userId] is the ID of the user.
  /// [milestoneId] is the ID of the milestone to add.
  Future<void> _updateMilestoneList(String userId, String milestoneId) async {
    final milestoneIds = await _getMilestoneIds(userId);

    if (!milestoneIds.contains(milestoneId)) {
      milestoneIds.add(milestoneId);
      await _storage.saveData('${_milestonesKeyPrefix}${userId}_ids', milestoneIds);
    }
  }

  /// Get the list of milestone IDs for a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of milestone IDs.
  Future<List<String>> _getMilestoneIds(String userId) async {
    final key = '${_milestonesKeyPrefix}${userId}_ids';
    final data = await _storage.getData(key);

    if (data == null) return [];

    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing milestone IDs: $e');
      return [];
    }
  }
}
