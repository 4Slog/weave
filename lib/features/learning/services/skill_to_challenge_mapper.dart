import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

/// Service for mapping between skills and appropriate challenges
///
/// This service provides methods for:
/// - Finding appropriate challenges based on skill proficiency
/// - Filtering challenges based on learning path preferences
/// - Generating challenge difficulty based on skill levels
/// - Recommending challenge sequences for skill development
class SkillToChallengeMapper {
  /// Map of concept IDs to related challenge types
  final Map<String, List<String>> _conceptToChallengeTypes = {
    'sequences': ['pattern', 'sequence'],
    'loops': ['pattern', 'loop'],
    'conditionals': ['pattern', 'condition'],
    'variables': ['pattern', 'variable'],
    'functions': ['pattern', 'function'],
    'debugging': ['debug'],
    'patterns': ['pattern'],
    'structure': ['structure'],
    'cultural': ['cultural'],
    'storytelling': ['story'],
  };

  /// Map of skill types to challenge difficulty modifiers
  final Map<String, double> _skillToDifficultyModifier = {
    'PATTERN_RECOGNITION': 0.2,
    'LOGICAL_THINKING': 0.3,
    'SEQUENTIAL_REASONING': 0.2,
    'ALGORITHMIC_THINKING': 0.3,
    'PROBLEM_SOLVING': 0.4,
    'CREATIVE_THINKING': 0.1,
  };

  /// Map of learning path types to preferred challenge types
  final Map<LearningPathType, List<String>> _pathToPreferredChallenges = {
    LearningPathType.logicBased: ['sequence', 'condition', 'function', 'debug'],
    LearningPathType.creativityBased: ['pattern', 'cultural', 'story', 'variable'],
    LearningPathType.challengeBased: ['debug', 'structure', 'loop', 'function'],
  };

  /// Find appropriate challenges based on user's skill proficiency
  ///
  /// Parameters:
  /// - `skills`: Map of skill types to proficiency values (0.0 to 1.0)
  /// - `count`: Number of challenges to recommend
  /// - `preferredPath`: Optional preferred learning path type
  /// - `userProgress`: Optional user progress for more personalized recommendations
  /// - `recentChallenges`: Optional list of recently completed challenges to avoid repetition
  ///
  /// Returns a list of challenge types sorted by appropriateness
  List<String> findChallengesForSkills(
    Map<String, double> skills, {
    int count = 3,
    LearningPathType? preferredPath,
    UserProgress? userProgress,
    List<String>? recentChallenges,
  }) {
    // Get all available challenge types
    final Set<String> allChallengeTypes = {};
    _conceptToChallengeTypes.values.forEach(allChallengeTypes.addAll);

    // Score each challenge type based on skill proficiency
    final Map<String, double> challengeScores = {};

    for (final challengeType in allChallengeTypes) {
      double score = 0.0;

      // Base score for each challenge
      for (final entry in _conceptToChallengeTypes.entries) {
        if (entry.value.contains(challengeType)) {
          // If this concept is related to the challenge type
          final conceptId = entry.key;
          final proficiency = skills[conceptId] ?? 0.0;

          // Higher score for challenges that match concepts with lower proficiency
          // (to encourage practice in weaker areas)
          score += (1.0 - proficiency) * 0.5;

          // But also some score for challenges that match concepts with higher proficiency
          // (to encourage mastery and reinforcement)
          score += proficiency * 0.2;
        }
      }

      // Adjust score based on preferred learning path
      if (preferredPath != null && _pathToPreferredChallenges[preferredPath]?.contains(challengeType) == true) {
        score *= 1.5; // Boost score for challenges that match preferred path
      }

      // Adjust score based on user progress if available
      if (userProgress != null) {
        // Boost score for challenges that address concepts in progress
        for (final concept in userProgress.conceptsInProgress) {
          if (_conceptToChallengeTypes[concept]?.contains(challengeType) == true) {
            score *= 1.3; // Boost score for challenges that address in-progress concepts
          }
        }

        // Reduce score for challenges that only address mastered concepts
        bool onlyMasteredConcepts = true;
        for (final entry in _conceptToChallengeTypes.entries) {
          if (entry.value.contains(challengeType)) {
            if (!userProgress.conceptsMastered.contains(entry.key)) {
              onlyMasteredConcepts = false;
              break;
            }
          }
        }

        if (onlyMasteredConcepts) {
          score *= 0.7; // Reduce score for challenges that only address mastered concepts
        }
      }

      // Reduce score for recently completed challenges to avoid repetition
      if (recentChallenges != null && recentChallenges.contains(challengeType)) {
        score *= 0.5; // Reduce score for recently completed challenges
      }

      challengeScores[challengeType] = score;
    }

    // Sort challenge types by score (descending)
    final sortedChallenges = challengeScores.keys.toList()
      ..sort((a, b) => challengeScores[b]!.compareTo(challengeScores[a]!));

    // Return the top N challenges
    return sortedChallenges.take(count).toList();
  }

