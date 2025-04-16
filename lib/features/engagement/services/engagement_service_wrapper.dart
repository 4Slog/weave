import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'engagement_service_refactored.dart';

/// Wrapper for the refactored engagement service to maintain backward compatibility.
///
/// This wrapper provides the same API as the original EngagementService,
/// but uses the refactored implementation internally.
class EngagementService {
  /// The refactored engagement service
  final EngagementServiceRefactored _refactoredService;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new EngagementService with optional dependencies
  EngagementService({
    EngagementServiceRefactored? refactoredService,
  }) :
    _refactoredService = refactoredService ?? EngagementServiceRefactored();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the refactored service
      await _refactoredService.initialize();

      _isInitialized = true;
      debugPrint('EngagementService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize EngagementService: $e');
      throw Exception('Failed to initialize EngagementService: $e');
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
  Future<void> trackInteraction({
    required String userId,
    required String interactionType,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.trackInteraction(
      userId: userId,
      interactionType: interactionType,
      details: details,
    );
  }

  /// Track a challenge attempt
  ///
  /// [userId] is the ID of the user
  /// [challengeId] is the ID of the challenge
  /// [success] indicates whether the attempt was successful
  /// [details] is additional details about the attempt
  Future<void> trackChallengeAttempt({
    required String userId,
    required String challengeId,
    required bool success,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.trackChallengeAttempt(
      userId: userId,
      challengeId: challengeId,
      success: success,
      details: details,
    );
  }

  /// Track story progress
  ///
  /// [userId] is the ID of the user
  /// [storyId] is the ID of the story
  /// [progress] is the progress percentage (0.0 to 1.0)
  /// [details] is additional details about the progress
  Future<void> trackStoryProgress({
    required String userId,
    required String storyId,
    required double progress,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.trackStoryProgress(
      userId: userId,
      storyId: storyId,
      progress: progress,
      details: details,
    );
  }

  /// Track session time
  ///
  /// [userId] is the ID of the user
  /// [durationSeconds] is the duration of the session in seconds
  /// [details] is additional details about the session
  Future<void> trackSessionTime({
    required String userId,
    required int durationSeconds,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.trackSessionTime(
      userId: userId,
      durationSeconds: durationSeconds,
      details: details,
    );
  }

  /// Start a user session
  ///
  /// [userId] is the ID of the user
  /// [details] is additional details about the session
  Future<void> startSession({
    required String userId,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.startSession(
      userId: userId,
      details: details,
    );
  }

  /// End a user session
  ///
  /// [userId] is the ID of the user
  /// [details] is additional details about the session
  Future<void> endSession({
    required String userId,
    Map<String, dynamic> details = const {},
  }) async {
    await _ensureInitialized();

    await _refactoredService.endSession(
      userId: userId,
      details: details,
    );
  }

  /// Get engagement metrics for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a map of engagement metrics for the user
  Future<Map<String, dynamic>> getEngagementMetrics(String userId) async {
    await _ensureInitialized();

    final metrics = await _refactoredService.getEngagementMetrics(userId);
    return metrics.toJson();
  }

  /// Get engagement summary for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a summary of engagement metrics for the user
  Future<Map<String, dynamic>> getEngagementSummary(String userId) async {
    await _ensureInitialized();

    return _refactoredService.getEngagementSummary(userId);
  }

  /// Get engagement score for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns the engagement score for the user
  Future<double> getEngagementScore(String userId) async {
    await _ensureInitialized();

    return _refactoredService.getEngagementScore(userId);
  }

  /// Get milestones for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of milestone data for the user
  Future<List<Map<String, dynamic>>> getMilestones(String userId) async {
    await _ensureInitialized();

    final milestones = await _refactoredService.getMilestones(userId);
    return milestones.map((milestone) => milestone.toJson()).toList();
  }

  /// Get reached milestones for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of reached milestone data for the user
  Future<List<Map<String, dynamic>>> getReachedMilestones(String userId) async {
    await _ensureInitialized();

    final milestones = await _refactoredService.getReachedMilestones(userId);
    return milestones.map((milestone) => milestone.toJson()).toList();
  }

  /// Get next milestones for a user
  ///
  /// [userId] is the ID of the user
  /// [limit] is the maximum number of milestones to return
  ///
  /// Returns a list of upcoming milestone data for the user
  Future<List<Map<String, dynamic>>> getNextMilestones(
    String userId, {
    int limit = 3,
  }) async {
    await _ensureInitialized();

    final milestones = await _refactoredService.getNextMilestones(userId, limit: limit);
    return milestones.map((milestone) => milestone.toJson()).toList();
  }

  /// Get learning path recommendation for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a recommended learning path type as a string
  Future<String> getLearningPathRecommendation(String userId) async {
    await _ensureInitialized();

    final pathType = await _refactoredService.getLearningPathRecommendation(userId);
    return pathType.toString().split('.').last;
  }

  /// Get learning recommendations for a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of learning recommendations
  Future<List<Map<String, dynamic>>> getLearningRecommendations(String userId) async {
    await _ensureInitialized();

    return _refactoredService.getLearningRecommendations(userId);
  }

  /// Update user progress based on engagement metrics
  ///
  /// [userProgress] is the current user progress
  ///
  /// Returns updated user progress
  Future<UserProgress> updateUserProgress(UserProgress userProgress) async {
    await _ensureInitialized();

    return _refactoredService.updateUserProgress(userProgress);
  }

  /// Check for milestones based on user progress
  ///
  /// [userProgress] is the current user progress
  ///
  /// Returns a milestone if reached, null otherwise
  Future<Map<String, dynamic>?> checkMilestone(UserProgress userProgress) async {
    await _ensureInitialized();

    final userId = userProgress.userId;

    // Get next milestones
    final nextMilestones = await _refactoredService.getNextMilestones(userId, limit: 1);

    // If there are no next milestones, return null
    if (nextMilestones.isEmpty) return null;

    // Get the next milestone
    final nextMilestone = nextMilestones.first;

    // If the milestone is already reached, return it
    if (nextMilestone.isReached) {
      return {
        'id': nextMilestone.id,
        'name': nextMilestone.name,
        'description': nextMilestone.description,
        'reward': nextMilestone.reward,
        'educational_context': nextMilestone.educationalContext,
      };
    }

    // Otherwise, return null
    return null;
  }
}
