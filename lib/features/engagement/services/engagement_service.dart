import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/features/badges/services/badge_service.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';

/// Service that tracks and manages user engagement within the application.
///
/// This service monitors user activities, session duration, interaction patterns,
/// and provides engagement analytics to support adaptive learning.
class EngagementService {
  // Singleton implementation
  static final EngagementService _instance = EngagementService._internal();

  factory EngagementService() {
    return _instance;
  }

  EngagementService._internal();

  // Services
  final StorageService _storageService = StorageService();
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final BadgeService _badgeService = BadgeService();
  AudioService? _audioService;

  // Engagement metrics
  DateTime? _sessionStartTime;
  DateTime? _lastInteractionTime;
  int _totalEngagementTimeSeconds = 0;
  int _sessionEngagementTimeSeconds = 0;
  int _interactionCount = 0;
  int _challengeAttempts = 0;
  int _challengeCompletions = 0;
  int _storyProgression = 0;

  // Activity tracking
  final Map<String, int> _activityCounts = {};
  final List<Map<String, dynamic>> _engagementEvents = [];

  // Inactivity timer
  Timer? _inactivityTimer;
  bool _isActive = false;

  // Stream controller for engagement milestones
  final _engagementMilestoneController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get engagementMilestones => _engagementMilestoneController.stream;

  /// Initialize the engagement service
  Future<void> initialize({AudioService? audioService}) async {
    _audioService = audioService;

    // Load previous engagement metrics if available
    await _loadEngagementMetrics();

    // Start session tracking
    _startSession();
  }

  /// Load previously saved engagement metrics
  Future<void> _loadEngagementMetrics() async {
    try {
      // Get total engagement time
      final totalTime = await _storageService.getSetting('total_engagement_time');
      if (totalTime != null) {
        _totalEngagementTimeSeconds = int.tryParse(totalTime.toString()) ?? 0;
      }

      // Get interaction count
      final interactions = await _storageService.getSetting('total_interactions');
      if (interactions != null) {
        _interactionCount = int.tryParse(interactions.toString()) ?? 0;
      }

      // Get challenge metrics
      final attempts = await _storageService.getSetting('challenge_attempts');
      if (attempts != null) {
        _challengeAttempts = int.tryParse(attempts.toString()) ?? 0;
      }

      final completions = await _storageService.getSetting('challenge_completions');
      if (completions != null) {
        _challengeCompletions = int.tryParse(completions.toString()) ?? 0;
      }

      // Get story progression
      final progression = await _storageService.getSetting('story_progression');
      if (progression != null) {
        _storyProgression = int.tryParse(progression.toString()) ?? 0;
      }

      // Get activity counts
      final activityJsonStr = await _storageService.getSetting('activity_counts');
      if (activityJsonStr != null && activityJsonStr.isNotEmpty) {
        try {
          final activityJson = jsonDecode(activityJsonStr);
          if (activityJson is Map) {
            for (final entry in activityJson.entries) {
              _activityCounts[entry.key] = int.tryParse(entry.value.toString()) ?? 0;
            }
          }
        } catch (e) {
          debugPrint('Error parsing activity counts: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading engagement metrics: $e');
    }
  }

  /// Start a new session
  void _startSession() {
    _sessionStartTime = DateTime.now();
    _lastInteractionTime = _sessionStartTime;
    _sessionEngagementTimeSeconds = 0;
    _isActive = true;

    // Start inactivity timer to track session time accurately
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), _checkActivity);

    // Record session start event
    _recordEngagementEvent('session_start', {
      'timestamp': _sessionStartTime!.millisecondsSinceEpoch,
    });
  }

