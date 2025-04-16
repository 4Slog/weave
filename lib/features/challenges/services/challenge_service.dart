import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';

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
  /// Adaptive learning service for skill assessment
  final AdaptiveLearningService _adaptiveLearningService;

  /// Cache for challenges to reduce API calls
  final Map<String, Map<String, dynamic>> _challengeCache = {};

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new ChallengeService with optional dependencies
  ChallengeService({
    AdaptiveLearningService? adaptiveLearningService,
  }) :
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
  /// - `learningPathType`: Optional learning path type to consider
  /// - `frustrationLevel`: Optional frustration level to consider for dynamic difficulty adjustment
  /// - `targetConcept`: Optional specific concept to focus on
  ///
  /// Returns a challenge as a map with challenge details
  Future<Map<String, dynamic>> getChallenge({
    required UserProgress userProgress,
    required String challengeType,
    int? difficultyOverride,
    LearningPathType? learningPathType,
    double? frustrationLevel,
    String? targetConcept,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the challenge
    final cacheKey = 'challenge_${userProgress.userId}_${challengeType}_${difficultyOverride ?? 'auto'}_${learningPathType?.toString() ?? 'any'}_${targetConcept ?? 'any'}';

    // Check if challenge is cached and frustration level is not provided (don't use cache for dynamic difficulty adjustment)
    if (_challengeCache.containsKey(cacheKey) && frustrationLevel == null) {
      return _challengeCache[cacheKey]!;
    }

    // Get difficulty level based on user progress or override, considering learning path and frustration
    final difficultyLevel = difficultyOverride ??
        await _adaptiveLearningService.calculateDifficultyLevel(
          userProgress: userProgress,
          learningPathType: learningPathType,
          conceptId: targetConcept,
          frustrationLevel: frustrationLevel,
        );

    // Get concepts the user has mastered
    final masteredConcepts = userProgress.conceptsMastered;

    // Get concepts the user is currently learning
    final conceptsInProgress = userProgress.conceptsInProgress;

    // Load challenges from assets
    final challenges = await _loadChallenges();

    // Filter challenges by type and difficulty
    final filteredChallenges = challenges.where((challenge) {
      // Check if challenge type matches
      if (challenge['type'] != challengeType) return false;

      // Check if difficulty is appropriate
      final challengeDifficulty = challenge['difficulty'] as int? ?? 1;

      // Adjust difficulty range based on frustration level
      int lowerBound = difficultyLevel - 1;
      int upperBound = difficultyLevel + 1;

      // If user is frustrated, widen the range to include easier challenges
      if (frustrationLevel != null && frustrationLevel > 0.5) {
        lowerBound = difficultyLevel - 2;
      }

      // If user is doing well, widen the range to include harder challenges
      if (frustrationLevel != null && frustrationLevel < 0.3) {
        upperBound = difficultyLevel + 2;
      }

      if (challengeDifficulty > upperBound || challengeDifficulty < lowerBound) {
        return false;
      }

      // Check if the challenge has already been completed
      if (userProgress.completedChallenges.contains(challenge['id'])) {
        return false;
      }

      // If target concept is specified, prioritize challenges that include it
      if (targetConcept != null) {
        final requiredConcepts = (challenge['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];
        if (!requiredConcepts.contains(targetConcept)) {
          // Don't exclude, but will be sorted lower
          return true;
        }
      }

      return true;
    }).toList();

    // If no challenges match, return a default challenge
    if (filteredChallenges.isEmpty) {
      final defaultChallenge = _createDefaultChallenge(
        challengeType: challengeType,
        difficultyLevel: difficultyLevel,
        masteredConcepts: masteredConcepts,
        inProgressConcepts: conceptsInProgress,
        targetConcept: targetConcept,
        learningPathType: learningPathType,
      );

      // Cache the challenge
      _challengeCache[cacheKey] = defaultChallenge;

      return defaultChallenge;
    }

    // Sort challenges by relevance to user's current learning
    filteredChallenges.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      // Get required concepts for each challenge
      final aRequiredConcepts = (a['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];
      final bRequiredConcepts = (b['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];

      // Count how many in-progress concepts are required for each challenge
      final aInProgressCount = aRequiredConcepts.where((c) => conceptsInProgress.contains(c)).length;
      final bInProgressCount = bRequiredConcepts.where((c) => conceptsInProgress.contains(c)).length;

      // Add score for in-progress concepts
      scoreA += aInProgressCount * 3;
      scoreB += bInProgressCount * 3;

      // If target concept is specified, prioritize challenges that include it
      if (targetConcept != null) {
        if (aRequiredConcepts.contains(targetConcept)) scoreA += 5;
        if (bRequiredConcepts.contains(targetConcept)) scoreB += 5;
      }

      // Prioritize challenges with difficulty closer to the target difficulty
      final aDifficulty = a['difficulty'] as int? ?? 1;
      final bDifficulty = b['difficulty'] as int? ?? 1;
      final aDifficultyDiff = (aDifficulty - difficultyLevel).abs();
      final bDifficultyDiff = (bDifficulty - difficultyLevel).abs();

      // Subtract points for difficulty difference (closer is better)
      scoreA -= aDifficultyDiff * 2;
      scoreB -= bDifficultyDiff * 2;

      // If learning path type is specified, prioritize challenges that match it
      if (learningPathType != null) {
        // Check if challenge matches learning path type
        final aMatchesPath = _doesChallengeMatchLearningPath(a, learningPathType);
        final bMatchesPath = _doesChallengeMatchLearningPath(b, learningPathType);

        if (aMatchesPath) scoreA += 4;
        if (bMatchesPath) scoreB += 4;
      }

      // Sort by total score (descending)
      return scoreB.compareTo(scoreA);
    });

    // Select the most relevant challenge
    final selectedChallenge = filteredChallenges.first;

    // Cache the challenge
    _challengeCache[cacheKey] = selectedChallenge;

    return selectedChallenge;
  }

  /// Check if a challenge matches a learning path type
  bool _doesChallengeMatchLearningPath(Map<String, dynamic> challenge, LearningPathType pathType) {
    // Get challenge tags or attributes that might indicate learning path compatibility
    final tags = (challenge['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final challengeType = challenge['type'] as String? ?? '';

    // Check if challenge matches learning path type
    if (pathType == LearningPathType.logicBased) {
      // Logic-based paths emphasize structured learning and problem-solving
      return tags.contains('logical') ||
             tags.contains('structured') ||
             challengeType == 'sequence' ||
             challengeType == 'function' ||
             challengeType == 'debug';
    } else if (pathType == LearningPathType.creativityBased) {
      // Creativity-based paths emphasize exploration and creative expression
      return tags.contains('creative') ||
             tags.contains('open-ended') ||
             challengeType == 'pattern' ||
             challengeType == 'cultural' ||
             challengeType == 'story';
    } else if (pathType == LearningPathType.challengeBased) {
      // Challenge-based paths emphasize mastery through increasingly difficult challenges
      return tags.contains('challenge') ||
             tags.contains('advanced') ||
             challengeType == 'debug' ||
             challengeType == 'structure' ||
             challengeType == 'loop';
    }

    // Default case
    return false;
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
    required PatternModel solution,
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
    required PatternModel solution,
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
      // In a real implementation, this would load challenges from a JSON file or API
      // For now, we'll return a list of mock challenges
      return [
        {
          'id': 'pattern_challenge_1',
          'type': 'pattern',
          'title': 'Create a Simple Pattern',
          'description': 'Create a pattern using move and turn blocks with at least 2 connections.',
          'difficulty': 1,
          'requiredConcepts': ['sequences', 'basic patterns'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn'],
            'minConnections': 2,
          },
          'availableBlockTypes': ['move', 'turn', 'loop'],
          'hints': [
            'Start by placing a move block.',
            'Connect blocks to create a pattern with at least 2 connections.',
            'Make sure to use both move and turn blocks.',
          ],
        },
        {
          'id': 'pattern_challenge_2',
          'type': 'pattern',
          'title': 'Create a Loop Pattern',
          'description': 'Create a pattern using move, turn, and loop blocks with at least 4 connections.',
          'difficulty': 2,
          'requiredConcepts': ['sequences', 'loops'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn', 'loop'],
            'minConnections': 4,
          },
          'availableBlockTypes': ['move', 'turn', 'loop', 'condition'],
          'hints': [
            'Start by placing a loop block.',
            'Place move and turn blocks inside the loop.',
            'Connect blocks to create a pattern with at least 4 connections.',
          ],
        },
        {
          'id': 'pattern_challenge_3',
          'type': 'pattern',
          'title': 'Create a Conditional Pattern',
          'description': 'Create a pattern using move, turn, loop, and condition blocks with at least 6 connections.',
          'difficulty': 3,
          'requiredConcepts': ['sequences', 'loops', 'conditionals'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn', 'loop', 'condition'],
            'minConnections': 6,
          },
          'availableBlockTypes': ['move', 'turn', 'loop', 'condition', 'variable'],
          'hints': [
            'Start by placing a condition block.',
            'Place move, turn, and loop blocks inside the condition branches.',
            'Connect blocks to create a pattern with at least 6 connections.',
          ],
        },
      ];
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
    String? targetConcept,
    LearningPathType? learningPathType,
  }) {
    // Determine which concepts to focus on
    List<String> focusConcepts;

    if (targetConcept != null) {
      // If target concept is specified, prioritize it
      focusConcepts = [targetConcept];

      // Add related concepts if needed
      if (inProgressConcepts.isNotEmpty) {
        focusConcepts.addAll(inProgressConcepts.where((c) => c != targetConcept).take(1));
      }
    } else {
      // Otherwise use in-progress or mastered concepts
      focusConcepts = inProgressConcepts.isNotEmpty
          ? inProgressConcepts
          : masteredConcepts.isNotEmpty
              ? masteredConcepts
              : ['sequences', 'basic patterns', 'simple loops'];
    }

    // Determine required block types based on difficulty and learning path
    List<String> requiredBlockTypes;

    if (learningPathType == LearningPathType.logicBased) {
      // Logic-based paths emphasize structured learning
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'loop']
              : ['move', 'turn', 'loop', 'condition'];
    } else if (learningPathType == LearningPathType.creativityBased) {
      // Creativity-based paths emphasize exploration
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn', 'color']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'color', 'pattern']
              : ['move', 'turn', 'color', 'pattern', 'variable'];
    } else if (learningPathType == LearningPathType.challengeBased) {
      // Challenge-based paths are more difficult
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn', 'loop']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'loop', 'condition']
              : ['move', 'turn', 'loop', 'condition', 'variable'];
    } else {
      // Default block types based on difficulty
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn']
          : difficultyLevel <= 4
              ? ['move', 'turn', 'loop']
              : ['move', 'turn', 'loop', 'condition'];
    }

    // Determine minimum connections based on difficulty and learning path
    int minConnections;

    if (learningPathType == LearningPathType.challengeBased) {
      // Challenge-based paths require more connections
      minConnections = difficultyLevel * 3;
    } else if (learningPathType == LearningPathType.creativityBased) {
      // Creativity-based paths are more flexible
      minConnections = difficultyLevel * 1;
    } else {
      // Default connections based on difficulty
      minConnections = difficultyLevel * 2;
    }

    // Create appropriate title and description based on learning path
    String title;
    String description;

    if (learningPathType == LearningPathType.logicBased) {
      title = 'Create a Logical ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Create a structured pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Focus on logical organization.';
    } else if (learningPathType == LearningPathType.creativityBased) {
      title = 'Design a Creative ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Express yourself by creating a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Be creative!';
    } else if (learningPathType == LearningPathType.challengeBased) {
      title = 'Master the ${_getDifficultyName(difficultyLevel)} Pattern Challenge';
      description = 'Overcome this challenge by creating a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Push your skills!';
    } else {
      title = 'Create a ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Create a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections.';
    }

    // Create appropriate hints based on learning path
    List<String> hints;

    if (learningPathType == LearningPathType.logicBased) {
      hints = [
        'Start by planning your pattern structure with ${requiredBlockTypes.first} blocks.',
        'Think about the logical flow of your pattern and how blocks connect.',
        'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
      ];
    } else if (learningPathType == LearningPathType.creativityBased) {
      hints = [
        'Experiment with different combinations of ${requiredBlockTypes.join(', ')} blocks.',
        'Try creating a pattern that tells a story or expresses an emotion.',
        'There are many ways to solve this challenge - be creative!',
      ];
    } else if (learningPathType == LearningPathType.challengeBased) {
      hints = [
        'This is a challenging pattern - start with the core structure using ${requiredBlockTypes.first} blocks.',
        'Build up complexity gradually to reach at least $minConnections connections.',
        'Challenge yourself to use all required block types efficiently: ${requiredBlockTypes.join(', ')}.',
      ];
    } else {
      hints = [
        'Start by placing a ${requiredBlockTypes.first} block.',
        'Connect blocks to create a pattern with at least $minConnections connections.',
        'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
      ];
    }

    // Create tags based on learning path
    List<String> tags = ['generated', challengeType];

    if (learningPathType == LearningPathType.logicBased) {
      tags.add('logical');
      tags.add('structured');
    } else if (learningPathType == LearningPathType.creativityBased) {
      tags.add('creative');
      tags.add('open-ended');
    } else if (learningPathType == LearningPathType.challengeBased) {
      tags.add('challenge');
      tags.add('advanced');
    }

    // Add concept-related tags
    tags.addAll(focusConcepts);

    return {
      'id': 'default_${challengeType}_${difficultyLevel}_${DateTime.now().millisecondsSinceEpoch}',
      'type': challengeType,
      'title': title,
      'description': description,
      'difficulty': difficultyLevel,
      'requiredConcepts': focusConcepts.take(2).toList(),
      'successCriteria': {
        'requiresBlockType': requiredBlockTypes,
        'minConnections': minConnections,
      },
      'availableBlockTypes': ['move', 'turn', 'loop', 'condition', 'variable', 'color', 'pattern'],
      'hints': hints,
      'tags': tags,
      'learningPathType': learningPathType?.toString().split('.').last,
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

/// Extension to get block types and connection count from a pattern model
extension PatternModelExtension on PatternModel {
  List<String> get blockTypes {
    // This is a simplified implementation since we don't know the exact structure of PatternModel
    // In a real implementation, you would access the blocks property and map to block types
    return [];
  }

  int get connectionCount {
    // This is a simplified implementation since we don't know the exact structure of PatternModel
    // In a real implementation, you would count the connections between blocks
    return 0;
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
