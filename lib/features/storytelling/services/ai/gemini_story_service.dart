import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/core/services/gemini_service.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/storytelling/models/tts_settings.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/prompt_template_manager.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/content_validator.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/story_cache_service.dart';

/// Helper class for extracting JSON from text and other utility functions
class GeminiStoryServiceHelper {
  /// Extract JSON from text that may contain additional content
  static String extractJsonFromText(String text) {
    // Look for JSON-like content (starting with { and ending with })
    final jsonRegex = RegExp(r'(\{.*\})', dotAll: true);
    final match = jsonRegex.firstMatch(text);

    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }

    // If no JSON object found, look for JSON array
    final jsonArrayRegex = RegExp(r'(\[.*\])', dotAll: true);
    final arrayMatch = jsonArrayRegex.firstMatch(text);

    if (arrayMatch != null && arrayMatch.group(1) != null) {
      return arrayMatch.group(1)!;
    }

    // If no JSON found, return the original text
    return text;
  }

  /// Get difficulty level from user progress
  static int getDifficultyFromUserProgress(UserProgress userProgress) {
    // Calculate difficulty based on mastered concepts
    final masteredCount = userProgress.conceptsMastered.length;

    if (masteredCount < 3) {
      return 1; // Beginner
    } else if (masteredCount < 7) {
      return 2; // Basic
    } else if (masteredCount < 12) {
      return 3; // Intermediate
    } else if (masteredCount < 18) {
      return 4; // Advanced
    } else {
      return 5; // Expert
    }
  }

  /// Get difficulty level (1-5) from skill level
  static int getDifficultyFromSkillLevel(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 1;
      case SkillLevel.intermediate:
        return 3;
      case SkillLevel.advanced:
        return 5;
      default:
        return 1;
    }
  }

  /// Validate a story response
  static bool validateStoryResponse(String responseText, List<String> requiredFields) {
    try {
      final jsonStr = extractJsonFromText(responseText);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Check for required fields
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null || data[field].toString().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error validating story response: $e');
      return false;
    }
  }
}

/// Service for AI-driven storytelling
///
/// This service provides AI-generated stories with branching narratives,
/// adaptive difficulty, and cultural context integration.
/// Features include:
/// - Enhanced AI prompt engineering for more engaging narratives
/// - Support for generating story branches based on user choices
/// - Better error handling for offline scenarios
/// - Caching mechanisms for generated content
/// - Removal of age-based references in story generation
/// - Content validation for quality control
/// - FIFO caching for efficient memory usage
class GeminiStoryService {
  /// Gemini service for API interactions
  final GeminiService _geminiService = GeminiService();

  /// Storage service for caching stories
  final StorageService _storageService;

  /// Cultural data service for integrating cultural context
  final EnhancedCulturalDataService _culturalDataService;

  /// Cache service for AI-generated stories
  final StoryCacheService _cacheService;

  /// Random number generator for variety in stories
  final Random _random = Random();

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new GeminiStoryService with optional dependencies
  GeminiStoryService({
    StorageService? storageService,
    EnhancedCulturalDataService? culturalDataService,
    StoryCacheService? cacheService,
  }) :
    _storageService = storageService ?? StorageService(),
    _culturalDataService = culturalDataService ?? EnhancedCulturalDataService(),
    _cacheService = cacheService ?? StoryCacheService();

  /// Initializes the service and its dependencies
  ///
  /// Uses the shared GeminiService for Gemini API access
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the Gemini service
      await _geminiService.initialize();

      // Initialize cultural data service
      await _culturalDataService.initialize();

      _isInitialized = true;
      debugPrint('GeminiStoryService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize GeminiStoryService: $e');
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

  /// Set offline mode (for testing)
  /// This is a no-op now as we use the shared GeminiService
  void setOfflineMode(bool offline) {
    // No longer directly controls online state
    // Would need to modify GeminiService if this functionality is needed
  }

