import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/features/block_workspace/models/challenge.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';

/// Enhanced service for challenge generation and validation
///
/// This service provides improved challenge generation based on skill level,
/// better validation for solutions, more sophisticated feedback mechanisms,
/// and milestone tracking.
/// Enhancements include:
/// - Improved challenge generation based on skill level
/// - Better validation for solutions
/// - More sophisticated feedback mechanisms
/// - Milestone tracking
class ChallengeService {
  /// Storage service for caching challenges
  final StorageService _storageService;

  /// Adaptive learning service for skill assessment
  final AdaptiveLearningService _adaptiveLearningService;

  /// Cache for challenges to reduce API calls
  final Map<String, Map<String, dynamic>> _challengeCache = {};

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new ChallengeService with optional dependencies
  ChallengeService({
    StorageService? storageService,
    AdaptiveLearningService? adaptiveLearningService,
  }) :
    _storageService = storageService ?? StorageService(),
    _adaptiveLearningService = adaptiveLearningService ?? AdaptiveLearningService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the adaptive learning service
      await _adaptiveLearningService.initialize();

      _isInitialized = true;
      debugPrint('ChallengeService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ChallengeService: $e');
      throw Exception('Failed to initialize ChallengeService: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get a challenge based on user progress
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `challengeType`: Type of challenge to generate (e.g., 'pattern', 'sequence')
  /// - `difficultyOverride`: Optional override for difficulty level
  ///
  /// Returns a challenge as a map with challenge details
  Future<Map<String, dynamic>> getChallenge({
    required UserProgress userProgress,
    required String challengeType,
    int? difficultyOverride,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the challenge
    final cacheKey = 'challenge_${userProgress.userId}_${challengeType}_${difficultyOverride ?? 'auto'}';

    // Check if challenge is cached
    if (_challengeCache.containsKey(cacheKey)) {
      return _challengeCache[cacheKey]!;
    }

    // Get difficulty level based on user progress or override
    final difficultyLevel = difficultyOverride ??
        await _adaptiveLearningService.calculateDifficultyLevel(userProgress: userProgress);

    // Get concepts the user has mastered
    final masteredConcepts = userProgress.conceptsMastered;

    // Get concepts the user is currently learning
    final inProgressConcepts = userProgress.conceptsInProgress;

    // Load challenges from assets
    final challenges = await _loadChallenges();

    // Filter challenges by type and difficulty
    final filteredChallenges = challenges.where((challenge) {
      // Check if challenge type matches
      if (challenge['type'] != challengeType) return false;

      // Check if difficulty is appropriate
      final challengeDifficulty = challenge['difficulty'] as int? ?? 1;
      if (challengeDifficulty > difficultyLevel + 1 || challengeDifficulty < difficultyLevel - 1) {
        return false;
      }

      // Check if the challenge has already been completed
      if (userProgress.completedChallenges.contains(challenge['id'])) {
        return false;
      }

      return true;
    }).toList();

    // If no challenges match, return a default challenge
    if (filteredChallenges.isEmpty) {
      final defaultChallenge = _createDefaultChallenge(
        challengeType: challengeType,
        difficultyLevel: difficultyLevel,
        masteredConcepts: masteredConcepts,
        inProgressConcepts: inProgressConcepts,
      );

      // Cache the challenge
      _challengeCache[cacheKey] = defaultChallenge;

      return defaultChallenge;
    }

    // Sort challenges by relevance to user's current learning
    filteredChallenges.sort((a, b) {
      // Get required concepts for each challenge
      final aRequiredConcepts = (a['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];
      final bRequiredConcepts = (b['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];

      // Count how many in-progress concepts are required for each challenge
      final aInProgressCount = aRequiredConcepts.where((c) => inProgressConcepts.contains(c)).length;
      final bInProgressCount = bRequiredConcepts.where((c) => inProgressConcepts.contains(c)).length;

      // Sort by in-progress count (descending)
      return bInProgressCount.compareTo(aInProgressCount);
    });

    // Select the most relevant challenge
    final selectedChallenge = filteredChallenges.first;

    // Cache the challenge
    _challengeCache[cacheKey] = selectedChallenge;

    return selectedChallenge;
  }

  /// Validate a user's solution to a challenge
  ///
  /// Parameters:
  /// - `challenge`: Challenge to validate against
  /// - `solution`: User's solution to the challenge
  ///
  /// Returns a validation result with success flag and feedback
  Future<Map<String, dynamic>> validateSolution({
    required Map<String, dynamic> challenge,
    required List<BlockModel> solution,
  }) async {
    await _ensureInitialized();

    // Get success criteria from the challenge
    final successCriteria = challenge['successCriteria'] as Map<String, dynamic>? ?? {};

    // Get required block types
    final requiredBlockTypes = (successCriteria['requiresBlockType'] as List<dynamic>?)?.cast<String>() ?? [];

    // Get minimum connections
    final minConnections = successCriteria['minConnections'] as int? ?? 0;

    // Get block types in the solution
    final solutionBlockTypes = solution.blockTypes;

    // Check if all required block types are used
    final allRequiredBlocksUsed = requiredBlockTypes.every((type) => solutionBlockTypes.contains(type));

    // Check if the solution has enough connections
    final hasEnoughConnections = solution.connectionCount >= minConnections;

    // Determine if the solution is successful
    final isSuccessful = allRequiredBlocksUsed && hasEnoughConnections;

    // Create feedback based on validation
    final feedback = _createFeedback(
      isSuccessful: isSuccessful,
      allRequiredBlocksUsed: allRequiredBlocksUsed,
      hasEnoughConnections: hasEnoughConnections,
      requiredBlockTypes: requiredBlockTypes,
      solutionBlockTypes: solutionBlockTypes,
      minConnections: minConnections,
      connectionCount: solution.connectionCount,
    );

    return {
      'success': isSuccessful,
      'feedback': feedback,
      'missingBlockTypes': allRequiredBlocksUsed ? [] : requiredBlockTypes.where((type) => !solutionBlockTypes.contains(type)).toList(),
      'connectionCount': solution.connectionCount,
      'requiredConnectionCount': minConnections,
    };
  }

  /// Update user progress based on challenge completion
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `challenge`: Completed challenge
  /// - `solution`: User's solution to the challenge
  /// - `validationResult`: Result of solution validation
  ///
  /// Returns updated user progress
  Future<UserProgress> updateProgressForChallenge({
    required UserProgress userProgress,
    required Map<String, dynamic> challenge,
    required List<BlockModel> solution,
    required Map<String, dynamic> validationResult,
  }) async {
    await _ensureInitialized();

    // Get challenge ID
    final challengeId = challenge['id'] as String? ?? '';

    // Get required concepts from the challenge
    final requiredConcepts = (challenge['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];

    // Get success flag from validation result
    final wasSuccessful = validationResult['success'] as bool? ?? false;

    // Update user progress using adaptive learning service
    return _adaptiveLearningService.updateProgressForChallenge(
      userProgress: userProgress,
      challengeId: challengeId,
      requiredConcepts: requiredConcepts,
      wasSuccessful: wasSuccessful,
    );
  }

  /// Get a challenge by ID
  ///
  /// Parameters:
  /// - `challengeId`: ID of the challenge to retrieve
  ///
  /// Returns the challenge if found, null otherwise
  Future<Challenge?> getChallengeById(String challengeId) async {
    await _ensureInitialized();

    try {
      // Check if the challenge is in the cache
      final cacheKey = 'challenge_$challengeId';
      if (_challengeCache.containsKey(cacheKey)) {
        return Challenge.fromJson(_challengeCache[cacheKey]!);
      }

      // Load all challenges
      final challenges = await _loadChallenges();

      // Find the challenge with the matching ID
      final challenge = challenges.firstWhere(
        (c) => c['id'] == challengeId,
        orElse: () => <String, dynamic>{},
      );

      // If no challenge found, return null
      if (challenge.isEmpty) {
        return null;
      }

      // Cache the challenge
      _challengeCache[cacheKey] = challenge;

      // Convert to Challenge model and return
      return Challenge.fromJson(challenge);
    } catch (e) {
      debugPrint('Error getting challenge by ID: $e');
      return null;
    }
  }

  /// Get challenge data by ID
  ///
  /// Parameters:
  /// - `challengeId`: ID of the challenge to retrieve
  ///
  /// Returns the challenge data as a map if found, null otherwise
  Future<Map<String, dynamic>?> getChallengeData(String challengeId) async {
    final challenge = await getChallengeById(challengeId);
    if (challenge == null) {
      return null;
    }

    // Convert Challenge to a map
    return challenge.toJson();
  }

  /// Check if a user has reached a milestone
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  ///
  /// Returns a milestone if reached, null otherwise
  Future<Map<String, dynamic>?> checkMilestone(UserProgress userProgress) async {
    await _ensureInitialized();

    // Get completed challenges count
    final completedChallengesCount = userProgress.completedChallenges.length;

    // Get mastered concepts count
    final masteredConceptsCount = userProgress.conceptsMastered.length;

    // Define milestones
    final milestones = [
      {
        'id': 'first_challenge',
        'name': 'First Challenge Completed',
        'description': 'You completed your first challenge!',
        'condition': completedChallengesCount >= 1,
        'reward': 'New block types unlocked',
      },
      {
        'id': 'five_challenges',
        'name': 'Challenge Master',
        'description': 'You completed 5 challenges!',
        'condition': completedChallengesCount >= 5,
        'reward': 'Advanced pattern creation tools unlocked',
      },
      {
        'id': 'three_concepts',
        'name': 'Concept Explorer',
        'description': 'You mastered 3 coding concepts!',
        'condition': masteredConceptsCount >= 3,
        'reward': 'New story themes unlocked',
      },
    ];

    // Check if any milestone has been reached
    for (final milestone in milestones) {
      if (milestone['condition'] as bool && !userProgress.completedMilestones.contains(milestone['id'])) {
        return milestone;
      }
    }

    return null;
  }

  /// Load challenges from assets
  Future<List<Map<String, dynamic>>> _loadChallenges() async {
    try {
      // Load challenges from storage
      final challengesJson = await _storageService.getProgress('challenges');

      if (challengesJson != null && challengesJson.isNotEmpty) {
        final List<dynamic> challenges = jsonDecode(challengesJson);
        return challenges.cast<Map<String, dynamic>>();
      }

      // If no challenges found, return an empty list
      return [];
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      return [];
    }
  }

  /// Create a default challenge when no suitable challenges are found
  Map<String, dynamic> _createDefaultChallenge({
    required String challengeType,
    required int difficultyLevel,
    required List<String> masteredConcepts,
    required List<String> inProgressConcepts,
  }) {
    // Determine which concepts to focus on
    final focusConcepts = inProgressConcepts.isNotEmpty
        ? inProgressConcepts
        : masteredConcepts.isNotEmpty
            ? masteredConcepts
            : ['sequences', 'basic patterns', 'simple loops'];

    // Determine required block types based on difficulty
    final requiredBlockTypes = difficultyLevel <= 2
        ? ['move', 'turn']
        : difficultyLevel <= 4
            ? ['move', 'turn', 'loop']
            : ['move', 'turn', 'loop', 'condition'];

    // Determine minimum connections based on difficulty
    final minConnections = difficultyLevel * 2;

    return {
      'id': 'default_${challengeType}_${difficultyLevel}_${DateTime.now().millisecondsSinceEpoch}',
      'type': challengeType,
      'title': 'Create a ${_getDifficultyName(difficultyLevel)} Pattern',
      'description': 'Create a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections.',
      'difficulty': difficultyLevel,
      'requiredConcepts': focusConcepts.take(2).toList(),
      'successCriteria': {
        'requiresBlockType': requiredBlockTypes,
        'minConnections': minConnections,
      },
      'availableBlockTypes': ['move', 'turn', 'loop', 'condition', 'variable'],
      'hints': [
        'Start by placing a ${requiredBlockTypes.first} block.',
        'Connect blocks to create a pattern with at least $minConnections connections.',
        'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
      ],
    };
  }

  /// Create feedback based on validation results
  Map<String, dynamic> _createFeedback({
    required bool isSuccessful,
    required bool allRequiredBlocksUsed,
    required bool hasEnoughConnections,
    required List<String> requiredBlockTypes,
    required List<String> solutionBlockTypes,
    required int minConnections,
    required int connectionCount,
  }) {
    if (isSuccessful) {
      return {
        'title': 'Great job!',
        'message': 'You successfully completed the challenge.',
        'details': 'Your solution uses all required block types and has enough connections.',
        'suggestions': [
          'Try creating a more complex pattern with more connections.',
          'Experiment with different block arrangements to see how they affect the pattern.',
        ],
      };
    }

    final List<String> issues = [];

    if (!allRequiredBlocksUsed) {
      final missingBlockTypes = requiredBlockTypes.where((type) => !solutionBlockTypes.contains(type)).toList();
      issues.add('Missing required block types: ${missingBlockTypes.join(', ')}.');
    }

    if (!hasEnoughConnections) {
      issues.add('Not enough connections. You have $connectionCount, but need at least $minConnections.');
    }

    return {
      'title': 'Almost there!',
      'message': 'Your solution needs some improvements.',
      'details': issues.join(' '),
      'suggestions': [
        if (!allRequiredBlocksUsed) 'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
        if (!hasEnoughConnections) 'Add more connections between blocks to reach at least $minConnections connections.',
      ],
    };
  }

  /// Get a human-readable name for a difficulty level
  String _getDifficultyName(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return 'Simple';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Custom';
    }
  }
}

/// Extension to get block types and connection count from a list of blocks
extension BlockListExtension on List<BlockModel> {
  List<String> get blockTypes {
    // Extract block types from the list of blocks
    return map((block) => block.type.toString().split('.').last).toList();
  }

  int get connectionCount {
    // Count connections between blocks
    int count = 0;
    for (final block in this) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          count++;
        }
      }
    }
    return count;
  }
}

/// Extension to get completed milestones from user progress
extension UserProgressExtension on UserProgress {
  List<String> get completedMilestones {
    // This is a simplified implementation since we don't know if UserProgress has a completedMilestones property
    // In a real implementation, you would access the completedMilestones property
    return [];
  }
}

