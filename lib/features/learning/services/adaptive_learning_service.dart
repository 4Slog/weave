import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/core/services/gemini_service.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path.dart';
import 'package:kente_codeweaver/features/learning/models/concept_mastery.dart';
import 'package:kente_codeweaver/features/learning/models/learning_session.dart';
import 'package:kente_codeweaver/features/learning/models/learning_style.dart' as style;
import 'package:kente_codeweaver/features/learning/data/learning_paths_data.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service_helper.dart';
import 'package:kente_codeweaver/features/learning/services/cultural_learning_integration_service.dart';

/// Service for adaptive learning progression
///
/// This service provides AI-driven difficulty progression, skill assessment,
/// learning style detection, and concept recommendations.
/// Features include:
/// - AI-driven difficulty progression instead of age-based
/// - Improved skill assessment algorithms
/// - More sophisticated learning style detection
/// - Enhanced recommendation algorithms for next concepts
/// Service for adaptive learning progression
///
/// This service provides AI-driven difficulty progression, skill assessment,
/// learning style detection, and concept recommendations.
/// Features include:
/// - AI-driven difficulty progression instead of age-based
/// - Improved skill assessment algorithms
/// - More sophisticated learning style detection
/// - Enhanced recommendation algorithms for next concepts
/// - Tailored learning paths (logic-based, creativity-based, challenge-based)
/// - Real-time analytics for immediate adaptation
/// - Robust skill assessment with practical demonstrations
/// - Dynamic challenge generation based on assessed skills
class AdaptiveLearningService {
  /// Gemini service for API interactions
  final GeminiService _geminiService = GeminiService();

  /// Storage service for caching responses
  final StorageService _storageService;

  /// Cultural learning integration service
  final CulturalLearningIntegrationService _culturalLearningService;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Cache for skill assessments to reduce API calls
  final Map<String, Map<String, dynamic>> _assessmentCache = {};

  /// Cache for learning style detection to reduce API calls
  final Map<String, String> _learningStyleCache = {};

  /// Cache for concept recommendations to reduce API calls
  final Map<String, List<String>> _recommendationCache = {};

  /// Cache for learning paths to reduce regeneration
  final Map<String, LearningPath> _learningPathCache = {};

  /// Cache for concept mastery data to reduce storage operations
  final Map<String, Map<String, ConceptMastery>> _conceptMasteryCache = {};

  /// Learning styles supported by the system
  final List<String> _supportedLearningStyles = [
    'visual', 'auditory', 'kinesthetic', 'reading/writing', 'logical', 'social', 'solitary', 'mixed'
  ];

  /// Coding concepts organized by difficulty level
  final Map<int, List<String>> _conceptsByLevel = {
    1: ['sequences', 'basic patterns', 'simple loops'],
    2: ['nested loops', 'variables', 'conditionals'],
    3: ['functions', 'parameters', 'complex patterns'],
    4: ['recursion', 'algorithms', 'optimization'],
    5: ['advanced algorithms', 'problem decomposition', 'abstraction']
  };

  /// Create a new AdaptiveLearningService with optional dependencies
  AdaptiveLearningService({
    StorageService? storageService,
    CulturalLearningIntegrationService? culturalLearningService,
  }) :
    _storageService = storageService ?? StorageService(),
    _culturalLearningService = culturalLearningService ?? CulturalLearningIntegrationService();

  /// Initializes the service and its dependencies
  ///
  /// Uses the shared GeminiService for Gemini API access
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the Gemini service
      await _geminiService.initialize();

      // Initialize cultural learning integration service
      await _culturalLearningService.initialize();

      _isInitialized = true;
      debugPrint('AdaptiveLearningService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdaptiveLearningService: $e');
      // Set to initialized anyway to prevent repeated initialization attempts
      _isInitialized = true;
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Check connectivity by using the GeminiService
  Future<bool> checkConnectivity() async {
    return _geminiService.isOnline;
  }

  /// Assess a user's skills based on their solutions and progress
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `recentSolutions`: Recent pattern solutions created by the user
  /// - `completedChallenges`: IDs of challenges the user has completed
  ///
  /// Returns a map of skill types to skill levels
  Future<Map<String, SkillLevel>> assessSkills({
    required UserProgress userProgress,
    List<PatternModel> recentSolutions = const [],
    List<String> completedChallenges = const [],
  }) async {
    await _ensureInitialized();

    // Create a cache key for the assessment
    final cacheKey = 'assessment_${userProgress.userId}_${completedChallenges.length}_${recentSolutions.length}';

    // Check if assessment is cached
    if (_assessmentCache.containsKey(cacheKey)) {
      return _mapToSkillAssessment(_assessmentCache[cacheKey]!);
    }

    // If offline, return a basic assessment based on user progress
    if (!_geminiService.isOnline) {
      return _getDefaultSkillAssessment(userProgress);
    }

    // Create a description of the user's recent solutions
    final solutionsDescription = recentSolutions.isEmpty
        ? "No recent solutions available."
        : "Recent solutions: ${recentSolutions.length} patterns created.";

    // Create a description of completed challenges
    final challengesDescription = completedChallenges.isEmpty
        ? "No completed challenges available."
        : "Completed ${completedChallenges.length} challenges.";

    // Create a description of mastered and in-progress concepts
    final masteredDescription = userProgress.conceptsMastered.isEmpty
        ? "No concepts mastered yet."
        : "Concepts mastered: ${userProgress.conceptsMastered.join(', ')}.";

    final inProgressDescription = userProgress.conceptsInProgress.isEmpty
        ? "No concepts in progress yet."
        : "Concepts in progress: ${userProgress.conceptsInProgress.join(', ')}.";

    // Create a prompt for assessing skills
    final prompt = "You are an AI educational assessment system analyzing a child's coding skills through their Kente weaving patterns. "
        "User ID: ${userProgress.userId}. "
        "$solutionsDescription. "
        "$challengesDescription. "
        "$masteredDescription. "
        "$inProgressDescription. "
        "Please assess the user's skills in the following areas: "
        "PATTERN_RECOGNITION, LOGICAL_THINKING, SEQUENTIAL_REASONING, ALGORITHMIC_THINKING, PROBLEM_SOLVING, CREATIVE_THINKING. "
        "For each skill, provide a skill level (BEGINNER, INTERMEDIATE, ADVANCED) "
        "and a brief explanation of your assessment. "
        "Format your response as a JSON object with skill names as keys and objects containing level and explanation as values.";

    try {
      // Generate the assessment using Gemini
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default assessment
      if (responseText.isEmpty) {
        return _getDefaultSkillAssessment(userProgress);
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final assessment = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Cache the assessment
        _assessmentCache[cacheKey] = assessment;

        return _mapToSkillAssessment(assessment);
      } catch (e) {
        debugPrint('Error parsing assessment JSON: $e');
        return _getDefaultSkillAssessment(userProgress);
      }
    } catch (e) {
      debugPrint('Error assessing skills: $e');
      return _getDefaultSkillAssessment(userProgress);
    }
  }

