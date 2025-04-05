import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/storytelling/models/tts_settings.dart';

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
class GeminiStoryService {
  /// Gemini instance for API interactions
  late final gemini.Gemini _gemini;

  /// Storage service for caching stories
  final StorageService _storageService;

  /// Cultural data service for integrating cultural context
  final EnhancedCulturalDataService _culturalDataService;

  /// Random number generator for variety in stories
  final Random _random = Random();

  /// Flag indicating if the device is online (determined by API response)
  bool _isOnline = true;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Cache for generated stories to reduce API calls
  final Map<String, StoryModel> _storyCache = {};

  /// Cache for generated story branches to reduce API calls
  final Map<String, List<StoryBranchModel>> _branchCache = {};

  /// Create a new GeminiStoryService with optional dependencies
  GeminiStoryService({
    StorageService? storageService,
    EnhancedCulturalDataService? culturalDataService,
  }) :
    _storageService = storageService ?? StorageService(),
    _culturalDataService = culturalDataService ?? EnhancedCulturalDataService();

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

      // Initialize cultural data service
      await _culturalDataService.initialize();

      // Check connectivity by making a simple API call
      await checkConnectivity();

      _isInitialized = true;
      debugPrint('GeminiStoryService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize GeminiStoryService: $e');
      throw Exception('Failed to initialize GeminiStoryService: $e');
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
    if (_storyCache.containsKey(cacheKey)) {
      return _storyCache[cacheKey]!;
    }