  /// End the current session
  Future<void> endSession() async {
    if (_sessionStartTime == null) return;

    // Calculate final session duration
    final endTime = DateTime.now();
    final sessionDuration = endTime.difference(_sessionStartTime!);
    _sessionEngagementTimeSeconds = sessionDuration.inSeconds;

    // Update total engagement time
    _totalEngagementTimeSeconds += _sessionEngagementTimeSeconds;

    // Record session end event
    _recordEngagementEvent('session_end', {
      'timestamp': endTime.millisecondsSinceEpoch,
      'duration_seconds': _sessionEngagementTimeSeconds,
    });

    // Cancel inactivity timer
    _inactivityTimer?.cancel();

    // Save engagement metrics
    await _saveEngagementMetrics();

    // Reset session data
    _sessionStartTime = null;
    _lastInteractionTime = null;
    _isActive = false;
  }

  /// Periodically check for user activity
  void _checkActivity(Timer timer) {
    if (_lastInteractionTime == null) return;

    final now = DateTime.now();
    final timeSinceLastInteraction = now.difference(_lastInteractionTime!);

    // If no interaction for 5 minutes, consider user inactive
    if (timeSinceLastInteraction.inMinutes >= 5) {
      if (_isActive) {
        _isActive = false;

        // Record inactivity event
        _recordEngagementEvent('user_inactive', {
          'timestamp': now.millisecondsSinceEpoch,
          'inactive_after_seconds': timeSinceLastInteraction.inSeconds,
        });
      }
    } else if (!_isActive) {
      // User has become active again
      _isActive = true;

      // Record activity resumed event
      _recordEngagementEvent('user_active', {
        'timestamp': now.millisecondsSinceEpoch,
      });
    }

    // Update session engagement time if active
    if (_isActive && _sessionStartTime != null) {
      final sessionDuration = now.difference(_sessionStartTime!);
      _sessionEngagementTimeSeconds = sessionDuration.inSeconds;
    }
  }

  /// Record user interaction
  void recordInteraction(String activityType, {Map<String, dynamic>? details}) {
    // Update last interaction time
    _lastInteractionTime = DateTime.now();
    _interactionCount++;

    // Ensure user is marked as active
    if (!_isActive) {
      _isActive = true;

      // Record activity resumed event
      _recordEngagementEvent('user_active', {
        'timestamp': _lastInteractionTime!.millisecondsSinceEpoch,
      });
    }

    // Track activity type
    _activityCounts[activityType] = (_activityCounts[activityType] ?? 0) + 1;

    // Record the interaction event
    _recordEngagementEvent('interaction', {
      'type': activityType,
      'timestamp': _lastInteractionTime!.millisecondsSinceEpoch,
      ...details ?? {},
    });

    // Check for engagement milestones
    _checkEngagementMilestones();
  }

  /// Record a challenge attempt
  Future<void> recordChallengeAttempt({
    required String challengeId,
    required bool success,
    int difficulty = 1,
    int attemptDurationSeconds = 0,
    Map<String, dynamic>? details,
  }) async {
    _challengeAttempts++;
    if (success) {
      _challengeCompletions++;
    }

    // Record the challenge event
    _recordEngagementEvent(success ? 'challenge_complete' : 'challenge_attempt', {
      'challenge_id': challengeId,
      'success': success,
      'difficulty': difficulty,
      'attempt_duration_seconds': attemptDurationSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...details ?? {},
    });

    // Record user interaction
    recordInteraction(
      success ? 'challenge_completion' : 'challenge_attempt',
      details: {
        'challenge_id': challengeId,
        'difficulty': difficulty,
      },
    );

    // Update adaptive learning metrics if successful
    if (success) {
      // Get the current user progress
      final userProgress = await _learningService.getUserProgress('current_user');
      if (userProgress != null) {
        // Update progress for challenge
        final updatedProgress = await _learningService.updateProgressForChallenge(
          userProgress: userProgress,
          challengeId: challengeId,
          requiredConcepts: ['loops', 'sequences'], // Default concepts for the challenge
          wasSuccessful: true,
        );

        // Save the updated progress
        await _learningService.saveUserProgress(updatedProgress);

        // Check for badges based on challenges
        _badgeService.checkForNewBadges(updatedProgress.userId);
      }
    }
  }