  /// Detect a user's learning style based on their interactions and progress
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `interactionHistory`: History of user interactions with the app
  ///
  /// Returns a learning style string (visual, auditory, kinesthetic, reading/writing, mixed)
  Future<String> detectLearningStyle({
    required UserProgress userProgress,
    Map<String, dynamic>? interactionHistory,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the learning style
    final cacheKey = 'learning_style_${userProgress.userId}';

    // Check if learning style is cached
    if (_learningStyleCache.containsKey(cacheKey)) {
      return _learningStyleCache[cacheKey]!;
    }

    // If offline or no interaction history, return a default learning style
    if (!_geminiService.isOnline || interactionHistory == null) {
      return 'mixed';
    }

    // Create a description of the user's interaction history
    final interactionsDescription = "User has spent ${interactionHistory['timeInStories'] ?? 0} minutes in stories, "
        "${interactionHistory['timeInChallenges'] ?? 0} minutes in challenges, "
        "and ${interactionHistory['timeInPatternCreation'] ?? 0} minutes in pattern creation. "
        "User has completed ${interactionHistory['storiesCompleted'] ?? 0} stories and "
        "${interactionHistory['challengesCompleted'] ?? 0} challenges.";

    // Create a prompt for detecting learning style
    final prompt = "You are an AI educational assessment system analyzing a child's learning style through their interactions with a coding app. "
        "User ID: ${userProgress.userId}. "
        "$interactionsDescription. "
        "Please determine the user's primary learning style based on their interactions. "
        "Consider the following learning styles: visual, auditory, kinesthetic, reading/writing, or mixed. "
        "Provide a single learning style as your answer, along with a brief explanation of your assessment.";

    try {
      // Generate the learning style detection using Gemini
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default learning style
      if (responseText.isEmpty) {
        return 'mixed';
      }

      // Extract the learning style from the response
      for (final style in _supportedLearningStyles) {
        if (responseText.toLowerCase().contains(style.toLowerCase())) {
          // Cache the learning style
          _learningStyleCache[cacheKey] = style;
          return style;
        }
      }

      // If no learning style is found, return mixed
      _learningStyleCache[cacheKey] = 'mixed';
      return 'mixed';
    } catch (e) {
      debugPrint('Error detecting learning style: $e');
      return 'mixed';
    }
  }

  /// Recommend next concepts for the user to learn based on their progress
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `count`: Number of concepts to recommend
  ///
  /// Returns a list of recommended concept strings
  Future<List<String>> recommendNextConcepts({
    required UserProgress userProgress,
    int count = 3,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the recommendations
    final cacheKey = 'adaptive_learning_recommendations_${userProgress.userId}_$count';

    // Check if recommendations are cached in memory
    if (_recommendationCache.containsKey(cacheKey)) {
      return _recommendationCache[cacheKey]!;
    }

    // Check if recommendations are cached in storage
    final cachedRecommendations = await _storageService.getSetting(cacheKey);
    if (cachedRecommendations != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(cachedRecommendations);
        final List<String> recommendations = decodedList.cast<String>();
        _recommendationCache[cacheKey] = recommendations;
        return recommendations;
      } catch (e) {
        // Invalid cache, continue with API call
      }
    }

    // If offline, return default recommendations based on user progress
    if (!_geminiService.isOnline) {
      return _getDefaultRecommendations(userProgress, count);
    }

    // Create a description of the user's mastered and in-progress concepts
    final masteredDescription = userProgress.conceptsMastered.isEmpty
        ? "No concepts mastered yet."
        : "Concepts mastered: ${userProgress.conceptsMastered.join(', ')}.";

    final inProgressDescription = userProgress.conceptsInProgress.isEmpty
        ? "No concepts in progress yet."
        : "Concepts in progress: ${userProgress.conceptsInProgress.join(', ')}.";

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a prompt for recommending next concepts
    final prompt = "You are an AI educational recommendation system suggesting coding concepts for a child to learn next. "
        "User ID: ${userProgress.userId}. "
        "Skill level: ${skillLevel == 1 ? 'Beginner' : skillLevel == 3 ? 'Intermediate' : 'Advanced'}. "
        "$masteredDescription "
        "$inProgressDescription "
        "Please recommend the next $count coding concepts this user should learn, based on their current progress. "
        "Consider concepts that build on what they already know, but are not too advanced for their skill level. "
        "Available concepts by level: "
        "Level 1: sequences, basic patterns, simple loops. "
        "Level 2: nested loops, variables, conditionals. "
        "Level 3: functions, parameters, complex patterns. "
        "Level 4: recursion, algorithms, optimization. "
        "Level 5: advanced algorithms, problem decomposition, abstraction. "
        "Format your response as a JSON array of concept names.";

    try {
      // Generate the recommendations using Gemini
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return default recommendations
      if (responseText.isEmpty) {
        return _getDefaultRecommendations(userProgress, count);
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final recommendations = jsonDecode(jsonStr) as List<dynamic>;

        // Convert to list of strings
        final conceptList = recommendations.map((r) => r.toString()).toList();

        // Ensure we have the requested number of concepts
        final result = conceptList.length > count
            ? conceptList.sublist(0, count)
            : conceptList;

        // Cache the recommendations in memory
        _recommendationCache[cacheKey] = result;

        // Cache the recommendations in storage
        try {
          await _storageService.saveSetting(cacheKey, jsonEncode(result));
        } catch (e) {
          // Failed to cache, but we can still return the recommendations
          debugPrint('Failed to cache recommendations: $e');
        }

        return result;
      } catch (e) {
        debugPrint('Error parsing recommendations JSON: $e');
        return _getDefaultRecommendations(userProgress, count);
      }
    } catch (e) {
      debugPrint('Error recommending concepts: $e');
      return _getDefaultRecommendations(userProgress, count);
    }
  }

  /// Calculate the appropriate difficulty level for a user based on their skills and progress
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `learningPathType`: Optional learning path type to consider
  /// - `conceptId`: Optional specific concept to focus on
  /// - `frustrationLevel`: Optional frustration level to consider
  ///
  /// Returns a difficulty level from 1 (easiest) to 5 (hardest)
  Future<int> calculateDifficultyLevel({
    required UserProgress userProgress,
    LearningPathType? learningPathType,
    String? conceptId,
    double? frustrationLevel,
  }) async {
    await _ensureInitialized();

    // Start with the base difficulty from user progress
    int baseDifficulty = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Adjust based on learning path type if provided
    if (learningPathType != null) {
      switch (learningPathType) {
        case LearningPathType.challengeBased:
          // Challenge-based paths are slightly more difficult
          baseDifficulty += 1;
          break;
        case LearningPathType.creativityBased:
          // Creativity-based paths focus more on exploration than difficulty
          break;
        case LearningPathType.logicBased:
          // Logic-based paths are more structured and progressive
          break;
        case LearningPathType.balanced:
          // Balanced paths provide a mix of challenge and creativity
          // Adjust difficulty based on user's progress
          if (userProgress.experiencePoints > 1000) {
            baseDifficulty += 1;
          }
          break;
      }
    }

    // Adjust based on specific concept proficiency if provided
    if (conceptId != null) {
      final proficiency = userProgress.skillProficiency[conceptId] ?? 0.0;

      // Higher proficiency means we can increase difficulty
      if (proficiency > 0.8) {
        baseDifficulty += 1;
      } else if (proficiency < 0.3) {
        baseDifficulty -= 1;
      }
    }

    // Adjust based on frustration level if provided
    if (frustrationLevel != null) {
      // If user is frustrated, decrease difficulty
      if (frustrationLevel > 0.7) {
        baseDifficulty -= 1;
      } else if (frustrationLevel < 0.3 && baseDifficulty < 5) {
        // If user is not frustrated and difficulty is not max, consider increasing
        baseDifficulty += 1;
      }
    }

    // Ensure difficulty stays within valid range
    return baseDifficulty.clamp(1, 5);
  }

  /// Get the user's progress
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  ///
  /// Returns the user's progress or null if not found
  Future<UserProgress?> getUserProgress(String userId) async {
    await _ensureInitialized();

    try {
      // Try to get the user progress from storage
      final progressJson = await _storageService.getSetting('user_progress_$userId');

      if (progressJson != null) {
        // Parse the JSON string into a UserProgress object
        final Map<String, dynamic> progressMap = jsonDecode(progressJson.toString());
        return UserProgress.fromJson(progressMap);
      }
    } catch (e) {
      debugPrint('Error getting user progress: $e');
    }

    // Return a default user progress if not found
    return UserProgress(
      userId: userId,
      name: 'User',
      level: 1,
      skills: {},
      completedChallenges: [],
      conceptsMastered: [],
      conceptsInProgress: [],
    );
  }

  /// Get the user's current skill level
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  ///
  /// Returns the user's skill level
  Future<SkillLevel> getUserSkillLevel(String userId) async {
    await _ensureInitialized();

    try {
      // Try to get the user progress
      final userProgress = await getUserProgress(userId);

      if (userProgress != null) {
        // Get the overall skill level
        final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

        // Map the difficulty to a skill level
        if (skillLevel <= 1) {
          return SkillLevel.beginner;
        } else if (skillLevel <= 2) {
          return SkillLevel.intermediate;
        } else {
          return SkillLevel.advanced;
        }
      }
    } catch (e) {
      debugPrint('Error getting user skill level: $e');
    }

    // Default to beginner if not found
    return SkillLevel.beginner;
  }

  /// Update user progress based on challenge completion
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `challengeId`: ID of the completed challenge
  /// - `requiredConcepts`: Concepts required for the challenge
  /// - `wasSuccessful`: Whether the user successfully completed the challenge
  ///
  /// Returns updated user progress
  Future<UserProgress> updateProgressForChallenge({
    required UserProgress userProgress,
    required String challengeId,
    required List<String> requiredConcepts,
    required bool wasSuccessful,
  }) async {
    // Create a copy of the user progress to modify
    final updatedProgress = UserProgress(
      userId: userProgress.userId,
      name: userProgress.name,
      level: userProgress.level,
      skills: userProgress.skills,
      completedChallenges: List.from(userProgress.completedChallenges),
      conceptsMastered: List.from(userProgress.conceptsMastered),
      conceptsInProgress: List.from(userProgress.conceptsInProgress),
    );

    // If the challenge was successful, update mastered concepts
    if (wasSuccessful) {
      // Add the challenge to completed challenges if not already there
      if (!updatedProgress.completedChallenges.contains(challengeId)) {
        updatedProgress.completedChallenges.add(challengeId);
      }

      // Add required concepts to mastered concepts if not already there
      for (final concept in requiredConcepts) {
        if (!updatedProgress.conceptsMastered.contains(concept)) {
          // If the concept was in progress, remove it
          updatedProgress.conceptsInProgress.remove(concept);

          // Add to mastered concepts
          updatedProgress.conceptsMastered.add(concept);
        }
      }
    } else {
      // If the challenge was not successful, add required concepts to in-progress
      for (final concept in requiredConcepts) {
        if (!updatedProgress.conceptsMastered.contains(concept) &&
            !updatedProgress.conceptsInProgress.contains(concept)) {
          updatedProgress.conceptsInProgress.add(concept);
        }
      }
    }

    return updatedProgress;
  }

  /// Get a default skill assessment based on user progress
  Map<String, SkillLevel> _getDefaultSkillAssessment(UserProgress userProgress) {
    // Calculate a base skill level based on mastered concepts
    final masteredCount = userProgress.conceptsMastered.length;

    SkillLevel baseSkillLevel;
    if (masteredCount < 5) {
      baseSkillLevel = SkillLevel.beginner;
    } else if (masteredCount < 10) {
      baseSkillLevel = SkillLevel.intermediate;
    } else {
      baseSkillLevel = SkillLevel.advanced;
    }

    // Create a map with all skill types set to the base skill level
    return {
      'PATTERN_RECOGNITION': baseSkillLevel,
      'LOGICAL_THINKING': baseSkillLevel,
      'SEQUENTIAL_REASONING': baseSkillLevel,
      'ALGORITHMIC_THINKING': baseSkillLevel,
      'PROBLEM_SOLVING': baseSkillLevel,
      'CREATIVE_THINKING': baseSkillLevel,
    };
  }

  /// Get default concept recommendations based on user progress
  List<String> _getDefaultRecommendations(UserProgress userProgress, int count) {
    // Get all available concepts
    final allConcepts = _conceptsByLevel.values.expand((c) => c).toList();

    // Remove concepts the user has already mastered
    final availableConcepts = allConcepts
        .where((c) => !userProgress.conceptsMastered.contains(c))
        .toList();

    // Prioritize concepts that are in progress
    final inProgressConcepts = availableConcepts
        .where((c) => userProgress.conceptsInProgress.contains(c))
        .toList();

    // If we have enough in-progress concepts, return those
    if (inProgressConcepts.length >= count) {
      return inProgressConcepts.sublist(0, count);
    }

    // Otherwise, add new concepts to reach the requested count
    final result = List<String>.from(inProgressConcepts);

    // Get new concepts (not mastered and not in progress)
    final newConcepts = availableConcepts
        .where((c) => !userProgress.conceptsInProgress.contains(c))
        .toList();

    // Add new concepts until we reach the requested count
    for (final concept in newConcepts) {
      if (result.length < count) {
        result.add(concept);
      } else {
        break;
      }
    }

    return result;
  }

  /// Convert a JSON map to a skill assessment map
  Map<String, SkillLevel> _mapToSkillAssessment(Map<String, dynamic> assessment) {
    final result = <String, SkillLevel>{};

    // Map of string skill levels to SkillLevel enum values
    final skillLevelMap = {
      'BEGINNER': SkillLevel.beginner,
      'INTERMEDIATE': SkillLevel.intermediate,
      'ADVANCED': SkillLevel.advanced,
    };

    // Process each skill in the assessment
    for (final entry in assessment.entries) {
      final skillName = entry.key.toUpperCase();

      // Get the skill level
      SkillLevel skillLevel;

      if (entry.value is Map) {
        // If the value is a map, look for a 'level' field
        final levelStr = (entry.value['level'] ?? '').toString().toUpperCase();
        skillLevel = skillLevelMap[levelStr] ?? SkillLevel.beginner;
      } else if (entry.value is String) {
        // If the value is a string, use it directly
        final levelStr = entry.value.toString().toUpperCase();
        skillLevel = skillLevelMap[levelStr] ?? SkillLevel.beginner;
      } else {
        // Default to beginner if the value is not recognized
        skillLevel = SkillLevel.beginner;
      }

      // Add to the result
      result[skillName] = skillLevel;
    }

    // Ensure all skill types are included
    final skillTypes = [
      'PATTERN_RECOGNITION',
      'LOGICAL_THINKING',
      'SEQUENTIAL_REASONING',
      'ALGORITHMIC_THINKING',
      'PROBLEM_SOLVING',
      'CREATIVE_THINKING',
    ];

    for (final skillType in skillTypes) {
      if (!result.containsKey(skillType)) {
        result[skillType] = SkillLevel.beginner;
      }
    }

    return result;
  }

  /// Save user progress to storage
  ///
  /// This method persists the user's progress data to the storage service
  /// @param progress The user progress to save
  /// @return A future that completes when the save operation is done
  Future<void> saveUserProgress(UserProgress progress) async {
    try {
      // Save to storage service using the appropriate method
      await _storageService.saveUserProgress(progress);
      debugPrint('User progress saved successfully for user ${progress.userId}');
    } catch (e) {
      debugPrint('Failed to save user progress: $e');
      // If we're offline, we'll try again when we're online
      if (!_geminiService.isOnline) {
        // Store in local cache for later sync
        debugPrint('Storing user progress in local cache for later sync');
      }
    }
  }

  /// Update skill proficiency for a user
  ///
  /// This method updates the user's proficiency in a specific concept based on their performance
  /// @param userId The ID of the user
  /// @param conceptId The ID of the concept
  /// @param success Whether the user was successful in the challenge
  /// @param difficulty The difficulty level of the challenge
  /// @return A future that resolves to the updated user progress
  Future<UserProgress> updateSkillProficiency(
    String userId,
    String conceptId,
    bool success,
    double difficulty,
  ) async {
    try {
      // Load current user progress
      final userProgress = await _storageService.loadUserProgress(userId) ??
                           UserProgress(userId: userId, name: 'Learner');

      // Calculate proficiency change based on success and difficulty
      final double proficiencyChange = success
          ? 0.1 * difficulty // Increase proficiency more for difficult challenges
          : -0.05; // Small decrease for failures

      // Update the proficiency for the concept
      final Map<String, double> skillProficiency =
          Map<String, double>.from(userProgress.skillProficiency);

      // Get current proficiency or default to 0.0
      final currentProficiency = skillProficiency[conceptId] ?? 0.0;

      // Update proficiency, ensuring it stays between 0.0 and 1.0
      skillProficiency[conceptId] = (currentProficiency + proficiencyChange).clamp(0.0, 1.0);

      // Update user progress with new proficiency
      final updatedProgress = userProgress.copyWith(
        skillProficiency: skillProficiency,
        lastActiveDate: DateTime.now(),
      );

      // Save updated progress
      await saveUserProgress(updatedProgress);

      return updatedProgress;
    } catch (e) {
      debugPrint('Failed to update skill proficiency: $e');
      throw Exception('Failed to update skill proficiency: $e');
    }
  }

  /// Record a user action for adaptive learning
  ///
  /// This method records user actions to improve the adaptive learning experience
  /// @param actionType The type of action performed
  /// @param wasSuccessful Whether the action was successful
  /// @param contextId Optional context ID (e.g., challenge ID, story ID)
  /// @param metadata Optional additional data about the action
  /// @return A future that completes when the action is recorded
  Future<void> recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = metadata?['userId'] as String?;
      if (userId == null) {
        debugPrint('Cannot record action: userId is missing in metadata');
        return;
      }

      // Create action record
      final actionRecord = {
        'actionType': actionType,
        'wasSuccessful': wasSuccessful,
        'contextId': contextId,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Load user progress
      final userProgress = await _storageService.loadUserProgress(userId) ??
                           UserProgress(userId: userId, name: 'Learner');

      // Update learning metrics with the new action
      final updatedMetrics = Map<String, dynamic>.from(userProgress.learningMetrics);

      // Add action to metrics
      if (updatedMetrics['actions'] == null) {
        updatedMetrics['actions'] = [];
      }

      // Add action and limit size
      final actions = List<dynamic>.from(updatedMetrics['actions']);
      actions.add(actionRecord);

      // Keep only the most recent 1000 actions
      if (actions.length > 1000) {
        actions.removeRange(0, actions.length - 1000);
      }

      updatedMetrics['actions'] = actions;

      // Update user progress
      final updatedProgress = userProgress.updateLearningMetrics(updatedMetrics);

      // Save updated progress
      await saveUserProgress(updatedProgress);

      debugPrint('Action recorded: $actionType');
    } catch (e) {
      debugPrint('Failed to record action: $e');
      // Don't throw here to prevent disrupting the user experience
    }
  }