  /// Calculate appropriate difficulty level for a challenge based on skills
  ///
  /// Parameters:
  /// - `skills`: Map of skill types to skill levels
  /// - `challengeType`: Type of challenge
  ///
  /// Returns a difficulty level from 1 (easiest) to 5 (hardest)
  int calculateDifficultyForChallenge(
    Map<String, SkillLevel> skills,
    String challengeType,
  ) {
    // Base difficulty
    double difficultyScore = 2.0;

    // Adjust based on skill levels
    for (final entry in skills.entries) {
      final skillType = entry.key;
      final skillLevel = entry.value;
      final modifier = _skillToDifficultyModifier[skillType] ?? 0.1;

      // Convert skill level to numeric value
      double skillValue;
      switch (skillLevel) {
        case SkillLevel.novice:
          skillValue = 1.0;
          break;
        case SkillLevel.beginner:
          skillValue = 2.0;
          break;
        case SkillLevel.intermediate:
          skillValue = 3.0;
          break;
        case SkillLevel.advanced:
          skillValue = 4.0;
          break;
      }

      // Apply modifier
      difficultyScore += skillValue * modifier;
    }

    // Ensure difficulty is within range
    return difficultyScore.clamp(1, 5).round();
  }

  /// Filter challenges based on skill gaps
  ///
  /// Parameters:
  /// - `challenges`: List of challenge maps
  /// - `userProgress`: User's progress
  ///
  /// Returns a filtered list of challenges that address skill gaps
  List<Map<String, dynamic>> filterChallengesForSkillGaps(
    List<Map<String, dynamic>> challenges,
    UserProgress userProgress,
  ) {
    // Identify skill gaps
    final skillGaps = _identifySkillGaps(userProgress);
    if (skillGaps.isEmpty) {
      return challenges; // No specific gaps to address
    }

    // Score each challenge based on how well it addresses skill gaps
    final scoredChallenges = challenges.map((challenge) {
      final requiredConcepts = (challenge['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [];

      // Calculate score based on how many skill gaps this challenge addresses
      int score = 0;
      for (final concept in requiredConcepts) {
        if (skillGaps.contains(concept)) {
          score += 2; // Higher score for directly addressing gaps
        }
      }

      return MapEntry(challenge, score);
    }).toList();

    // Sort by score (descending)
    scoredChallenges.sort((a, b) => b.value.compareTo(a.value));

    // Return challenges in order of relevance to skill gaps
    return scoredChallenges.map((entry) => entry.key).toList();
  }

  /// Generate a sequence of challenges for skill development
  ///
  /// Parameters:
  /// - `userProgress`: User's progress
  /// - `targetConcept`: Target concept to develop
  /// - `count`: Number of challenges in the sequence
  /// - `learningPathType`: Optional learning path type to consider
  /// - `adaptToDifficulty`: Whether to adapt challenge difficulty based on user performance
  ///
  /// Returns a list of challenge types in recommended sequence
  List<Map<String, dynamic>> generateChallengeSequence(
    UserProgress userProgress,
    String targetConcept,
    int count, {
    LearningPathType? learningPathType,
    bool adaptToDifficulty = true,
  }) {
    // Get related concepts (prerequisites and related)
    final relatedConcepts = _getRelatedConcepts(targetConcept);

    // Get proficiency for target and related concepts
    final conceptProficiency = <String, double>{};
    for (final concept in [targetConcept, ...relatedConcepts]) {
      conceptProficiency[concept] = userProgress.skillProficiency[concept] ?? 0.0;
    }

    // Sort concepts by proficiency (ascending, to focus on weaker areas first)
    final sortedConcepts = conceptProficiency.keys.toList()
      ..sort((a, b) => conceptProficiency[a]!.compareTo(conceptProficiency[b]!));

    // Generate challenge sequence
    final sequence = <Map<String, dynamic>>[];

    // Start with easier challenges for prerequisites
    for (final concept in sortedConcepts) {
      if (sequence.length >= count) break;

      // Get challenge types for this concept
      final challengeTypes = _conceptToChallengeTypes[concept] ?? [];
      if (challengeTypes.isNotEmpty) {
        // Select challenge type based on learning path if available
        String challengeType = challengeTypes.first;
        if (learningPathType != null && _pathToPreferredChallenges[learningPathType] != null) {
          // Find a challenge type that matches both the concept and the learning path
          for (final type in challengeTypes) {
            if (_pathToPreferredChallenges[learningPathType]!.contains(type)) {
              challengeType = type;
              break;
            }
          }
        }

        // Calculate appropriate difficulty level
        int difficultyLevel = 1;
        if (adaptToDifficulty) {
          // Base difficulty on proficiency
          final proficiency = conceptProficiency[concept] ?? 0.0;
          if (proficiency < 0.3) {
            difficultyLevel = 1; // Beginner
          } else if (proficiency < 0.6) {
            difficultyLevel = 2; // Intermediate
          } else if (proficiency < 0.9) {
            difficultyLevel = 3; // Advanced
          } else {
            difficultyLevel = 4; // Expert
          }

          // Adjust based on learning path
          if (learningPathType == LearningPathType.challengeBased) {
            difficultyLevel += 1; // Challenge-based paths are more difficult
          }

          // Ensure difficulty is within range
          difficultyLevel = difficultyLevel.clamp(1, 5);
        }

        // Add challenge to sequence
        sequence.add({
          'type': challengeType,
          'concept': concept,
          'difficulty': difficultyLevel,
          'isPrerequisite': concept != targetConcept,
        });
      }
    }

    // Fill remaining slots with challenges for the target concept
    final targetChallengeTypes = _conceptToChallengeTypes[targetConcept] ?? [];
    if (targetChallengeTypes.isNotEmpty) {
      // Select challenge type based on learning path if available
      String challengeType = targetChallengeTypes.first;
      if (learningPathType != null && _pathToPreferredChallenges[learningPathType] != null) {
        // Find a challenge type that matches both the concept and the learning path
        for (final type in targetChallengeTypes) {
          if (_pathToPreferredChallenges[learningPathType]!.contains(type)) {
            challengeType = type;
            break;
          }
        }
      }

      // Calculate appropriate difficulty level for target concept
      int baseDifficulty = 2; // Default to intermediate
      if (adaptToDifficulty) {
        // Base difficulty on proficiency
        final proficiency = conceptProficiency[targetConcept] ?? 0.0;
        if (proficiency < 0.3) {
          baseDifficulty = 1; // Beginner
        } else if (proficiency < 0.6) {
          baseDifficulty = 2; // Intermediate
        } else if (proficiency < 0.9) {
          baseDifficulty = 3; // Advanced
        } else {
          baseDifficulty = 4; // Expert
        }
      }

      // Add progressively more difficult challenges for the target concept
      while (sequence.length < count) {
        // Calculate difficulty for this challenge
        int challengeIndex = sequence.length - (count - targetChallengeTypes.length);
        int difficultyLevel = baseDifficulty;

        // Increase difficulty for later challenges
        if (challengeIndex > 0) {
          difficultyLevel += challengeIndex;
        }

        // Adjust based on learning path
        if (learningPathType == LearningPathType.challengeBased) {
          difficultyLevel += 1; // Challenge-based paths are more difficult
        }

        // Ensure difficulty is within range
        difficultyLevel = difficultyLevel.clamp(1, 5);

        // Add challenge to sequence
        sequence.add({
          'type': challengeType,
          'concept': targetConcept,
          'difficulty': difficultyLevel,
          'isPrerequisite': false,
        });
      }
    }

    return sequence;
  }

  /// Identify skill gaps based on user progress
  List<String> _identifySkillGaps(UserProgress userProgress) {
    final gaps = <String>[];

    // Check proficiency for each concept
    userProgress.skillProficiency.forEach((concept, proficiency) {
      if (proficiency < 0.6) {
        gaps.add(concept);
      }
    });

    // Add concepts that are in progress but not mastered
    for (final concept in userProgress.conceptsInProgress) {
      if (!userProgress.conceptsMastered.contains(concept) && !gaps.contains(concept)) {
        gaps.add(concept);
      }
    }

    return gaps;
  }

  /// Get related concepts for a target concept
  List<String> _getRelatedConcepts(String targetConcept) {
    // Map of concepts to their prerequisites and related concepts
    final Map<String, List<String>> conceptRelations = {
      'sequences': <String>[],
      'loops': <String>['sequences'],
      'conditionals': <String>['sequences'],
      'variables': <String>['sequences'],
      'functions': <String>['sequences', 'variables'],
      'debugging': <String>['sequences', 'loops', 'conditionals'],
      'patterns': <String>['sequences', 'loops'],
      'structure': <String>['functions', 'variables'],
      'cultural': <String>[],
      'storytelling': <String>[],
      'basic patterns': <String>[],
      'simple loops': <String>['sequences'],
      'nested loops': <String>['loops'],
      'complex patterns': <String>['loops', 'conditionals'],
      'recursion': <String>['functions'],
      'algorithms': <String>['loops', 'conditionals', 'functions'],
      'optimization': <String>['algorithms'],
      'advanced algorithms': <String>['algorithms', 'recursion'],
      'problem decomposition': <String>['functions', 'algorithms'],
      'abstraction': <String>['functions', 'problem decomposition'],
    };

    return conceptRelations[targetConcept] ?? <String>[];
  }
}
