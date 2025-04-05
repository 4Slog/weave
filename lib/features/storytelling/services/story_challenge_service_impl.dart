import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/storytelling/interfaces/story_challenge_interface.dart';

/// Implementation of the StoryChallengeInterface
class StoryChallengeServiceImpl implements StoryChallengeInterface {
  /// Story provider - used for story-related operations
  final StoryProvider _storyProvider;

  /// Learning provider
  final LearningProvider _learningProvider;

  /// Constructor
  StoryChallengeServiceImpl({
    required StoryProvider storyProvider,
    required LearningProvider learningProvider,
  }) : _storyProvider = storyProvider,
       _learningProvider = learningProvider;

  /// Factory constructor to create from BuildContext
  factory StoryChallengeServiceImpl.fromContext(BuildContext context) {
    return StoryChallengeServiceImpl(
      storyProvider: Provider.of<StoryProvider>(context, listen: false),
      learningProvider: Provider.of<LearningProvider>(context, listen: false),
    );
  }

  @override
  List<BlockType> getRequiredBlockTypes(String storyId) {
    // Convert string block types to BlockType enum values
    final List<String> stringTypes = _getRequiredBlockTypesAsStrings(storyId);
    return stringTypes.map((type) => _stringToBlockType(type)).toList();
  }

  /// Helper method to get required block types as strings
  List<String> _getRequiredBlockTypesAsStrings(String storyId) {
    // For now, return mock data
    switch (storyId) {
      case 'story_001':
        return ['start', 'action', 'end'];
      case 'story_002':
        return ['start', 'condition', 'action', 'end'];
      case 'story_003':
        return ['start', 'loop', 'action', 'end'];
      default:
        return ['start', 'action', 'end'];
    }
  }

  @override
  Future<void> onChallengeCompleted(
    String storyId,
    String challengeId,
    bool success,
  ) async {
    if (!success) return;

    // Mark challenge as completed
    await _learningProvider.markChallengeCompleted(challengeId);

    // Check if all challenges for this story are completed
    final allChallenges = getAllChallenges(storyId);
    final allCompleted = allChallenges.every(
      (challengeId) => _learningProvider.isChallengeCompleted(challengeId),
    );

    if (allCompleted) {
      // Mark story as completed
      // Mark story as completed in the story provider
      // This is a placeholder - implement actual method in StoryProvider
      debugPrint('Story $storyId completed');
    }
  }

  /// Get the next challenge in a story
  String? getNextChallenge(String storyId, String currentChallengeId) {
    final allChallenges = getAllChallenges(storyId);

    if (currentChallengeId.isEmpty) {
      // Return the first challenge
      return allChallenges.isNotEmpty ? allChallenges.first : null;
    }

    final currentIndex = allChallenges.indexOf(currentChallengeId);
    if (currentIndex == -1 || currentIndex >= allChallenges.length - 1) {
      return null;
    }

    return allChallenges[currentIndex + 1];
  }

  /// Get the difficulty level of a challenge
  Future<int> getDifficultyLevel(String storyId, String challengeId) async {
    // For now, return mock data
    switch (storyId) {
      case 'story_001':
        return 1;
      case 'story_002':
        return 2;
      case 'story_003':
        return 3;
      default:
        return 1;
    }
  }

  /// Check if a challenge is completed
  Future<bool> isChallengeCompleted(String storyId, String challengeId) async {
    return _learningProvider.isChallengeCompleted(challengeId);
  }

  /// Get a hint for a challenge
  String getHint(String storyId, String challengeId) {
    // For now, return mock data
    switch (challengeId) {
      case 'challenge_001':
        return 'Try connecting the start block to the action block, then to the end block.';
      case 'challenge_002':
        return 'Use a condition block to check if a value is true or false.';
      case 'challenge_003':
        return 'Use a loop block to repeat an action multiple times.';
      default:
        return 'Connect the blocks in a logical sequence.';
    }
  }

  /// Get all challenges for a story
  List<String> getAllChallenges(String storyId) {
    // For now, return mock data
    switch (storyId) {
      case 'story_001':
        return ['challenge_001', 'challenge_002', 'challenge_003'];
      case 'story_002':
        return ['challenge_004', 'challenge_005', 'challenge_006'];
      case 'story_003':
        return ['challenge_007', 'challenge_008', 'challenge_009'];
      default:
        return [];
    }
  }

  /// Get the progress of a story
  double getStoryProgress(String storyId) {
    final allChallenges = getAllChallenges(storyId);
    if (allChallenges.isEmpty) return 0.0;

    final completedCount = allChallenges.where(
      (challengeId) => _learningProvider.isChallengeCompleted(challengeId),
    ).length;

    return completedCount / allChallenges.length;
  }

  /// Reset a challenge
  Future<void> resetChallenge(String storyId, String challengeId) async {
    // For now, do nothing
  }

  /// Convert string to BlockType enum
  BlockType _stringToBlockType(String typeStr) {
    return BlockType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => BlockType.pattern,
    );
  }

  @override
  int getChallengeDifficulty(String storyId) {
    // For now, return a default difficulty
    return 1;
  }
}