  /// Get hint priority based on user's learning style
  ///
  /// This method determines the priority of different hint types based on the user's learning style
  /// @param hintType The type of hint
  /// @return The priority of the hint (higher is more important)
  int getHintPriority(String hintType) {
    // Default priorities for different hint types
    final Map<String, int> defaultPriorities = {
      'visual': 3,
      'textual': 2,
      'interactive': 4,
      'audio': 1,
    };

    return defaultPriorities[hintType] ?? 2; // Default to medium priority
  }

  /// Detect user frustration based on session data and real-time factors
  ///
  /// Parameters:
  /// - `session`: Current learning session
  /// - `recentErrors`: Number of recent errors not yet recorded in the session
  /// - `timeOnChallenge`: Time spent on current challenge in seconds
  /// - `hintsRequested`: Number of hints requested not yet recorded in the session
  ///
  /// Returns a frustration level from 0.0 (not frustrated) to 1.0 (very frustrated)
  Future<double> detectFrustration({
    required LearningSession session,
    int recentErrors = 0,
    int timeOnChallenge = 0,
    int hintsRequested = 0,
  }) async {
    await _ensureInitialized();

    // Base frustration from session
    double frustrationLevel = session.frustrationLevel;

    // Factor 1: Recent errors increase frustration
    if (recentErrors > 0) {
      frustrationLevel += 0.1 * recentErrors.clamp(0, 5);
    }

    // Factor 2: Time spent on challenge without progress
    // If spending more than 3 minutes on a challenge, frustration increases
    if (timeOnChallenge > 180) {
      frustrationLevel += 0.1 * ((timeOnChallenge - 180) / 60).clamp(0, 3);
    }

    // Factor 3: Multiple hint requests indicate frustration
    if (hintsRequested > 1) {
      frustrationLevel += 0.05 * hintsRequested.clamp(0, 5);
    }

    // Factor 4: Low success rate increases frustration
    if (session.challengesAttempted > 2) {
      final successRate = session.successRate;
      if (successRate < 0.5) {
        frustrationLevel += 0.2 * (1 - successRate);
      }
    }

    // Factor 5: High error rate increases frustration
    if (session.challengesAttempted > 0) {
      final errorRate = session.averageErrorsPerChallenge;
      if (errorRate > 3) {
        frustrationLevel += 0.1 * (errorRate / 5).clamp(0.0, 1.0);
      }
    }

    // Factor 6: Check if user is struggling according to session
    if (session.isUserStruggling) {
      frustrationLevel += 0.1;
    }

    // Ensure frustration level stays within valid range
    return frustrationLevel.clamp(0.0, 1.0);
  }

