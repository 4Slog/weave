import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service_helper.dart';

/// Service for adaptive learning progression
///
/// This service provides AI-driven difficulty progression, skill assessment,
/// learning style detection, and concept recommendations.
/// Features include:
/// - AI-driven difficulty progression instead of age-based
/// - Improved skill assessment algorithms
/// - More sophisticated learning style detection
/// - Enhanced recommendation algorithms for next concepts
class AdaptiveLearningService {
  /// Gemini instance for API interactions
  late final gemini.Gemini _gemini;

  /// Storage service for caching responses
  final StorageService _storageService;

  /// Flag indicating if the device is online (determined by API response)
  bool _isOnline = true;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Cache for skill assessments to reduce API calls
  final Map<String, Map<String, dynamic>> _assessmentCache = {};

  /// Cache for learning style detection to reduce API calls
  final Map<String, String> _learningStyleCache = {};

  /// Cache for concept recommendations to reduce API calls
  final Map<String, List<String>> _recommendationCache = {};

  /// Cache key prefix for recommendations
  static const String _recommendationCachePrefix = 'adaptive_learning_recommendations_';

  /// Learning styles supported by the system
  final List<String> _supportedLearningStyles = [
    'visual', 'auditory', 'kinesthetic', 'reading/writing', 'mixed'
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
  }) :
    _storageService = storageService ?? StorageService();

  /// Initializes the Gemini service with the API key from environment variables.
  ///
  /// Throws an exception if the API key is not found or initialization fails.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get API key from environment variables
      final String? apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found');
      }

      // Initialize Gemini with the API key
      gemini.Gemini.init(apiKey: apiKey);
      _gemini = gemini.Gemini.instance;

      // Check connectivity by making a simple API call
      await checkConnectivity();

      _isInitialized = true;
      debugPrint('AdaptiveLearningService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdaptiveLearningService: $e');
      throw Exception('Failed to initialize AdaptiveLearningService: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Check connectivity by making a simple API call
  Future<bool> checkConnectivity() async {
    try {
      // Try a simple API call to check connectivity
      final response = await _gemini.prompt(parts: [gemini.Part.text("Hello")]);

      _isOnline = response != null;
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      return false;
    }
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
    if (!_isOnline) {
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
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

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
    if (!_isOnline || interactionHistory == null) {
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
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

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
    final cacheKey = '$_recommendationCachePrefix${userProgress.userId}_$count';

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
    if (!_isOnline) {
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
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

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
  ///
  /// Returns a difficulty level from 1 (easiest) to 5 (hardest)
  Future<int> calculateDifficultyLevel({
    required UserProgress userProgress,
  }) async {
    await _ensureInitialized();

    // Use the overall skill level
    return GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);
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
      if (!_isOnline) {
        // TODO: Implement offline queue for sync when online
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
}
