import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_model.dart';
// Removed unused import: skill_level.dart
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
// Removed unused import: storage_service.dart
import 'package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service_helper.dart';

/// Enhanced service for generating AI-driven hints and solution analysis
///
/// This service provides contextual hints and solution analysis for challenges
/// based on the user's current progress and skill level.
/// Enhancements include:
/// - Improved AI-driven hint generation based on user's current progress
/// - More sophisticated solution analysis
/// - Enhanced cultural context integration in hints
/// - Better fallback mechanisms for offline use
class EnhancedStoryMentorService {
  /// Gemini instance for API interactions
  late final gemini.Gemini _gemini;

  // Removed unused _storageService field

  /// Cultural data service for integrating cultural context
  final CulturalDataService _culturalDataService;

  /// Flag indicating if the device is online (determined by API response)
  bool _isOnline = true;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Cache for hints to reduce API calls
  final Map<String, String> _hintCache = {};

  /// Cache for solution analysis to reduce API calls
  final Map<String, Map<String, dynamic>> _analysisCache = {};

  /// Create a new EnhancedStoryMentorService with optional dependencies
  EnhancedStoryMentorService({
    CulturalDataService? culturalDataService,
  }) :
    _culturalDataService = culturalDataService ?? CulturalDataService();

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
      debugPrint('EnhancedStoryMentorService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize EnhancedStoryMentorService: $e');
      throw Exception('Failed to initialize EnhancedStoryMentorService: $e');
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
      final response = await _gemini.text("Hello");
      // Note: text() is deprecated but we're using it for compatibility