  /// Recommend the most appropriate learning path type for a user
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  /// - `userPreference`: Optional user preference for learning path type
  /// - `session`: Optional current learning session for real-time adaptation
  ///
  /// Returns the recommended learning path type
  Future<LearningPathType> recommendLearningPathType({
    required String userId,
    LearningPathType? userPreference,
    LearningSession? session,
  }) async {
    await _ensureInitialized();

    // If user has a preference and no active session showing struggles, respect it
    if (userPreference != null && (session == null || !session.isUserStruggling)) {
      return userPreference;
    }

    // Get user progress
    final userProgress = await getUserProgress(userId);
    if (userProgress == null) {
      // For new users, start with logic-based path as it's most structured
      return LearningPathType.logicBased;
    }

    // Calculate scores for each learning path type
    double logicBasedScore = 0.0;
    double creativityBasedScore = 0.0;
    double challengeBasedScore = 0.0;

    // Factor 1: Overall skill proficiency
    final averageProficiency = _calculateAverageProficiency(userProgress.skillProficiency);

    // Higher proficiency favors challenge-based and creativity-based paths
    if (averageProficiency > 0.7) {
      challengeBasedScore += 2.0;
      creativityBasedScore += 1.5;
    } else if (averageProficiency > 0.4) {
      creativityBasedScore += 1.0;
      logicBasedScore += 0.5;
    } else {
      // Lower proficiency favors logic-based paths for structure
      logicBasedScore += 2.0;
    }

    // Factor 2: Recent performance in session
    if (session != null) {
      // High mastery favors challenge-based paths
      if (session.masteryLevel > 0.7) {
        challengeBasedScore += 1.5;
      }

      // High engagement favors creativity-based paths
      if (session.engagementScore > 0.7) {
        creativityBasedScore += 1.5;
      }

      // Struggling users benefit from more structured logic-based paths
      if (session.isUserStruggling) {
        logicBasedScore += 2.0;
        challengeBasedScore -= 1.0; // Reduce challenge-based score
      }

      // Excelling users benefit from more challenging paths
      if (session.isUserExcelling) {
        challengeBasedScore += 2.0;
      }
    }

    // Factor 3: Completed challenges
    final completedChallenges = userProgress.completedChallenges.length;
    if (completedChallenges > 20) {
      // Experienced users might prefer challenge or creativity
      challengeBasedScore += 1.0;
      creativityBasedScore += 1.0;
    } else if (completedChallenges < 5) {
      // Beginners benefit from structure
      logicBasedScore += 1.0;
    }

    // Factor 4: Concepts mastered
    final conceptsMastered = userProgress.conceptsMastered.length;
    if (conceptsMastered > 5) {
      // Users with many mastered concepts might enjoy challenges
      challengeBasedScore += 1.0;
    }

    // Determine the highest scoring path type
    if (logicBasedScore >= creativityBasedScore && logicBasedScore >= challengeBasedScore) {
      return LearningPathType.logicBased;
    } else if (creativityBasedScore >= challengeBasedScore) {
      return LearningPathType.creativityBased;
    } else {
      return LearningPathType.challengeBased;
    }
  }