    // If offline, return a default story
    if (!_isOnline) {
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

    // Create a prompt for generating the story
    final prompt = _createStoryPrompt(
      learningConcepts: learningConcepts,
      skillLevel: skillLevel,
      culturalContext: culturalInfo['description'] ?? '',
      emotionalTone: emotionalTone,
      previousStories: await _getPreviousStories(userProgress.userId),
    );

    try {
      // Generate the story using Gemini
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default story
      if (responseText.isEmpty) {
        return _getDefaultStory(
          learningConcepts: learningConcepts,
          emotionalTone: emotionalTone,
        );
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final storyData = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Create a StoryModel from the response
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
          culturalNotes: {'context': culturalInfo['description'] ?? ''},
        );

        // Cache the story
        _storyCache[cacheKey] = story;

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        return story;
      } catch (e) {
        debugPrint('Error parsing story JSON: $e');

        // If we can't parse the JSON, create a simple story from the text
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
        _storyCache[cacheKey] = story;

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
    // Convert skill level to learning concepts
    final List<String> learningConcepts = conceptsToTeach ?? _getLearningConceptsForSkillLevel(skillLevel);

    // For now, just use the regular story generation with the new parameters
    return generateStory(
      learningConcepts: learningConcepts,
      emotionalTone: EmotionalTone.excited,
      userProgress: userProgress ?? UserProgress(
        userId: 'default_user',
        name: 'Learner',
        level: 1,
        conceptsMastered: conceptsToTeach ?? [],
        conceptsInProgress: [],
      ),
    );
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
    if (_branchCache.containsKey(cacheKey)) {
      return _branchCache[cacheKey]!;
    }

    // If offline, return default branches
    if (!_isOnline) {
      return _getDefaultBranches(
        parentStory: parentStory,
        choiceCount: choiceCount,
      );
    }

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a prompt for generating the branches
    final prompt = _createBranchPrompt(
      parentStory: parentStory,
      skillLevel: skillLevel,
      choiceCount: choiceCount,
    );

    try {
      // Generate the branches using Gemini
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return default branches
      if (responseText.isEmpty) {
        return _getDefaultBranches(
          parentStory: parentStory,
          choiceCount: choiceCount,
        );
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final branchesData = jsonDecode(jsonStr) as List<dynamic>;

        // Create StoryBranchModel list from the response
        final branches = branchesData.map((branchData) {
          return StoryBranchModel(
            id: 'branch_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
            description: branchData['description'] ?? 'Story continuation',
            targetStoryId: 'target_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
            parentStoryId: parentStory.id,
            choiceText: branchData['choiceText'] ?? 'Continue the story',
            content: branchData['content'] ?? 'The story continues...',
            learningConcepts: parentStory.learningConcepts,
            emotionalTone: _parseEmotionalTone(branchData['emotionalTone']),
          );
        }).toList();

        // Cache the branches
        _branchCache[cacheKey] = branches;

        return branches;
      } catch (e) {
        debugPrint('Error parsing branches JSON: $e');
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
    if (_storyCache.containsKey(cacheKey)) {
      return _storyCache[cacheKey]!;
    }

    // If offline, return a default continuation
    if (!_isOnline) {
      return _getDefaultContinuation(
        selectedBranch: selectedBranch,
      );
    }

    // Get skill level from user progress
    final skillLevel = GeminiStoryServiceHelper.getDifficultyFromUserProgress(userProgress);

    // Create a prompt for continuing the story
    final prompt = _createContinuationPrompt(
      selectedBranch: selectedBranch,
      skillLevel: skillLevel,
    );

    try {
      // Generate the continuation using Gemini
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);

      // Get the response text
      final responseText = response?.toString() ?? '';

      // If the response is empty, return a default continuation
      if (responseText.isEmpty) {
        return _getDefaultContinuation(
          selectedBranch: selectedBranch,
        );
      }

      // Try to extract JSON from the response
      try {
        final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
        final storyData = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Create a StoryModel from the response
        final story = StoryModel(
          id: 'story_${DateTime.now().millisecondsSinceEpoch}',
          title: storyData['title'] ?? 'Continued Story',
          theme: storyData['theme'] ?? 'general',
          region: storyData['region'] ?? 'Ghana',
          characterName: storyData['characterName'] ?? 'Kwame',
          ageGroup: storyData['ageGroup'] ?? '7-12',
          content: _createContentBlocksFromText('${selectedBranch.content}\n\n${storyData['content'] ?? responseText}'),
          learningConcepts: selectedBranch.learningConcepts,
          emotionalTone: selectedBranch.emotionalTone,
          culturalNotes: storyData['culturalNotes'] != null ?
            Map<String, String>.from(storyData['culturalNotes']) :
            {},
        );

        // Cache the story
        _storyCache[cacheKey] = story;

        // Save the story to storage for continuity
        await _saveStory(userProgress.userId, story);

        return story;
      } catch (e) {
        debugPrint('Error parsing continuation JSON: $e');

        // If we can't parse the JSON, create a simple continuation from the text
        final story = StoryModel(
          id: 'story_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Continued Adventure',
          theme: 'general',
          region: 'Ghana',
          characterName: 'Kwame',
          ageGroup: '7-12',
          content: _createContentBlocksFromText('${selectedBranch.content}\n\n$responseText'),
          learningConcepts: selectedBranch.learningConcepts,
          emotionalTone: selectedBranch.emotionalTone,
          culturalNotes: {},
        );

        // Cache the story
        _storyCache[cacheKey] = story;

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

  /// Create a prompt for generating a story
  String _createStoryPrompt({
    required List<String> learningConcepts,
    required int skillLevel,
    required String culturalContext,
    required EmotionalTone emotionalTone,
    required List<Map<String, dynamic>> previousStories,
  }) {
    final skillLevelText = skillLevel == 1 ? 'beginner' : skillLevel == 3 ? 'intermediate' : 'advanced';
    final emotionalToneText = emotionalTone.name;

    final previousStoriesText = previousStories.isEmpty
        ? "This is the user's first story."
        : "Previous stories: ${previousStories.map((s) => s['title']).join(', ')}";

    return """
You are an expert storyteller creating an educational story about coding concepts through the lens of Kente weaving from Ghana.

Learning concepts to focus on: ${learningConcepts.join(', ')}
Skill level: $skillLevelText
Emotional tone: $emotionalToneText
Cultural context: $culturalContext
$previousStoriesText

Create an engaging, culturally rich story that teaches the specified learning concepts. The story should be appropriate for the user's skill level, not mentioning age but focusing on their coding knowledge. Incorporate the cultural context naturally into the narrative.

The story should have the following elements:
1. A clear beginning, middle, and end
2. Characters that the reader can relate to
3. A problem or challenge related to the learning concepts
4. A resolution that demonstrates the learning concepts
5. Cultural elements that enrich the story
6. An emotional tone that matches the specified tone

Format your response as a JSON object with the following structure:
{
  "title": "Story title",
  "content": "Full story content with paragraphs",
  "hasChoices": true/false (whether the story should have branching choices),
  "choicePrompt": "Text prompting the user to make a choice (if hasChoices is true)"
}

Make the story approximately 300-500 words long, engaging, and educational.
""";
  }

  /// Create a prompt for generating story branches
  String _createBranchPrompt({
    required StoryModel parentStory,
    required int skillLevel,
    required int choiceCount,
  }) {
    final skillLevelText = skillLevel == 1 ? 'beginner' : skillLevel == 3 ? 'intermediate' : 'advanced';

    return """
You are creating branching choices for an educational story about coding concepts through Kente weaving.

Parent story title: ${parentStory.title}
Parent story content: ${parentStory.content}
Learning concepts: ${parentStory.learningConcepts.join(', ')}
Skill level: $skillLevelText
Number of choices to generate: $choiceCount

Create $choiceCount different story branches that could follow from this story. Each branch should:
1. Start with a clear choice the user can make
2. Continue the story in a different direction
3. Still teach the same learning concepts
4. Maintain cultural relevance to Kente weaving
5. Have a different emotional tone if possible

Format your response as a JSON array of branch objects with the following structure:
[
  {
    "choiceText": "Short text describing the choice (e.g., 'Follow the river')",
    "content": "Content that continues the story based on this choice (100-200 words)",
    "emotionalTone": "One of: happy, sad, excited, tense, curious, neutral"
  },
  {
    "choiceText": "...",
    "content": "...",
    "emotionalTone": "..."
  }
]

Make each branch distinct and interesting, with different potential outcomes.
""";
  }

  /// Create a prompt for continuing a story from a branch
  String _createContinuationPrompt({
    required StoryBranchModel selectedBranch,
    required int skillLevel,
  }) {
    final skillLevelText = skillLevel == 1 ? 'beginner' : skillLevel == 3 ? 'intermediate' : 'advanced';

    return """
You are continuing an educational story about coding concepts through Kente weaving based on a user's choice.

Selected branch content: ${selectedBranch.content}
Learning concepts: ${selectedBranch.learningConcepts.join(', ')}
Emotional tone: ${selectedBranch.emotionalTone.name}
Skill level: $skillLevelText

Continue the story based on the selected branch. The continuation should:
1. Flow naturally from the branch content
2. Develop the story further with a clear middle and end
3. Reinforce the learning concepts
4. Maintain the emotional tone
5. Keep the cultural context of Kente weaving
6. Be appropriate for the user's skill level

Format your response as a JSON object with the following structure:
{
  "title": "Title for the continued story",
  "content": "Content that continues the story (200-400 words)",
  "culturalContext": "Brief description of cultural elements included",
  "hasChoices": true/false (whether this continuation should have further choices),
  "choicePrompt": "Text prompting the user to make another choice (if hasChoices is true)"
}

Make the continuation engaging, educational, and satisfying.
""";
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
  List<ContentBlock> _createContentBlocksFromText(String text) {
    // Split text into paragraphs
    final paragraphs = text.split('\n\n');

    // Create a content block for each paragraph
    return paragraphs.map((paragraph) {
      // Skip empty paragraphs
      if (paragraph.trim().isEmpty) return null;

      return ContentBlock(
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
    }).whereType<ContentBlock>().toList();
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

