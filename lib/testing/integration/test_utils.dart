import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/storytelling/models/enhanced_story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';

import 'package:kente_codeweaver/features/challenges/models/challenge_model.dart';
import 'package:kente_codeweaver/features/engagement/models/engagement_event.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

/// Utility class for integration testing.
class IntegrationTestUtils {
  /// Create a test storage service that uses in-memory storage.
  static StorageService createTestStorageService() {
    // Create a new storage service
    final storageService = StorageService();
    // Initialize the service
    // Note: In a real test, you would need to mock the dependencies
    // or use a test-specific implementation
    return storageService;
  }

  /// Create a test user ID for testing.
  static String createTestUserId() {
    return 'test_user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create a test user progress for testing.
  static UserProgress createTestUserProgress({
    String? userId,
    List<String>? conceptsMastered,
    List<String>? conceptsInProgress,
    List<String>? completedChallenges,
    List<String>? completedMilestones,
    LearningPathType? learningPathType,
  }) {
    return UserProgress(
      userId: userId ?? createTestUserId(),
      name: 'Test User',
      completedStories: [],
      completedStoryBranches: [],
      completedMilestones: completedMilestones ?? ['milestone_1'],
      earnedBadges: [],
      storyMetrics: {},
      storyDecisions: {},
      learningMetrics: {},
      narrativeContext: {},
      skills: {},
      skillProficiency: {},
      conceptsMastered: conceptsMastered ?? ['sequences', 'loops'],
      conceptsInProgress: conceptsInProgress ?? ['conditionals', 'variables'],
      challengeAttempts: {},
      completedChallenges: completedChallenges ?? ['challenge_1', 'challenge_2'],
      preferredLearningStyle: LearningStyle.visual,
      learningPathType: learningPathType ?? LearningPathType.balanced,
      learningStyleConfidence: {},
      experiencePoints: 0,
      level: 1,
      streak: 0,
      lastActiveDate: DateTime.now(),
      preferences: {},
      engagementMetrics: {},
      sessionHistory: [],
      totalTimeSpentMinutes: 0,
    );
  }

  /// Create a test story for testing.
  static EnhancedStoryModel createTestStory({
    String? id,
    String? title,
    String? theme,
    String? region,
    String? characterName,
    String? ageGroup,
    List<ContentBlockModel>? content,
    List<String>? learningConcepts,
    int? difficultyLevel,
    List<String>? educationalStandards,
    List<String>? learningObjectives,
  }) {
    return EnhancedStoryModel(
      id: id,
      title: title ?? 'Test Story',
      theme: theme ?? 'wisdom',
      region: region ?? 'Ghana',
      characterName: characterName ?? 'Kwame',
      ageGroup: ageGroup ?? '7-12',
      content: content ?? [],
      learningConcepts: learningConcepts ?? ['sequences', 'loops'],
      difficultyLevel: difficultyLevel ?? 2,
      educationalStandards: educationalStandards ?? ['CSTA-1A-AP-10', 'K12CS-P4.1'],
      learningObjectives: learningObjectives ?? ['Create a sequence of instructions', 'Use loops to repeat actions'],
    );
  }

  /// Create a test challenge for testing.
  static ChallengeModel createTestChallenge({
    String? id,
    String? type,
    String? title,
    String? description,
    int? difficulty,
    List<String>? requiredConcepts,
    List<String>? availableBlockTypes,
    LearningPathType? learningPathType,
  }) {
    // Create a simple challenge model for testing
    return ChallengeModel(
      id: id ?? 'test_challenge_${DateTime.now().millisecondsSinceEpoch}',
      type: type ?? 'pattern',
      title: title ?? 'Test Challenge',
      description: description ?? 'Create a pattern using move and turn blocks.',
      difficulty: difficulty ?? 2,
      requiredConcepts: requiredConcepts ?? ['sequences', 'loops'],
      successCriteria: _createTestSuccessCriteria(availableBlockTypes),
      availableBlockTypes: availableBlockTypes ?? ['move', 'turn', 'loop', 'condition'],
      hints: ['Start by placing a move block.', 'Connect blocks to create a pattern.'],
      tags: ['test', 'pattern', 'sequences', 'loops'],
      learningPathType: learningPathType ?? LearningPathType.balanced,
    );
  }

  /// Create a test success criteria for testing.
  static SuccessCriteria _createTestSuccessCriteria(List<String>? availableBlockTypes) {
    return SuccessCriteria(
      requiresBlockType: availableBlockTypes ?? ['move', 'turn', 'loop'],
      minConnections: 4,
    );
  }

  /// Create a test engagement event for testing.
  static EngagementEvent createTestEngagementEvent({
    String? id,
    String? eventType,
    String? userId,
    Map<String, dynamic>? details,
    String? educationalContext,
  }) {
    return EngagementEvent(
      id: id ?? 'test_event_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType ?? 'interaction',
      timestamp: DateTime.now(),
      userId: userId ?? createTestUserId(),
      details: details ?? {},
      educationalContext: educationalContext,
    );
  }



  /// Wait for a specified duration.
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Log a message for testing.
  static void log(String message) {
    debugPrint('[IntegrationTest] $message');
  }
}