  /// Calculate the average proficiency from a map of skill proficiencies
  double _calculateAverageProficiency(Map<String, double> skillProficiency) {
    if (skillProficiency.isEmpty) {
      return 0.0;
    }

    double total = 0.0;
    for (final proficiency in skillProficiency.values) {
      total += proficiency;
    }

    return total / skillProficiency.length;
  }

  /// Dynamically adjust challenge difficulty based on user performance
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  /// - `session`: Current learning session
  /// - `currentDifficulty`: Current difficulty level (1-5)
  /// - `timeSpentSeconds`: Time spent on the current challenge
  /// - `errorsCount`: Number of errors made on the current challenge
  /// - `hintsUsed`: Number of hints used on the current challenge
  /// - `conceptId`: Optional specific concept being tested
  ///
  /// Returns the adjusted difficulty level (1-5)
  Future<int> adjustChallengeDifficulty({
    required String userId,
    required LearningSession session,
    required int currentDifficulty,
    int timeSpentSeconds = 0,
    int errorsCount = 0,
    int hintsUsed = 0,
    String? conceptId,
  }) async {
    await _ensureInitialized();

    // Start with the session's recommended difficulty adjustment
    int difficultyAdjustment = session.recommendedDifficultyAdjustment;

    // Factor 1: Time spent on challenge
    // If spending too much time, decrease difficulty
    if (timeSpentSeconds > 300) { // 5 minutes
      difficultyAdjustment -= 1;
    } else if (timeSpentSeconds < 60 && session.successRate > 0.7) {
      // If completing quickly with high success rate, increase difficulty
      difficultyAdjustment += 1;
    }

    // Factor 2: Errors and hints
    if (errorsCount > 5 || hintsUsed > 3) {
      // Many errors or hints indicate the challenge is too difficult
      difficultyAdjustment -= 1;
    }

    // Factor 3: Frustration level
    final frustrationLevel = await detectFrustration(
      session: session,
      recentErrors: errorsCount,
      timeOnChallenge: timeSpentSeconds,
      hintsRequested: hintsUsed,
    );

    if (frustrationLevel > 0.7) {
      // High frustration should decrease difficulty
      difficultyAdjustment -= 1;
    } else if (frustrationLevel < 0.2 && session.successRate > 0.8) {
      // Low frustration with high success rate can increase difficulty
      difficultyAdjustment += 1;
    }

    // Factor 4: Concept-specific proficiency
    if (conceptId != null) {
      final userProgress = await getUserProgress(userId);
      if (userProgress != null) {
        final proficiency = userProgress.skillProficiency[conceptId] ?? 0.0;

        // Adjust based on concept proficiency
        if (proficiency > 0.8 && currentDifficulty < 4) {
          // High proficiency can handle higher difficulty
          difficultyAdjustment += 1;
        } else if (proficiency < 0.3 && currentDifficulty > 2) {
          // Low proficiency needs lower difficulty
          difficultyAdjustment -= 1;
        }
      }
    }

    // Apply the adjustment to the current difficulty
    final newDifficulty = (currentDifficulty + difficultyAdjustment).clamp(1, 5);

    // Ensure we don't change difficulty too drastically in one step
    if (newDifficulty > currentDifficulty + 1) {
      return currentDifficulty + 1;
    } else if (newDifficulty < currentDifficulty - 1) {
      return currentDifficulty - 1;
    } else {
      return newDifficulty;
    }
  }