  /// Generate a story based on user progress and learning concepts
  ///
  /// Parameters:
  /// - `userProgress`: User's current progress
  /// - `learningConcepts`: Concepts to focus on in the story
  /// - `culturalContext`: Optional cultural context to include
  /// - `emotionalTone`: Optional emotional tone for the story
  ///
  /// Returns a StoryModel with the generated story
  Future<StoryModel> generateStory({
    required UserProgress userProgress,
    required List<String> learningConcepts,
    String? culturalContext,
    EmotionalTone emotionalTone = EmotionalTone.neutral,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the story
    final cacheKey = 'story_${userProgress.userId}_${learningConcepts.join('_')}_${emotionalTone.name}';

    // Check if story is cached
    final cachedStory = await _cacheService.getCachedStory(cacheKey);
    if (cachedStory != null) {
      debugPrint('Using cached story for key: $cacheKey');
      return cachedStory;
    }

    // If offline, return a default story
    if (!_geminiService.isOnline) {
      debugPrint('Device is offline, using default story');
      return _getDefaultStory(
        learningConcepts: learningConcepts,
        emotionalTone: emotionalTone,
      );
    }

    // Get cultural context if not provided
    final culturalInfo = culturalContext != null
        ? {'description': culturalContext}
        : await _culturalDataService.getRandomCulturalInfo();

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Get previous stories for continuity
    final previousStories = await _getPreviousStories(userProgress.userId);

    // Create a prompt for generating the story using the template manager
    final prompt = PromptTemplateManager.createStoryPrompt(
      learningConcepts: learningConcepts,
      skillLevel: skillLevel,
      culturalContext: culturalInfo['description'] ?? '',
      emotionalTone: emotionalTone,
      previousStories: previousStories,
    );

    try {
      // Generate the story using Gemini
      debugPrint('Generating story with Gemini AI...');
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default story
      if (responseText.isEmpty) {
        debugPrint('Empty response from Gemini, using default story');
        return _getDefaultStory(
          learningConcepts: learningConcepts,
          emotionalTone: emotionalTone,
        );
      }

      // Validate the response
      final validationResult = ContentValidator.validateStoryResponse(
        responseText: responseText,
        requiredFields: ['title', 'content'],
        learningConcepts: learningConcepts,
      );

      if (validationResult.isValid && validationResult.extractedJson != null) {
        // Create a StoryModel from the validated response
        final storyData = validationResult.extractedJson as Map<String, dynamic>;

        // Extract cultural notes if available
        Map<String, String> culturalNotes = {'context': culturalInfo['description'] ?? ''};
        if (storyData['culturalNotes'] != null && storyData['culturalNotes'] is Map) {
          final notes = storyData['culturalNotes'] as Map;
          notes.forEach((key, value) {
            culturalNotes[key.toString()] = value.toString();
          });
        }

        // Create the story model
        final story = StoryModel(
          id: 'story_${DateTime.now().millisecondsSinceEpoch}',
          title: storyData['title'] ?? 'Untitled Story',
          theme: storyData['theme'] ?? 'cultural',
          region: storyData['region'] ?? 'Ghana',
          characterName: storyData['characterName'] ?? 'Kofi',
          ageGroup: storyData['ageGroup'] ?? '7-12',
          content: _createContentBlocksFromText(storyData['content'] ?? responseText),
          learningConcepts: learningConcepts,
          emotionalTone: emotionalTone,
          culturalNotes: culturalNotes,
        );

        // Cache the story
        await _cacheService.cacheStory(cacheKey, story);

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        debugPrint('Successfully generated and cached story: ${story.title}');
        return story;
      } else {
        // If validation failed, log the errors and create a simple story from the text
        debugPrint('Validation failed: ${validationResult.errors.join(', ')}');

        final story = StoryModel(
          id: 'story_${DateTime.now().millisecondsSinceEpoch}',
          title: 'A Kente Weaving Adventure',
          theme: 'cultural',
          region: 'Ghana',
          characterName: 'Kofi',
          ageGroup: '7-12',
          content: _createContentBlocksFromText(responseText),
          learningConcepts: learningConcepts,
          emotionalTone: emotionalTone,
          culturalNotes: {'context': culturalInfo['description'] ?? ''},
        );

        // Cache the story
        await _cacheService.cacheStory(cacheKey, story);

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        return story;
      }
    } catch (e) {
      debugPrint('Error generating story: $e');

      // Return a default story if there's an error
      return _getDefaultStory(
        learningConcepts: learningConcepts,
        emotionalTone: emotionalTone,
      );
    }
  }

  /// Generate an enhanced story with continuity and cultural context
  ///
  /// This version of story generation focuses on creating a more personalized and contextual
  /// story experience, with better narrative continuity and cultural connections.
  Future<StoryModel> generateEnhancedStory({
    required SkillLevel skillLevel,
    required String theme,
    String? characterName,
    String? previousStoryId,
    String? narrativeType,
    Map<String, dynamic>? narrativeContext,
    List<String>? conceptsToTeach,
    UserProgress? userProgress,
  }) async {
    await _ensureInitialized();

    // Convert skill level to learning concepts
    final List<String> learningConcepts = conceptsToTeach ?? _getLearningConceptsForSkillLevel(skillLevel);

    // Create a default user progress if not provided
    final UserProgress progress = userProgress ?? UserProgress(
      userId: 'default_user',
      name: 'Learner',
      level: 1,
      conceptsMastered: conceptsToTeach ?? [],
      conceptsInProgress: [],
    );

    // Create a cache key for the enhanced story
    final cacheKey = 'enhanced_story_${theme}_${skillLevel.toString().split('.').last}_${characterName ?? 'default'}';

    // Check if story is cached
    final cachedStory = await _cacheService.getCachedStory(cacheKey);
    if (cachedStory != null) {
      debugPrint('Using cached enhanced story for key: $cacheKey');
      return cachedStory;
    }

    // If offline, return a default story
    if (!_geminiService.isOnline) {
      debugPrint('Device is offline, using default enhanced story');
      return _getDefaultStory(
        learningConcepts: learningConcepts,
        emotionalTone: EmotionalTone.excited,
      );
    }

    // Get cultural context
    final culturalInfo = await _culturalDataService.getRandomCulturalInfo();

    // Get previous stories for continuity
    final previousStories = await _getPreviousStories(progress.userId);

    // Create a prompt for generating the enhanced story using the template manager
    final prompt = PromptTemplateManager.createEnhancedStoryPrompt(
      learningConcepts: learningConcepts,
      skillLevel: GeminiStoryServiceHelper.getDifficultyFromSkillLevel(skillLevel),
      culturalContext: culturalInfo['description'] ?? '',
      emotionalTone: EmotionalTone.excited,
      previousStories: previousStories,
      characterName: characterName,
      narrativeContext: narrativeContext,
      theme: theme,
    );

    try {
      // Generate the story using Gemini
      debugPrint('Generating enhanced story with Gemini AI...');
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default story
      if (responseText.isEmpty) {
        debugPrint('Empty response from Gemini, using default enhanced story');
        return _getDefaultStory(
          learningConcepts: learningConcepts,
          emotionalTone: EmotionalTone.excited,
        );
      }

      // Validate the response
      final validationResult = ContentValidator.validateStoryResponse(
        responseText: responseText,
        requiredFields: ['title', 'content', 'theme', 'characterName'],
        learningConcepts: learningConcepts,
      );

      if (validationResult.isValid && validationResult.extractedJson != null) {
        // Create a StoryModel from the validated response
        final storyData = validationResult.extractedJson as Map<String, dynamic>;

        // Extract cultural notes if available
        Map<String, String> culturalNotes = {'context': culturalInfo['description'] ?? ''};
        if (storyData['culturalNotes'] != null && storyData['culturalNotes'] is Map) {
          final notes = storyData['culturalNotes'] as Map;
          notes.forEach((key, value) {
            culturalNotes[key.toString()] = value.toString();
          });
        }

        // Create challenge if available
        StoryChallenge? challenge;
        if (storyData['challenge'] != null && storyData['challenge'] is Map<String, dynamic>) {
          final challengeData = storyData['challenge'] as Map<String, dynamic>;
          challenge = StoryChallenge(
            id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
            title: challengeData['title'] ?? 'Coding Challenge',
            description: challengeData['description'] ?? 'Complete the pattern',
            successCriteria: challengeData['successCriteria'] ?? {},
            difficulty: challengeData['difficulty'] ?? GeminiStoryServiceHelper.getDifficultyFromSkillLevel(skillLevel),
            availableBlockTypes: challengeData['availableBlockTypes'] != null
                ? List<String>.from(challengeData['availableBlockTypes'])
                : ['move', 'turn', 'repeat'],
            contentStartIndex: 0,
            contentEndIndex: 0,
          );
        }

        // Create the story model
        final story = StoryModel(
          id: 'enhanced_story_${DateTime.now().millisecondsSinceEpoch}',
          title: storyData['title'] ?? 'Untitled Story',
          theme: storyData['theme'] ?? theme,
          region: storyData['region'] ?? 'Ghana',
          characterName: storyData['characterName'] ?? characterName ?? 'Kofi',
          ageGroup: '7-15',
          content: _createContentBlocksFromText(storyData['content'] ?? responseText),
          learningConcepts: learningConcepts,
          emotionalTone: EmotionalTone.excited,
          culturalNotes: culturalNotes,
          challenge: challenge,
          difficultyLevel: GeminiStoryServiceHelper.getDifficultyFromSkillLevel(skillLevel),
        );

        // Cache the story
        await _cacheService.cacheStory(cacheKey, story);

        // Save the story to storage for continuity
        await _saveStory(progress.userId, story);

        debugPrint('Successfully generated and cached enhanced story: ${story.title}');
        return story;
      } else {
        // If validation failed, log the errors and fall back to regular story generation
        debugPrint('Enhanced story validation failed: ${validationResult.errors.join(', ')}');
        return generateStory(
          learningConcepts: learningConcepts,
          emotionalTone: EmotionalTone.excited,
          userProgress: progress,
        );
      }
    } catch (e) {
      debugPrint('Error generating enhanced story: $e');

      // Fall back to regular story generation
      return generateStory(
        learningConcepts: learningConcepts,
        emotionalTone: EmotionalTone.excited,
        userProgress: progress,
      );
    }
  }

  /// Get learning concepts based on skill level
  List<String> _getLearningConceptsForSkillLevel(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return ['sequences', 'loops'];
      case SkillLevel.intermediate:
        return ['loops', 'conditionals', 'variables'];
      case SkillLevel.advanced:
        return ['conditionals', 'functions', 'algorithms'];
      default:
        return ['sequences', 'loops', 'conditionals'];
    }
  }