  /// Record story progression
  Future<void> recordStoryProgress({
    required String storyId,
    required int progressIndex,
    int totalBlocks = 0,
    Map<String, dynamic>? decisions,
  }) async {
    _storyProgression++;

    // Record the story progress event
    _recordEngagementEvent('story_progress', {
      'story_id': storyId,
      'progress_index': progressIndex,
      'total_blocks': totalBlocks,
      'decisions': decisions,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Record user interaction
    recordInteraction('story_progress', details: {
      'story_id': storyId,
      'progress_index': progressIndex,
    });

    // Play success sound if available
    _audioService?.playEffect(AudioType.achievement);

    // Check for story-related badges
    // Get the current user progress
    final userProgress = await _learningService.getUserProgress('current_user');
    if (userProgress != null) {
      _badgeService.checkForNewBadges(userProgress.userId);
    }
  }

  /// Record pattern creation
  void recordPatternCreation({
    required String patternId,
    required int blockCount,
    required int connectionCount,
    Map<String, dynamic>? metadata,
  }) {
    // Record the pattern creation event
    _recordEngagementEvent('pattern_creation', {
      'pattern_id': patternId,
      'block_count': blockCount,
      'connection_count': connectionCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...metadata ?? {},
    });

    // Record user interaction
    recordInteraction('pattern_creation', details: {
      'pattern_id': patternId,
      'block_count': blockCount,
      'connection_count': connectionCount,
    });
  }

  /// Record cultural exploration
  void recordCulturalExploration({
    required String contentType,
    required String contentId,
    int timeSpentSeconds = 0,
  }) {
    // Record the cultural exploration event
    _recordEngagementEvent('cultural_exploration', {
      'content_type': contentType,
      'content_id': contentId,
      'time_spent_seconds': timeSpentSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Record user interaction
    recordInteraction('cultural_exploration', details: {
      'content_type': contentType,
      'content_id': contentId,
      'time_spent_seconds': timeSpentSeconds,
    });
  }

  /// Record private engagement event (not directly triggered by user)
  void _recordEngagementEvent(String eventType, Map<String, dynamic> details) {
    final event = {
      'event_type': eventType,
      ...details,
    };

    _engagementEvents.add(event);

    // Keep event list at a reasonable size
    if (_engagementEvents.length > 100) {
      _engagementEvents.removeAt(0);
    }
  }

  /// Check for engagement milestones based on metrics
  void _checkEngagementMilestones() {
    // Time-based milestones (total engagement)
    final List<int> hourMilestones = [1, 5, 10, 20, 50, 100];
    final int totalHours = _totalEngagementTimeSeconds ~/ 3600;

    for (final milestone in hourMilestones) {
      if (totalHours == milestone) {
        _triggerEngagementMilestone('engagement_hours', milestone);
      }
    }

    // Interaction milestones
    final List<int> interactionMilestones = [100, 500, 1000, 5000, 10000];
    for (final milestone in interactionMilestones) {
      if (_interactionCount == milestone) {
        _triggerEngagementMilestone('interactions', milestone);
      }
    }

    // Challenge completion milestones
    final List<int> challengeMilestones = [1, 5, 10, 25, 50, 100];
    for (final milestone in challengeMilestones) {
      if (_challengeCompletions == milestone) {
        _triggerEngagementMilestone('challenges_completed', milestone);
      }
    }

    // Story progression milestones
    final List<int> storyMilestones = [1, 5, 10, 20, 50];
    for (final milestone in storyMilestones) {
      if (_storyProgression == milestone) {
        _triggerEngagementMilestone('stories_progressed', milestone);
      }
    }
  }

  /// Trigger an engagement milestone event
  void _triggerEngagementMilestone(String type, int value) {
    final milestone = {
      'type': type,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Send to stream
    _engagementMilestoneController.add(milestone);

    // Record the milestone event
    _recordEngagementEvent('milestone_reached', milestone);

    // Play achievement sound if available
    _audioService?.playEffect(AudioType.achievement);
  }

  /// Save current engagement metrics to storage
  Future<void> _saveEngagementMetrics() async {
    try {
      await _storageService.saveSetting('total_engagement_time', _totalEngagementTimeSeconds.toString());
      await _storageService.saveSetting('total_interactions', _interactionCount.toString());
      await _storageService.saveSetting('challenge_attempts', _challengeAttempts.toString());
      await _storageService.saveSetting('challenge_completions', _challengeCompletions.toString());
      await _storageService.saveSetting('story_progression', _storyProgression.toString());
      await _storageService.saveSetting('activity_counts', jsonEncode(_activityCounts));

      // Save recent engagement events
      await _storageService.saveSetting('recent_engagement_events', jsonEncode(_engagementEvents));
    } catch (e) {
      debugPrint('Error saving engagement metrics: $e');
    }
  }

  /// Get total engagement time in seconds
  int get totalEngagementTimeSeconds => _totalEngagementTimeSeconds;

  /// Get current session engagement time in seconds
  int get sessionEngagementTimeSeconds => _sessionEngagementTimeSeconds;

  /// Get total interaction count
  int get interactionCount => _interactionCount;

  /// Get challenge metrics
  Map<String, int> get challengeMetrics => {
    'attempts': _challengeAttempts,
    'completions': _challengeCompletions,
  };

  /// Get story progression count
  int get storyProgressionCount => _storyProgression;

  /// Get activity counts by type
  Map<String, int> get activityCounts => Map.unmodifiable(_activityCounts);

  /// Get engagement summary
  Map<String, dynamic> getEngagementSummary() {
    final now = DateTime.now();
    final activeSession = _sessionStartTime != null;

    return {
      'total_engagement_time_seconds': _totalEngagementTimeSeconds,
      'current_session_time_seconds': activeSession ? now.difference(_sessionStartTime!).inSeconds : 0,
      'total_interactions': _interactionCount,
      'challenge_attempts': _challengeAttempts,
      'challenge_completions': _challengeCompletions,
      'story_progression': _storyProgression,
      'activity_counts': _activityCounts,
      'active_session': activeSession,
      'current_active': _isActive,
    };
  }

  /// Get recent engagement events
  List<Map<String, dynamic>> getRecentEvents({int limit = 20}) {
    return _engagementEvents.reversed.take(limit).toList();
  }

  /// Calculate engagement score based on various metrics
  double calculateEngagementScore() {
    // Base score components
    double timeScore = math.min(_totalEngagementTimeSeconds / 3600, 10) * 10; // Max 10 hours = 100 points
    double interactionScore = math.min(_interactionCount / 1000, 10) * 10; // Max 1000 interactions = 100 points
    double challengeScore = math.min(_challengeCompletions / 50, 10) * 10; // Max 50 completions = 100 points
    double storyScore = math.min(_storyProgression / 20, 10) * 10; // Max 20 stories = 100 points

    // Calculate frequency and recency bonuses
    double frequencyBonus = 0;
    double recencyBonus = 0;

    // Bonus for frequency (daily use)
    if (_engagementEvents.length >= 2) {
      final Set<String> sessionDays = {};
      for (final event in _engagementEvents) {
        if (event['event_type'] == 'session_start') {
          final timestamp = event['timestamp'] as int;
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final dayKey = '${date.year}-${date.month}-${date.day}';
          sessionDays.add(dayKey);
        }
      }

      frequencyBonus = math.min(sessionDays.length * 5, 25); // Up to 25 points for 5+ unique days
    }

    // Bonus for recency (used in last 2 days)
    if (_lastInteractionTime != null) {
      final daysSinceLastInteraction = DateTime.now().difference(_lastInteractionTime!).inDays;
      if (daysSinceLastInteraction < 2) {
        recencyBonus = 25; // 25 points for recent use
      }
    }

    // Calculate overall score (maximum 400 + 50 = 450)
    final overallScore = timeScore + interactionScore + challengeScore + storyScore + frequencyBonus + recencyBonus;

    // Return normalized score out of 100
    return math.min((overallScore / 450) * 100, 100);
  }

  /// Dispose resources
  void dispose() {
    _inactivityTimer?.cancel();
    _engagementMilestoneController.close();
  }
}