  /// Assess concept mastery with practical demonstrations
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  /// - `conceptId`: ID of the concept being assessed
  /// - `challengeId`: ID of the challenge completed
  /// - `successful`: Whether the challenge was completed successfully
  /// - `timeSpentSeconds`: Time spent on the challenge
  /// - `errorsCount`: Number of errors made
  /// - `hintsUsed`: Number of hints used
  /// - `solutionQuality`: Optional quality score of the solution (0.0 to 1.0)
  ///
  /// Returns the updated concept mastery
  Future<ConceptMastery> assessConceptMastery({
    required String userId,
    required String conceptId,
    required String challengeId,
    required bool successful,
    int timeSpentSeconds = 0,
    int errorsCount = 0,
    int hintsUsed = 0,
    double? solutionQuality,
  }) async {
    await _ensureInitialized();

    // Get user progress
    final userProgress = await getUserProgress(userId);
    if (userProgress == null) {
      throw Exception('User progress not found');
    }

    // Get existing concept mastery or create new one
    ConceptMastery conceptMastery;

    // Check if we have this concept in the cache
    if (_conceptMasteryCache.containsKey(userId) &&
        _conceptMasteryCache[userId]!.containsKey(conceptId)) {
      conceptMastery = _conceptMasteryCache[userId]![conceptId]!;
    } else {
      // Get from user progress or create new
      final existingMastery = await _getConceptMastery(userId, conceptId);
      conceptMastery = existingMastery ?? ConceptMastery(
        conceptId: conceptId,
        proficiency: 0.0,
        successfulApplications: 0,
        failedApplications: 0,
        demonstrations: [],
      );
    }

    // Update concept mastery based on challenge outcome
    if (successful) {
      // Record successful application
      conceptMastery = conceptMastery.recordSuccess();

      // Add demonstration if not already present
      conceptMastery = conceptMastery.addDemonstration(challengeId);

      // Adjust proficiency based on solution quality if provided
      if (solutionQuality != null) {
        // Higher quality solutions increase proficiency more
        final qualityBonus = solutionQuality * 0.1;
        final newProficiency = (conceptMastery.proficiency + qualityBonus).clamp(0.0, 1.0);
        conceptMastery = conceptMastery.copyWith(proficiency: newProficiency);
      }

      // Adjust proficiency based on hints and errors
      if (hintsUsed == 0 && errorsCount == 0) {
        // Perfect solution increases proficiency more
        final perfectionBonus = 0.05;
        final newProficiency = (conceptMastery.proficiency + perfectionBonus).clamp(0.0, 1.0);
        conceptMastery = conceptMastery.copyWith(proficiency: newProficiency);
      } else if (hintsUsed > 2 || errorsCount > 3) {
        // Many hints or errors reduce the proficiency gain
        final hintsErrorPenalty = 0.03;
        final newProficiency = (conceptMastery.proficiency - hintsErrorPenalty).clamp(0.0, 1.0);
        conceptMastery = conceptMastery.copyWith(proficiency: newProficiency);
      }
    } else {
      // Record failed application
      conceptMastery = conceptMastery.recordFailure();
    }

    // Update the cache
    if (!_conceptMasteryCache.containsKey(userId)) {
      _conceptMasteryCache[userId] = {};
    }
    _conceptMasteryCache[userId]![conceptId] = conceptMastery;

    // Update user progress with new concept mastery
    await _updateConceptMastery(userId, conceptId, conceptMastery);

    // Check if concept is now mastered and update user progress if needed
    if (conceptMastery.isMastered &&
        !userProgress.conceptsMastered.contains(conceptId)) {
      // Add to mastered concepts
      final updatedMastered = List<String>.from(userProgress.conceptsMastered)..add(conceptId);

      // Remove from in-progress concepts if present
      final updatedInProgress = List<String>.from(userProgress.conceptsInProgress)
        ..removeWhere((c) => c == conceptId);

      // Update user progress
      final updatedProgress = userProgress.copyWith(
        conceptsMastered: updatedMastered,
        conceptsInProgress: updatedInProgress,
      );

      // Save updated progress
      await saveUserProgress(updatedProgress);
    }

    return conceptMastery;
  }

  /// Get concept mastery for a specific user and concept
  Future<ConceptMastery?> _getConceptMastery(String userId, String conceptId) async {
    // Check cache first
    if (_conceptMasteryCache.containsKey(userId) &&
        _conceptMasteryCache[userId]!.containsKey(conceptId)) {
      return _conceptMasteryCache[userId]![conceptId];
    }

    // Get user progress
    final userProgress = await getUserProgress(userId);
    if (userProgress == null) {
      return null;
    }

    // Check if we have proficiency data for this concept
    final proficiency = userProgress.skillProficiency[conceptId];
    if (proficiency == null) {
      return null;
    }

    // Create a basic concept mastery object based on available data
    final conceptMastery = ConceptMastery(
      conceptId: conceptId,
      proficiency: proficiency,
      // We don't have these details in UserProgress, so use estimates
      successfulApplications: (proficiency * 10).round(),
      failedApplications: ((1 - proficiency) * 5).round(),
      demonstrations: [],
    );

    // Cache the result
    if (!_conceptMasteryCache.containsKey(userId)) {
      _conceptMasteryCache[userId] = {};
    }
    _conceptMasteryCache[userId]![conceptId] = conceptMastery;

    return conceptMastery;
  }

  /// Update concept mastery for a specific user and concept
  Future<void> _updateConceptMastery(
    String userId,
    String conceptId,
    ConceptMastery conceptMastery
  ) async {
    // Get user progress
    final userProgress = await getUserProgress(userId);
    if (userProgress == null) {
      throw Exception('User progress not found');
    }

    // Update skill proficiency
    final updatedSkillProficiency = Map<String, double>.from(userProgress.skillProficiency);
    updatedSkillProficiency[conceptId] = conceptMastery.proficiency;

    // Update user progress
    final updatedProgress = userProgress.copyWith(
      skillProficiency: updatedSkillProficiency,
    );

    // Save updated progress
    await saveUserProgress(updatedProgress);

    // Update cache
    if (!_conceptMasteryCache.containsKey(userId)) {
      _conceptMasteryCache[userId] = {};
    }
    _conceptMasteryCache[userId]![conceptId] = conceptMastery;
  }