  /// Generate story branches based on a parent story and user choices
  ///
  /// Parameters:
  /// - `parentStory`: The parent story to branch from
  /// - `userProgress`: User's current progress
  /// - `choiceCount`: Number of choices to generate
  ///
  /// Returns a list of StoryBranchModel with the generated branches
  Future<List<StoryBranchModel>> generateStoryBranches({
    required StoryModel parentStory,
    required UserProgress userProgress,
    int choiceCount = 2,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the branches
    final cacheKey = 'branches_${parentStory.id}_$choiceCount';

    // Check if branches are cached
    final cachedBranches = await _cacheService.getCachedBranches(cacheKey);
    if (cachedBranches != null) {
      debugPrint('Using cached branches for key: $cacheKey');
      return cachedBranches;
    }

    // If offline, return default branches
    if (!_geminiService.isOnline) {
      debugPrint('Device is offline, using default branches');
      return _getDefaultBranches(
        parentStory: parentStory,
        choiceCount: choiceCount,
      );
    }

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a prompt for generating the branches using the template manager
    final prompt = PromptTemplateManager.createBranchPrompt(
      parentStory: parentStory,
      skillLevel: skillLevel,
      choiceCount: choiceCount,
    );

    try {
      // Generate the branches using Gemini
      debugPrint('Generating story branches with Gemini AI...');
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return default branches
      if (responseText.isEmpty) {
        debugPrint('Empty response from Gemini, using default branches');
        return _getDefaultBranches(
          parentStory: parentStory,
          choiceCount: choiceCount,
        );
      }

      // Validate the response
      final validationResult = ContentValidator.validateBranchesResponse(
        responseText: responseText,
        requiredFields: ['choiceText', 'content'],
        expectedCount: choiceCount,
      );

      if (validationResult.isValid && validationResult.extractedJson != null) {
        // Create StoryBranchModel list from the validated response
        final branchesData = validationResult.extractedJson as List<dynamic>;

        final branches = branchesData.map((branchData) {
          // Extract focus concept if available
          final focusConcept = branchData['focusConcept'] as String? ??
              (parentStory.learningConcepts.isNotEmpty ? parentStory.learningConcepts.first : null);

          // Create the branch model
          return StoryBranchModel(
            id: 'branch_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
            description: branchData['description'] ?? 'Story continuation',
            targetStoryId: 'target_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
            parentStoryId: parentStory.id,
            choiceText: branchData['choiceText'] ?? 'Continue the story',
            content: branchData['content'] ?? 'The story continues...',
            learningConcepts: parentStory.learningConcepts,
            emotionalTone: _parseEmotionalTone(branchData['emotionalTone']),
            focusConcept: focusConcept,
            hasChoices: branchData['hasChoices'] as bool? ?? false,
            choicePrompt: branchData['choicePrompt'] as String?,
          );
        }).toList();

        // Cache the branches
        await _cacheService.cacheBranches(cacheKey, branches);

        debugPrint('Successfully generated and cached ${branches.length} story branches');
        return branches;
      } else {
        // If validation failed, log the errors and return default branches
        debugPrint('Branch validation failed: ${validationResult.errors.join(', ')}');
        return _getDefaultBranches(
          parentStory: parentStory,
          choiceCount: choiceCount,
        );
      }
    } catch (e) {
      debugPrint('Error generating branches: $e');

      // Return default branches if there's an error
      return _getDefaultBranches(
        parentStory: parentStory,
        choiceCount: choiceCount,
      );
    }
  }

  /// Continue a story based on a selected branch
  ///
  /// Parameters:
  /// - `selectedBranch`: The branch to continue from
  /// - `userProgress`: User's current progress
  ///
  /// Returns a StoryModel with the continued story
  Future<StoryModel> continueStoryFromBranch({
    required StoryBranchModel selectedBranch,
    required UserProgress userProgress,
  }) async {
    await _ensureInitialized();

    // Create a cache key for the continued story
    final cacheKey = 'continue_${selectedBranch.id}';

    // Check if continued story is cached
    final cachedStory = await _cacheService.getCachedStory(cacheKey);
    if (cachedStory != null) {
      debugPrint('Using cached continuation for key: $cacheKey');
      return cachedStory;
    }

    // If offline, return a default continuation
    if (!_geminiService.isOnline) {
      debugPrint('Device is offline, using default continuation');
      return _getDefaultContinuation(
        selectedBranch: selectedBranch,
      );
    }

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a prompt for continuing the story using the template manager
    final prompt = PromptTemplateManager.createContinuationPrompt(
      selectedBranch: selectedBranch,
      skillLevel: skillLevel,
    );

    try {
      // Generate the continuation using Gemini
      debugPrint('Generating story continuation with Gemini AI...');
      final response = await _geminiService.instance.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default continuation
      if (responseText.isEmpty) {
        debugPrint('Empty response from Gemini, using default continuation');
        return _getDefaultContinuation(
          selectedBranch: selectedBranch,
        );
      }

      // Validate the response
      final validationResult = ContentValidator.validateContinuationResponse(
        responseText: responseText,
        requiredFields: ['title', 'content'],
        learningConcepts: selectedBranch.learningConcepts,
      );

      if (validationResult.isValid && validationResult.extractedJson != null) {
        // Create a StoryModel from the validated response
        final storyData = validationResult.extractedJson as Map<String, dynamic>;

        // Extract cultural notes if available
        Map<String, String> culturalNotes = {};
        if (storyData['culturalNotes'] != null && storyData['culturalNotes'] is Map) {
          final notes = storyData['culturalNotes'] as Map;
          notes.forEach((key, value) {
            culturalNotes[key.toString()] = value.toString();
          });
        }

        // Create challenge if available
        StoryChallenge? challenge;
        if (storyData['challenge'] != null && storyData['challenge'] is Map<String, dynamic>) {
          final challengeData = storyData['challenge'] as Map<String, dynamic>;
          challenge = StoryChallenge(
            id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
            title: challengeData['title'] ?? 'Coding Challenge',
            description: challengeData['description'] ?? 'Complete the pattern',
            successCriteria: challengeData['successCriteria'] ?? {},
            difficulty: challengeData['difficulty'] ?? skillLevel,
            availableBlockTypes: challengeData['availableBlockTypes'] != null
                ? List<String>.from(challengeData['availableBlockTypes'])
                : ['move', 'turn', 'repeat'],
            contentStartIndex: 0,
            contentEndIndex: 0,
          );
        }

        // Create the story model
        final story = StoryModel(
          id: 'continuation_${DateTime.now().millisecondsSinceEpoch}',
          title: storyData['title'] ?? 'Continued Story',
          theme: storyData['theme'] ?? 'general',
          region: storyData['region'] ?? 'Ghana',
          characterName: storyData['characterName'] ?? 'Kwame',
          ageGroup: '7-15',
          content: _createContentBlocksFromText('${selectedBranch.content}\n\n${storyData['content'] ?? responseText}'),
          learningConcepts: selectedBranch.learningConcepts,
          emotionalTone: selectedBranch.emotionalTone,
          culturalNotes: culturalNotes,
          challenge: challenge,
        );

        // Cache the story
        await _cacheService.cacheStory(cacheKey, story);

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        debugPrint('Successfully generated and cached story continuation: ${story.title}');
        return story;
      } else {
        // If validation failed, log the errors and create a simple continuation from the text
        debugPrint('Continuation validation failed: ${validationResult.errors.join(', ')}');

        final story = StoryModel(
          id: 'continuation_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Continued Adventure',
          theme: 'general',
          region: 'Ghana',
          characterName: 'Kwame',
          ageGroup: '7-15',
          content: _createContentBlocksFromText('${selectedBranch.content}\n\n$responseText'),
          learningConcepts: selectedBranch.learningConcepts,
          emotionalTone: selectedBranch.emotionalTone,
          culturalNotes: {},
        );

        // Cache the story
        await _cacheService.cacheStory(cacheKey, story);

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        return story;
      }
    } catch (e) {
      debugPrint('Error continuing story: $e');

      // Return a default continuation if there's an error
      return _getDefaultContinuation(
        selectedBranch: selectedBranch,
      );
    }
  }



  /// Get a default story when offline or when API fails
  StoryModel _getDefaultStory({
    required List<String> learningConcepts,
    required EmotionalTone emotionalTone,
  }) {
    final conceptText = learningConcepts.join(', ');
    final storyText = """
In a small village in Ghana, a young weaver named Kofi was learning the art of Kente weaving from his mentor, Master Anansi. Kofi was eager to learn about $conceptText through weaving.

"To create beautiful patterns," Master Anansi explained, "you must understand how to repeat steps in a specific order, just like in coding."

Kofi practiced diligently, creating simple patterns at first. He learned that each thread placement was like a line of code, and the repeated patterns were like loops in programming.

As he improved, Master Anansi taught him more complex techniques. "Now you're ready to learn about conditions," the master said. "Sometimes we change the pattern based on what came before, just like an 'if' statement in coding."

Kofi's final challenge was to create a Kente cloth that told a story through its patterns. He carefully planned his design, thinking about the sequence of steps, the repeated patterns, and the conditional changes.

When he finished, Master Anansi smiled proudly. "You have not only learned to weave Kente, but you have also learned the fundamental concepts of coding. The patterns you create with thread are not so different from the programs you can create with code."

Kofi looked at his creation with new understanding. The beautiful Kente cloth represented both his cultural heritage and his first steps into the world of programming.
""";

    return StoryModel(
      id: 'default_story_${DateTime.now().millisecondsSinceEpoch}',
      title: 'The Kente Weaver\'s Journey',
      theme: 'cultural',
      region: 'Ghana',
      characterName: 'Kofi',
      ageGroup: '7-12',
      content: _createContentBlocksFromText(storyText),
      learningConcepts: learningConcepts,
      emotionalTone: emotionalTone,
      culturalNotes: {'weaving': 'Kente weaving in Ghana is a traditional craft with deep cultural significance.'},
    );
  }

  /// Get default story branches when offline or when API fails
  List<StoryBranchModel> _getDefaultBranches({
    required StoryModel parentStory,
    required int choiceCount,
  }) {
    final branches = <StoryBranchModel>[];

    // Add first branch
    branches.add(StoryBranchModel(
      id: 'default_branch_1_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Learning advanced patterns',
      targetStoryId: 'target_branch_1_${DateTime.now().millisecondsSinceEpoch}',
      parentStoryId: parentStory.id,
      choiceText: 'Learn more advanced patterns',
      content: 'You decide to ask Master Anansi to teach you more advanced patterns that require complex sequences and loops.',
      learningConcepts: parentStory.learningConcepts,
      emotionalTone: EmotionalTone.excited,
    ));

    // Add second branch if needed
    if (choiceCount >= 2) {
      branches.add(StoryBranchModel(
        id: 'default_branch_2_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Creating your own pattern',
        targetStoryId: 'target_branch_2_${DateTime.now().millisecondsSinceEpoch}',
        parentStoryId: parentStory.id,
        choiceText: 'Create your own unique pattern',
        content: 'You decide to experiment and create your own unique pattern, applying the concepts you\'ve learned in a creative way.',
        learningConcepts: parentStory.learningConcepts,
        emotionalTone: EmotionalTone.curious,
      ));
    }

    // Add third branch if needed
    if (choiceCount >= 3) {
      branches.add(StoryBranchModel(
        id: 'default_branch_3_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Teaching another student',
        targetStoryId: 'target_branch_3_${DateTime.now().millisecondsSinceEpoch}',
        parentStoryId: parentStory.id,
        choiceText: 'Teach another student',
        content: 'You decide to share your knowledge by teaching another student the basics of pattern creation and loops.',
        learningConcepts: parentStory.learningConcepts,
        emotionalTone: EmotionalTone.happy,
      ));
    }

    return branches;
  }

  /// Get a default story continuation when offline or when API fails
  StoryModel _getDefaultContinuation({
    required StoryBranchModel selectedBranch,
  }) {
    final continuationText = """
${selectedBranch.content}

As you continue your journey, you find that the concepts you're learning apply to both Kente weaving and coding. The patterns become more complex, but the fundamental principles remain the same.

You practice creating sequences, using loops to repeat patterns, and applying conditions to create variations. Each new skill builds upon the previous ones, just like in programming.

Master Anansi watches your progress with pride. "You are connecting the ancient art of our ancestors with the modern world of technology," he says. "This is how traditions stay alive and relevant."

By the end of your training, you have created a beautiful Kente cloth that tells your unique story. But more importantly, you have gained a deep understanding of the coding concepts that will help you in your future endeavors.

The patterns of the threads mirror the patterns in code, a beautiful intersection of culture and technology.
""";

    return StoryModel(
      id: 'default_continuation_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Continuing the Journey',
      theme: 'cultural',
      region: 'Ghana',
      characterName: 'Kofi',
      ageGroup: '7-12',
      content: _createContentBlocksFromText(continuationText),
      learningConcepts: selectedBranch.learningConcepts,
      emotionalTone: selectedBranch.emotionalTone,
      culturalNotes: {'weaving': 'Kente weaving traditions are passed down through generations.'},
    );
  }

  /// Create content blocks from text
  List<ContentBlockModel> _createContentBlocksFromText(String text) {
    // Split text into paragraphs
    final paragraphs = text.split('\n\n');

    // Create a content block for each paragraph
    return paragraphs.map((paragraph) {
      // Skip empty paragraphs
      if (paragraph.trim().isEmpty) return null;

      return ContentBlockModel(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        text: paragraph.trim(),
        ttsSettings: TTSSettings(
          pitch: 1.0,
          rate: 1.0,
          volume: 1.0,
          voice: 'default',
        ),
        delay: 0,
        displayDuration: 0,
        waitForInteraction: false,
      );
    }).whereType<ContentBlockModel>().toList();
  }

  /// Parse emotional tone from string
  EmotionalTone _parseEmotionalTone(dynamic toneText) {
    if (toneText == null) return EmotionalTone.neutral;

    final tone = toneText.toString().toLowerCase();

    switch (tone) {
      case 'happy':
        return EmotionalTone.happy;
      case 'sad':
        return EmotionalTone.sad;
      case 'excited':
        return EmotionalTone.excited;
      case 'curious':
        return EmotionalTone.curious;
      case 'calm':
        return EmotionalTone.calm;
      case 'encouraging':
        return EmotionalTone.encouraging;
      case 'dramatic':
        return EmotionalTone.dramatic;
      case 'concerned':
        return EmotionalTone.concerned;
      case 'proud':
        return EmotionalTone.proud;
      case 'thoughtful':
        return EmotionalTone.thoughtful;
      case 'wise':
        return EmotionalTone.wise;
      case 'mysterious':
        return EmotionalTone.mysterious;
      case 'playful':
        return EmotionalTone.playful;
      case 'serious':
        return EmotionalTone.serious;
      case 'surprised':
        return EmotionalTone.surprised;
      case 'inspired':
        return EmotionalTone.inspired;
      case 'determined':
        return EmotionalTone.determined;
      case 'reflective':
        return EmotionalTone.reflective;
      case 'celebratory':
        return EmotionalTone.celebratory;
      default:
        return EmotionalTone.neutral;
    }
  }



  /// Get previous stories for a user
  Future<List<Map<String, dynamic>>> _getPreviousStories(String userId) async {
    try {
      final storiesJson = await _storageService.getProgress('stories_$userId');

      if (storiesJson != null && storiesJson.isNotEmpty) {
        final List<dynamic> stories = jsonDecode(storiesJson);
        return stories.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting previous stories: $e');
      return [];
    }
  }

  /// Save a story to storage
  Future<void> _saveStory(String userId, StoryModel story) async {
    try {
      // Get existing stories
      final previousStories = await _getPreviousStories(userId);

      // Add new story
      previousStories.add({
        'id': story.id,
        'title': story.title,
        'learningConcepts': story.learningConcepts,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Keep only the 10 most recent stories
      final recentStories = previousStories.length > 10
          ? previousStories.sublist(previousStories.length - 10)
          : previousStories;

      // Save to storage
      await _storageService.saveProgress('stories_$userId', jsonEncode(recentStories));
    } catch (e) {
      debugPrint('Error saving story: $e');
    }
  }
}