      _isOnline = response != null;
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      return false;
    }
  }

  /// Generate a hint for the current challenge based on user progress
  ///
  /// Parameters:
  /// - `challengeId`: ID of the current challenge
  /// - `challengeDescription`: Description of the challenge
  /// - `userProgress`: User's current progress
  /// - `currentBlocks`: Current blocks in the workspace
  /// - `requiredBlockTypes`: Block types required for the challenge
  /// - `hintLevel`: Level of hint to provide (1-3, with 3 being most detailed)
  ///
  /// Returns a hint string with cultural context integrated
  Future<String> generateHint({
    required String challengeId,
    required String challengeDescription,
    required UserProgress userProgress,
    required List<BlockModel> currentBlocks,
    required List<String> requiredBlockTypes,
    int hintLevel = 1,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the hint
    final cacheKey = 'hint_${challengeId}_${hintLevel}_${currentBlocks.length}';

    // Check if hint is cached
    if (_hintCache.containsKey(cacheKey)) {
      return _hintCache[cacheKey]!;
    }

    // If offline, return a default hint
    if (!_isOnline) {
      return _getDefaultHint(
        challengeDescription: challengeDescription,
        requiredBlockTypes: requiredBlockTypes,
        hintLevel: hintLevel,
      );
    }

    // Get cultural context for the hint
    final culturalContext = await _culturalDataService.getRandomCulturalInfo();

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a description of the current blocks
    final blocksDescription = currentBlocks.isEmpty
        ? "No blocks have been placed yet."
        : "Current blocks: ${currentBlocks.map((b) => b.type.name).join(', ')}";

    // Create a prompt for generating the hint
    final prompt = "You are a helpful mentor teaching a child about coding concepts through Kente weaving patterns from Ghana. "
        "Challenge: $challengeDescription. "
        "Required block types: ${requiredBlockTypes.join(', ')}. "
        "$blocksDescription. "
        "User's skill level: ${skillLevel == 1 ? 'Beginner' : skillLevel == 3 ? 'Intermediate' : 'Advanced'}. "
        "Hint level: $hintLevel (1 = subtle hint, 2 = moderate guidance, 3 = detailed explanation). "
        "Cultural context to incorporate: ${culturalContext['description'] ?? 'Kente weaving is a traditional craft in Ghana that uses patterns to tell stories.'}. "
        "Please provide a hint that is encouraging, incorporates cultural context, and provides appropriate guidance based on the hint level.";

    try {
      // Generate the hint using Gemini
      final response = await _gemini.text(prompt);
      // Note: text() is deprecated but we're using it for compatibility

      // Get the response text
      final hint = response?.toString() ?? '';

      // If the hint is empty, return a default hint
      if (hint.isEmpty) {
        return _getDefaultHint(
          challengeDescription: challengeDescription,
          requiredBlockTypes: requiredBlockTypes,
          hintLevel: hintLevel,
        );
      }

      // Cache the hint
      _hintCache[cacheKey] = hint;

      return hint;
    } catch (e) {
      debugPrint('Error generating hint: $e');

      // Return a default hint if there's an error
      return _getDefaultHint(
        challengeDescription: challengeDescription,
        requiredBlockTypes: requiredBlockTypes,
        hintLevel: hintLevel,
      );
    }
  }

  /// Analyze a user's solution to a challenge
  ///
  /// Parameters:
  /// - `challengeId`: ID of the challenge
  /// - `challengeDescription`: Description of the challenge
  /// - `userSolution`: User's solution as a pattern
  /// - `requiredBlockTypes`: Block types required for the challenge
  /// - `userProgress`: User's current progress
  ///
  /// Returns an analysis of the solution with feedback and suggestions
  Future<Map<String, dynamic>> analyzeSolution({
    required String challengeId,
    required String challengeDescription,
    required PatternModel userSolution,
    required List<String> requiredBlockTypes,
    required UserProgress userProgress,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the analysis
    final cacheKey = 'analysis_${challengeId}_${userSolution.id}';

    // Check if analysis is cached
    if (_analysisCache.containsKey(cacheKey)) {
      return _analysisCache[cacheKey]!;
    }

    // If offline, return a basic analysis
    if (!_isOnline) {
      return _getDefaultAnalysis(
        challengeDescription: challengeDescription,
        userSolution: userSolution,
        requiredBlockTypes: requiredBlockTypes,
      );
    }

    // Get cultural context for the analysis
    final culturalContext = await _culturalDataService.getRandomCulturalInfo();

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a description of the user's solution
    final solutionDescription = "User's solution contains these blocks: ${getBlockTypes(userSolution).join(', ')}";

    // Check if all required block types are used
    final usedBlockTypes = getBlockTypes(userSolution).toSet();
    final missingBlockTypes = requiredBlockTypes.where((type) => !usedBlockTypes.contains(type)).toList();
    final allRequiredBlocksUsed = missingBlockTypes.isEmpty;

    // Create a prompt for analyzing the solution
    final prompt = "You are an expert in coding education analyzing a child's solution to a coding challenge based on Kente weaving patterns from Ghana. "
        "Challenge: $challengeDescription. "
        "Required block types: ${requiredBlockTypes.join(', ')}. "
        "$solutionDescription. "
        "${missingBlockTypes.isNotEmpty ? 'Missing block types: ${missingBlockTypes.join(', ')}' : 'All required block types are used.'}. "
        "User's skill level: ${skillLevel == 1 ? 'Beginner' : skillLevel == 3 ? 'Intermediate' : 'Advanced'}. "
        "Cultural context to incorporate: ${culturalContext['description'] ?? 'Kente weaving is a traditional craft in Ghana that uses patterns to tell stories.'}. "
        "Please analyze the solution and provide feedback in JSON format with success, strengths, improvements, cultural connection, next step suggestion, and overall feedback.";

    try {
      // Generate the analysis using Gemini
      final response = await _gemini.text(prompt);
      // Note: text() is deprecated but we're using it for compatibility

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default analysis
      if (responseText.isEmpty) {
        return _getDefaultAnalysis(
          challengeDescription: challengeDescription,
          userSolution: userSolution,
          requiredBlockTypes: requiredBlockTypes,
        );
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final analysis = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Ensure all required fields are present
        final defaultAnalysis = _getDefaultAnalysis(
          challengeDescription: challengeDescription,
          userSolution: userSolution,
          requiredBlockTypes: requiredBlockTypes,
        );

        final result = {
          "success": analysis["success"] ?? defaultAnalysis["success"],
          "strengths": analysis["strengths"] ?? defaultAnalysis["strengths"],
          "improvements": analysis["improvements"] ?? defaultAnalysis["improvements"],
          "culturalConnection": analysis["culturalConnection"] ?? defaultAnalysis["culturalConnection"],
          "nextStepSuggestion": analysis["nextStepSuggestion"] ?? defaultAnalysis["nextStepSuggestion"],
          "overallFeedback": analysis["overallFeedback"] ?? defaultAnalysis["overallFeedback"],
        };

        // Cache the analysis
        _analysisCache[cacheKey] = result;

        return result;
      } catch (e) {
        debugPrint('Error parsing analysis JSON: $e');

        // If we can't parse the JSON, create a simple analysis from the text
        final simpleAnalysis = {
          "success": allRequiredBlocksUsed,
          "strengths": ["You've created a solution to the challenge"],
          "improvements": allRequiredBlocksUsed
              ? ["Try making your solution more efficient"]
              : ["Make sure to use all the required block types: ${requiredBlockTypes.join(', ')}"],
          "culturalConnection": "In Kente weaving, each pattern tells a story, just as your code creates a meaningful pattern.",
          "nextStepSuggestion": "Try adding more complexity to your pattern by using different combinations of blocks.",
          "overallFeedback": responseText.length > 100 ? responseText.substring(0, 100) : responseText,
        };

        // Cache the analysis
        _analysisCache[cacheKey] = simpleAnalysis;

        return simpleAnalysis;
      }
    } catch (e) {
      debugPrint('Error analyzing solution: $e');

      // Return a default analysis if there's an error
      return _getDefaultAnalysis(
        challengeDescription: challengeDescription,
        userSolution: userSolution,
        requiredBlockTypes: requiredBlockTypes,
      );
    }
  }

  /// Get a default hint when offline or when API fails
  String _getDefaultHint({
    required String challengeDescription,
    required List<String> requiredBlockTypes,
    required int hintLevel,
  }) {
    if (hintLevel == 1) {
      return "Think about how you might use ${requiredBlockTypes.first} blocks to solve this challenge. In Kente weaving, each pattern has a specific meaning and purpose.";
    } else if (hintLevel == 2) {
      return "Try combining ${requiredBlockTypes.join(' and ')} blocks to create a pattern that solves the challenge. Kente weavers plan their patterns carefully before they begin, just like good coders plan their solutions.";
    } else {
      return "For this challenge, you'll need to use ${requiredBlockTypes.join(', ')} blocks in a specific order. Start by placing a ${requiredBlockTypes.first} block, then build from there. In Kente tradition, master weavers teach their apprentices step by step, just as you're learning coding step by step.";
    }
  }

  /// Get a default analysis when offline or when API fails
  Map<String, dynamic> _getDefaultAnalysis({
    required String challengeDescription,
    required PatternModel userSolution,
    required List<String> requiredBlockTypes,
  }) {
    // Check if all required block types are used
    final usedBlockTypes = getBlockTypes(userSolution).toSet();
    final allRequiredBlocksUsed = requiredBlockTypes.every((type) => usedBlockTypes.contains(type));

    return {
      "success": allRequiredBlocksUsed,
      "strengths": [
        "You've created a solution to the challenge",
        "Your pattern shows creativity"
      ],
      "improvements": allRequiredBlocksUsed
          ? ["Try making your solution more efficient"]
          : ["Make sure to use all the required block types: ${requiredBlockTypes.join(', ')}"],
      "culturalConnection": "In Kente weaving, each pattern tells a story, just as your code creates a meaningful pattern.",
      "nextStepSuggestion": "Try adding more complexity to your pattern by using different combinations of blocks.",
      "overallFeedback": allRequiredBlocksUsed
          ? "Great job completing the challenge! Your solution shows good understanding of the concepts."
          : "You're on the right track! Keep working on your solution to include all the required elements."
    };
  }

  /// Helper method to get block types from a pattern model
  List<String> getBlockTypes(PatternModel pattern) {
    // This is a simplified implementation since we don't know the exact structure of PatternModel
    // In a real implementation, you would access the blocks property and map to block types
    return pattern.blocks.map((block) => block.type.name).toList();
  }
}