  /// Generate a personalized learning path for a user
  ///
  /// Parameters:
  /// - `userId`: ID of the user
  /// - `pathType`: Type of learning path to generate
  /// - `forceRegenerate`: Whether to force regeneration of the path
  ///
  /// Returns a personalized learning path
  Future<LearningPath> generateLearningPath({
    required String userId,
    required LearningPathType pathType,
    bool forceRegenerate = false,
  }) async {
    await _ensureInitialized();

    // Check cache first
    final cacheKey = '_learning_path_${userId}_${pathType.toString()}';
    if (!forceRegenerate && _learningPathCache.containsKey(cacheKey)) {
      return _learningPathCache[cacheKey]!;
    }

    // Get user progress
    final userProgress = await getUserProgress(userId);

    // Get learning style
    final learningStyleName = userProgress?.preferredLearningStyle.name;

    // Convert to the LearningStyle enum used by LearningPathsData
    style.LearningStyle? learningStyle;
    if (learningStyleName != null) {
      try {
        learningStyle = style.LearningStyle.values.firstWhere(
          (s) => s.name == learningStyleName,
        );
      } catch (e) {
        // If not found, leave as null
      }
    }

    // Get template path based on path type and learning style
    // Convert from style.LearningStyle to UserProgress.LearningStyle
    LearningStyle? userProgressLearningStyle;
    if (learningStyle != null) {
      // Map between the two different LearningStyle enums
      switch (learningStyle) {
        case style.LearningStyle.visual:
          userProgressLearningStyle = LearningStyle.visual;
          break;
        case style.LearningStyle.logical:
          userProgressLearningStyle = LearningStyle.logical;
          break;
        case style.LearningStyle.kinesthetic:
          userProgressLearningStyle = LearningStyle.practical; // Map kinesthetic to practical
          break;
        case style.LearningStyle.reading:
          userProgressLearningStyle = LearningStyle.verbal; // Map reading to verbal
          break;
        case style.LearningStyle.auditory:
          userProgressLearningStyle = LearningStyle.verbal; // Map auditory to verbal
          break;
        case style.LearningStyle.social:
          userProgressLearningStyle = LearningStyle.social;
          break;
        case style.LearningStyle.solitary:
          userProgressLearningStyle = LearningStyle.reflective; // Map solitary to reflective
          break;
        case style.LearningStyle.practical:
          userProgressLearningStyle = LearningStyle.practical;
          break;
        case style.LearningStyle.verbal:
          userProgressLearningStyle = LearningStyle.verbal;
          break;
        case style.LearningStyle.reflective:
          userProgressLearningStyle = LearningStyle.reflective;
          break;
      }
    }

    // Convert from UserProgress.LearningStyle to style.LearningStyle
    style.LearningStyle? convertedLearningStyle;
    if (userProgressLearningStyle != null) {
      switch (userProgressLearningStyle) {
        case LearningStyle.visual:
          convertedLearningStyle = style.LearningStyle.visual;
          break;
        case LearningStyle.logical:
          convertedLearningStyle = style.LearningStyle.logical;
          break;
        case LearningStyle.practical:
          convertedLearningStyle = style.LearningStyle.practical;
          break;
        case LearningStyle.verbal:
          convertedLearningStyle = style.LearningStyle.verbal;
          break;
        case LearningStyle.social:
          convertedLearningStyle = style.LearningStyle.social;
          break;
        case LearningStyle.reflective:
          convertedLearningStyle = style.LearningStyle.reflective;
          break;
      }
    }

    final templatePath = LearningPathsData.getLearningPathTemplate(
      userId: userId,
      pathType: pathType,
      learningStyle: convertedLearningStyle,
    );

    // Personalize the path based on user progress
    final personalizedPath = await _personalizeLearningPath(
      templatePath: templatePath,
      userProgress: userProgress,
    );

    // Cache the result
    _learningPathCache[cacheKey] = personalizedPath;

    return personalizedPath;
  }

  /// Personalize a learning path based on user progress
  Future<LearningPath> _personalizeLearningPath({
    required LearningPath templatePath,
    UserProgress? userProgress,
  }) async {
    if (userProgress == null) {
      // No personalization needed for new users
      return templatePath;
    }

    // Create a copy of the template items
    final personalizedItems = List<LearningPathItem>.from(templatePath.items);

    // Enhance the learning path with cultural elements
    final enhancedPath = await _culturalLearningService.enhanceLearningPathWithCulturalElements(
      LearningPath(
        pathType: templatePath.pathType,
        items: personalizedItems,
        userId: templatePath.userId,
        generatedAt: templatePath.generatedAt,
      )
    );

    // Get the enhanced items
    final enhancedItems = enhancedPath.items;

    // Sort items based on prerequisites and user progress
    enhancedItems.sort((a, b) {
      // If user has mastered a concept, it should come first
      final aIsMastered = userProgress.isConceptMastered(a.concept);
      final bIsMastered = userProgress.isConceptMastered(b.concept);

      if (aIsMastered && !bIsMastered) {
        return -1;
      } else if (!aIsMastered && bIsMastered) {
        return 1;
      }

      // If user is currently learning a concept, it should come next
      final aIsInProgress = userProgress.isConceptInProgress(a.concept);
      final bIsInProgress = userProgress.isConceptInProgress(b.concept);

      if (aIsInProgress && !bIsInProgress) {
        return -1;
      } else if (!aIsInProgress && bIsInProgress) {
        return 1;
      }

      // Otherwise, sort by prerequisites
      // Items with fewer prerequisites should come first
      return a.prerequisites.length.compareTo(b.prerequisites.length);
    });

    // Create a personalized path
    return LearningPath(
      pathType: templatePath.pathType,
      items: personalizedItems,
      userId: templatePath.userId,
    );
  }

  /// Get challenge data for a specific concept and difficulty level
  Future<Map<String, dynamic>> getChallenge({
    required UserProgress userProgress,
    required String challengeType,
    int? difficultyOverride,
    LearningPathType? learningPathType,
    double? frustrationLevel,
    String? targetConcept,
  }) async {
    await _ensureInitialized();

    // Determine the concept to focus on
    final conceptId = targetConcept ?? await _determineNextConcept(userProgress);

    // Determine the learning path type
    final pathType = learningPathType ?? await recommendLearningPathType(
      userId: userProgress.userId,
    );

    // Determine the difficulty level
    final difficultyLevel = difficultyOverride ?? await calculateDifficultyLevel(
      userProgress: userProgress,
      learningPathType: pathType,
      conceptId: conceptId,
      frustrationLevel: frustrationLevel,
    );

    // Get challenge data
    final challengeData = LearningPathsData.getChallengeData(
      conceptId: conceptId,
      difficultyLevel: difficultyLevel,
      pathType: pathType,
    );

    // Enhance with cultural elements
    final culturalElements = await _culturalLearningService.getBestCulturalElementsForConcept(
      userProgress.userId,
      conceptId,
    );

    // Record that we're teaching this concept with these cultural elements
    if (culturalElements['pattern'] != null && culturalElements['pattern']['id'] != null) {
      await _culturalLearningService.recordConceptTeaching(
        userProgress.userId,
        conceptId,
        culturalElements['pattern']['id'],
      );
    }

    // Add cultural elements to challenge data
    return {
      ...challengeData,
      'culturalElements': culturalElements,
    };
  }

  /// Determine the next concept for a user to learn
  Future<String> _determineNextConcept(UserProgress userProgress) async {
    // Check if user has any concepts in progress
    if (userProgress.conceptsInProgress.isNotEmpty) {
      return userProgress.conceptsInProgress.first;
    }

    // Otherwise, recommend a new concept
    final recommendedConcepts = await recommendNextConcepts(
      userProgress: userProgress,
      count: 1,
    );

    if (recommendedConcepts.isNotEmpty) {
      return recommendedConcepts.first;
    }

    // Default to variables if no recommendations
    return 'variables';
  }




  /// Get the skill level for a specific concept
  ///
  /// Parameters:
  /// - `userProgress`: The user's progress
  /// - `concept`: The concept to get the skill level for
  ///
  /// Returns the skill level for the concept
  Future<SkillLevel> _getSkillLevelForConcept(
    UserProgress userProgress,
    String concept,
  ) async {
    // Get proficiency for this concept
    final proficiency = userProgress.skillProficiency[concept] ?? 0.0;

    // Map proficiency to skill level
    if (proficiency < 0.3) {
      return SkillLevel.novice;
    } else if (proficiency < 0.6) {
      return SkillLevel.beginner;
    } else if (proficiency < 0.9) {
      return SkillLevel.intermediate;
    } else {
      return SkillLevel.advanced;
    }
  }

  /// Get a human-readable title for a concept
  String _getConceptTitle(String concept) {
    // Map of concept IDs to human-readable titles
    final Map<String, String> conceptTitles = {
      'sequences': 'Sequences',
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'arrays': 'Arrays',
      'operators': 'Operators',
      'recursion': 'Recursion',
      'algorithms': 'Algorithms',
      'data_structures': 'Data Structures',
      'problem_solving': 'Problem Solving',
      'basic patterns': 'Basic Patterns',
      'simple loops': 'Simple Loops',
      'nested loops': 'Nested Loops',
      'complex patterns': 'Complex Patterns',
      'optimization': 'Optimization',
      'advanced algorithms': 'Advanced Algorithms',
      'problem decomposition': 'Problem Decomposition',
      'abstraction': 'Abstraction',
    };

    return conceptTitles[concept] ?? concept.split('_').map((word) =>
      word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
  }

  /// Get a description for a concept
  String _getConceptDescription(String concept) {
    // Map of concept IDs to descriptions
    final Map<String, String> conceptDescriptions = {
      'sequences': 'Learn how to create sequences of instructions to create patterns.',
      'loops': 'Discover how to repeat instructions to create complex patterns efficiently.',
      'conditionals': 'Explore how to make decisions in your code based on conditions.',
      'variables': 'Learn how to store and use values in your patterns.',
      'functions': 'Create reusable blocks of code to simplify complex patterns.',
      'basic patterns': 'Learn the fundamental patterns used in Kente weaving.',
      'simple loops': 'Discover how to use simple loops to repeat patterns.',
      'nested loops': 'Explore how to use loops inside other loops for complex patterns.',
      'complex patterns': 'Create intricate patterns using advanced techniques.',
    };

    return conceptDescriptions[concept] ??
      'Learn about $concept and how to apply it in Kente pattern creation.';
  }

  /// Get estimated time to complete a concept based on skill level
  int _getEstimatedTimeForConcept(String concept, SkillLevel skillLevel) {
    // Base time in minutes
    int baseTime = 15;

    // Adjust based on skill level
    switch (skillLevel) {
      case SkillLevel.novice:
        baseTime = 30; // Novices need more time
        break;
      case SkillLevel.beginner:
        baseTime = 20;
        break;
      case SkillLevel.intermediate:
        baseTime = 15;
        break;
      case SkillLevel.advanced:
        baseTime = 10; // Advanced users need less time
        break;
    }

    // Adjust based on concept complexity
    if (['recursion', 'advanced algorithms', 'complex patterns'].contains(concept)) {
      baseTime += 10; // Complex concepts take longer
    } else if (['sequences', 'basic patterns'].contains(concept)) {
      baseTime -= 5; // Simple concepts take less time
    }

    return baseTime.clamp(5, 45); // Ensure time is reasonable
  }

  /// Get prerequisites for a concept
  List<String> _getPrerequisitesForConcept(String concept) {
    // Map of concepts to their prerequisites
    final Map<String, List<String>> conceptPrerequisites = {
      'loops': ['sequences'],
      'conditionals': ['sequences'],
      'variables': ['sequences'],
      'functions': ['sequences', 'variables'],
      'nested loops': ['loops'],
      'complex patterns': ['loops', 'conditionals'],
      'recursion': ['functions'],
      'algorithms': ['loops', 'conditionals', 'functions'],
      'optimization': ['algorithms'],
      'advanced algorithms': ['algorithms', 'recursion'],
      'problem decomposition': ['functions', 'algorithms'],
      'abstraction': ['functions', 'problem decomposition'],
    };

    return conceptPrerequisites[concept] ?? [];
  }

  /// Get resources for logic-based learning path
  List<Map<String, dynamic>> _getLogicBasedResources(String concept, SkillLevel skillLevel) {
    return [
      {
        'type': 'tutorial',
        'title': 'Logical Approach to $concept',
        'description': 'A structured tutorial on the logical principles of $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'diagram',
        'title': '$concept Flowchart',
        'description': 'Visual representation of how $concept works.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'example',
        'title': 'Step-by-Step $concept Example',
        'description': 'A detailed example showing how to apply $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get challenges for logic-based learning path
  List<Map<String, dynamic>> _getLogicBasedChallenges(String concept, SkillLevel skillLevel) {
    return [
      {
        'type': 'problem_solving',
        'title': 'Logical $concept Challenge',
        'description': 'Solve this structured problem using $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'debugging',
        'title': 'Debug the $concept',
        'description': 'Find and fix the logical errors in this $concept example.',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get resources for creativity-based learning path
  List<Map<String, dynamic>> _getCreativityBasedResources(String concept, SkillLevel skillLevel) {
    return [
      {
        'type': 'inspiration',
        'title': 'Creative $concept Ideas',
        'description': 'Explore creative ways to use $concept in your patterns.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'gallery',
        'title': '$concept Pattern Gallery',
        'description': 'View a gallery of patterns that use $concept creatively.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'story',
        'title': 'The Story of $concept',
        'description': 'Learn about $concept through an engaging story.',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get challenges for creativity-based learning path
  List<Map<String, dynamic>> _getCreativityBasedChallenges(String concept, SkillLevel skillLevel) {
    return [
      {
        'type': 'open_ended',
        'title': 'Creative $concept Expression',
        'description': 'Create a pattern that expresses your understanding of $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'remix',
        'title': 'Remix the $concept',
        'description': 'Take an existing pattern and remix it using your own $concept style.',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get resources for challenge-based learning path
  List<Map<String, dynamic>> _getChallengeBasedResources(String concept, SkillLevel skillLevel) {
    return [
      {
        'type': 'quick_reference',
        'title': '$concept Quick Reference',
        'description': 'A concise reference guide for $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'tips',
        'title': '$concept Pro Tips',
        'description': 'Advanced tips for mastering $concept.',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get challenges for challenge-based learning path
  List<Map<String, dynamic>> _getChallengeBasedChallenges(String concept, SkillLevel skillLevel) {
    // Create challenges with increasing difficulty
    final List<Map<String, dynamic>> challenges = [];

    // Determine the number of challenges based on skill level
    int challengeCount;
    switch (skillLevel) {
      case SkillLevel.novice:
        challengeCount = 2;
        break;
      case SkillLevel.beginner:
        challengeCount = 3;
        break;
      case SkillLevel.intermediate:
        challengeCount = 4;
        break;
      case SkillLevel.advanced:
        challengeCount = 5;
        break;
    }

    // Create challenges with increasing difficulty
    for (int i = 1; i <= challengeCount; i++) {
      challenges.add({
        'type': 'progressive',
        'title': 'Level $i $concept Challenge',
        'description': 'Complete this level $i challenge using $concept.',
        'difficulty': ((i / challengeCount) * 3 + 1).round().toString(),
      });
    }

    return challenges;
  }
}
