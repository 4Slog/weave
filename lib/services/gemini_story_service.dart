import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/story_branch_model.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/story_memory_service.dart';
import 'package:kente_codeweaver/models/skill_level.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for generating AI-driven stories using Google's Gemini API.
/// Handles initialization, story generation, branching narratives, and response caching.
class GeminiStoryService {
  /// Gemini instance for API interactions.
  late final gemini.Gemini _gemini;

  /// Storage service for caching responses.
  final StorageService _storageService;

  /// HTTP client for API requests.
  final http.Client? _client;
  
  /// Flag indicating if the device is online (determined by API response)
  bool _isOnline = true;
  
  /// Maximum cache age in hours
  static const int _maxCacheAgeHours = 72;

  /// Create a new GeminiStoryService with optional dependencies
  GeminiStoryService({
    StorageService? storageService,
    http.Client? client,
  }) : 
    _storageService = storageService ?? StorageService(),
    _client = client;

  /// Initializes the Gemini service with the API key from environment variables.
  ///
  /// Throws an exception if the API key is not found or initialization fails.
  Future<void> initialize() async {
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
      await _checkConnectivity();
      
    } catch (e) {
      debugPrint('Failed to initialize GeminiStoryService: $e');
      throw Exception('Failed to initialize GeminiStoryService: $e');
    }
  }
  
  /// Checks if the service is ready to generate content
  /// Returns true if online or if offline but with cached content available
  Future<bool> isServiceAvailable() async {
    await _checkConnectivity();
    return _isOnline;
  }
  
  /// Check connectivity by making a simple API call
  Future<void> _checkConnectivity() async {
    try {
      // Try a simple API call to check connectivity
      final response = await _gemini.prompt(
        parts: [gemini.Part.text("Hello")],
      );
      
      _isOnline = response != null;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  /// Generates a story based on theme, skill level, and optional character name.
  ///
  /// First checks the cache for an existing story with the same parameters.
  /// If not found, generates a new story using the Gemini API.
  ///
  /// Parameters:
  /// - `skillLevel`: User's current skill level (used instead of age for difficulty)
  /// - `theme`: Theme of the story (e.g., "Space").
  /// - `characterName`: Optional name of the main character.
  /// - `userProgress`: Optional user progress for personalization
  ///
  /// Returns a `StoryModel` containing the generated story and related metadata.
  Future<StoryModel> generateStory({
    required SkillLevel skillLevel,
    required String theme,
    String? characterName,
    UserProgress? userProgress,
  }) async {
    // Check connectivity first
    await _checkConnectivity();
    
    // Create a unique cache key based on the input parameters
    final cacheKey = 'story_${theme}_${skillLevel.toString()}_${characterName ?? ""}';

    // Check if a cached response exists
    final cachedStory = await _storageService.getProgress(cacheKey);
    if (cachedStory != null) {
      try {
        // Check if cache is still valid (not too old)
        final cacheMetadata = await _storageService.getProgress('${cacheKey}_metadata');
        if (cacheMetadata != null) {
          final metadata = jsonDecode(cacheMetadata);
          final timestamp = DateTime.parse(metadata['timestamp']);
          final now = DateTime.now();
          final difference = now.difference(timestamp).inHours;
          
          // If cache is still valid or we're offline, use it
          if (difference < _maxCacheAgeHours || !_isOnline) {
            return StoryModel.fromJson(jsonDecode(cachedStory));
          }
        } else if (!_isOnline) {
          // If we're offline and have any cache, use it regardless of age
          return StoryModel.fromJson(jsonDecode(cachedStory));
        }
      } catch (e) {
        debugPrint('Error parsing cached story: $e');
        // Continue to generate a new story if parsing fails
      }
    }
    
    // If we're offline and don't have a valid cache, throw an exception
    if (!_isOnline) {
      throw Exception('Cannot generate story while offline. Please connect to the internet.');
    }

    // Determine difficulty level based on skill level
    final difficultyLevel = _getDifficultyFromSkillLevel(skillLevel);
    
    // Get mastered concepts from user progress if available
    List<String> masteredConcepts = [];
    List<String> inProgressConcepts = [];
    if (userProgress != null) {
      masteredConcepts = userProgress.conceptsMastered;
      inProgressConcepts = userProgress.conceptsInProgress;
    }

    // Construct a prompt for the Gemini model
    final prompt = '''
    Create an educational coding story about $theme for a learner with ${skillLevel.toString().split('.').last} skill level.
    ${characterName != null ? 'Include the character named $characterName.' : ''}
    
    The story should:
    1. Introduce a problem that can be solved with coding concepts
    2. Show how coding concepts help solve the problem
    3. End with a lesson learned
    4. Connect coding concepts to Kente weaving traditions from Ghana
    5. Be engaging and culturally authentic
    
    ${masteredConcepts.isNotEmpty ? 'Concepts the learner has already mastered: ${masteredConcepts.join(", ")}' : ''}
    ${inProgressConcepts.isNotEmpty ? 'Concepts the learner is currently learning: ${inProgressConcepts.join(", ")}' : ''}
    
    Format as JSON with the following structure:
    {
      "id": "unique_id_string",
      "title": "Story Title",
      "theme": "$theme",
      "region": "Ghana",
      "characterName": "${characterName ?? 'Kofi'}",
      "difficultyLevel": $difficultyLevel,
      "content": [
        {"id": "block1", "text": "Story text paragraph 1", "delay": 0, "displayDuration": 3000, "waitForInteraction": false, "emotionalTone": "neutral"},
        {"id": "block2", "text": "Story text paragraph 2", "delay": 0, "displayDuration": 3000, "waitForInteraction": true, "emotionalTone": "excited"}
      ],
      "challenge": {
        "id": "challenge_id",
        "title": "Challenge Title",
        "description": "Brief description of the challenge",
        "successCriteria": {"requiresBlockType": ["loop", "move"], "minConnections": 3},
        "difficulty": $difficultyLevel,
        "availableBlockTypes": ["move", "turn", "repeat"],
        "contentStartIndex": 2,
        "contentEndIndex": 4
      },
      "branches": [
        {"id": "branch1", "description": "Continue the adventure", "difficultyLevel": $difficultyLevel},
        {"id": "branch2", "description": "Try a harder challenge", "difficultyLevel": ${difficultyLevel + 1}}
      ],
      "culturalNotes": {
        "kentePattern": "This pattern represents wisdom",
        "regionalContext": "In Ghana, storytelling is a way of passing knowledge"
      },
      "learningConcepts": ["loops", "sequences"]
    }
    ''';

    try {
      // Use prompt with parts parameter instead of deprecated text method
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );

      // Extract the text response correctly
      final responseText = extractTextFromResponse(response);

      // Validate response
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Extract JSON from response text
      final jsonStr = extractJsonFromText(responseText);

      // Convert JSON to StoryModel
      final storyModel = StoryModel.fromJson(jsonDecode(jsonStr));

      // Cache the response for future use
      await _storageService.saveProgress(cacheKey, jsonStr);
      
      // Save cache metadata with timestamp
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'skillLevel': skillLevel.toString(),
        'theme': theme,
      };
      await _storageService.saveProgress('${cacheKey}_metadata', jsonEncode(metadata));

      return storyModel;
    } catch (e) {
      debugPrint('Failed to generate story: $e');
      
      // If we have a cached version, return it as fallback even if it's old
      if (cachedStory != null) {
        try {
          return StoryModel.fromJson(jsonDecode(cachedStory));
        } catch (parseError) {
          debugPrint('Error parsing fallback cached story: $parseError');
        }
      }
      
      throw Exception('Failed to generate story: $e');
    }
  }
  
  /// Maps skill level to difficulty level (1-5)
  int _getDifficultyFromSkillLevel(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.novice:
        return 1;
      case SkillLevel.beginner:
        return 2;
      case SkillLevel.intermediate:
        return 3;
      case SkillLevel.advanced:
        return 5;
      default:
        return 1;
    }
  }

  /// Extracts text content from the Gemini API response.
  ///
  /// Ensures compatibility with different response formats.
  String extractTextFromResponse(dynamic response) {
    // Handle null response case first
    if (response == null) {
      return '';
    }
    
    if (response is String) {
      return response;
    }
    
    // Handle model.Response format (from newer versions of the package)
    if (response.parts != null && response.parts.isNotEmpty) {
      return response.parts.first.text;
    }
    
    // Handle response.Response format (from older versions)
    if (response.content != null) {
      return response.content.parts.first.text;
    }
    
    // Handle map format (usually from testing mocks)
    if (response is Map && response.containsKey('content')) {
      return response['content'].toString();
    }
    
    // Fall back to toString() if we can't extract text in a known way
    return response.toString();
  }

  /// Extracts JSON from a text response.
  ///
  /// Handles cases where the JSON might be embedded in markdown code blocks or
  /// mixed with explanatory text.
  String extractJsonFromText(String text) {
    // First, check for JSON code blocks with triple backticks
    final jsonCodeBlockRegex = RegExp(r'```(?:json)?\s*({[\s\S]*?})\s*```');
    final jsonCodeBlockMatch = jsonCodeBlockRegex.firstMatch(text);
    if (jsonCodeBlockMatch != null && jsonCodeBlockMatch.group(1) != null) {
      return jsonCodeBlockMatch.group(1)!;
    }
    
    // Next, check for just a JSON object directly
    final jsonRegex = RegExp(r'({[\s\S]*})');
    final jsonMatch = jsonRegex.firstMatch(text);
    if (jsonMatch != null && jsonMatch.group(1) != null) {
      return jsonMatch.group(1)!;
    }
    
    // If we can't find JSON, return the text as is
    return text;
  }
  
  /// Generate an enhanced story with continuity and cultural context
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
    // Check connectivity first
    await _checkConnectivity();
    
    // If we're offline, try to get a cached story
    if (!_isOnline) {
      final cacheKey = 'story_${theme}_${skillLevel.toString()}_${characterName ?? ""}_${previousStoryId ?? ""}_${narrativeType ?? ""}';
      final cachedStory = await _storageService.getProgress(cacheKey);
      
      if (cachedStory != null) {
        try {
          return StoryModel.fromJson(jsonDecode(cachedStory));
        } catch (e) {
          debugPrint('Error parsing cached story: $e');
          throw Exception('Cannot generate story while offline. Please connect to the internet.');
        }
      } else {
        throw Exception('Cannot generate story while offline. Please connect to the internet.');
      }
    }
    
    // Get narrative context if not provided
    if (narrativeContext == null && previousStoryId != null) {
      final userId = userProgress?.userId ?? 'current_user';
      final memoryService = StoryMemoryService();
      narrativeContext = await memoryService.getNarrativeContext(userId, previousStoryId);
    }
    
    final storyType = narrativeType ?? _getRandomNarrativeType();
    
    // Determine difficulty level based on skill level
    final difficultyLevel = _getDifficultyFromSkillLevel(skillLevel);
    
    // Get mastered concepts from user progress if available
    List<String> masteredConcepts = [];
    List<String> inProgressConcepts = [];
    if (userProgress != null) {
      masteredConcepts = userProgress.conceptsMastered;
      inProgressConcepts = userProgress.conceptsInProgress;
    }
    
    // Create an enhanced prompt for Gemini
    final prompt = '''
    Create an educational coding story about $theme for a learner with ${skillLevel.toString().split('.').last} skill level.
    Story type: $storyType
    ${characterName != null ? 'Main character: $characterName' : ''}
    ${conceptsToTeach != null ? 'Concepts to teach: ${conceptsToTeach.join(", ")}' : ''}
    
    ${masteredConcepts.isNotEmpty ? 'Concepts the learner has already mastered: ${masteredConcepts.join(", ")}' : ''}
    ${inProgressConcepts.isNotEmpty ? 'Concepts the learner is currently learning: ${inProgressConcepts.join(", ")}' : ''}
    
    ${narrativeContext != null ? 'Previous story context: ${jsonEncode(narrativeContext)}' : ''}
    
    The story must include:
    1. A clear connection to Kente weaving from Ghana
    2. Coding concepts explained through cultural metaphors
    3. Interactive elements that encourage the learner to solve problems
    4. A moral or lesson related to both coding and culture
    5. Emotional expressions for different parts of the story
    6. References to specific Kente patterns and their meanings
    
    Format the response as a JSON object with:
    {
      "id": "unique_id_string",
      "title": "Story Title",
      "theme": "$theme",
      "region": "Ghana",
      "characterName": "${characterName ?? 'Kofi'}",
      "difficultyLevel": $difficultyLevel,
      "content": [
        {"id": "block1", "text": "Story text paragraph 1", "delay": 0, "displayDuration": 3000, "waitForInteraction": false, "emotionalTone": "neutral", "speakerImage": "assets/images/characters/ananse.png"},
        {"id": "block2", "text": "Story text paragraph 2", "delay": 0, "displayDuration": 3000, "waitForInteraction": true, "emotionalTone": "excited", "speakerImage": "assets/images/characters/ananse_teaching.png"}
      ],
      "challenge": {
        "id": "challenge_id",
        "title": "Challenge Title",
        "description": "Brief description of the challenge",
        "successCriteria": {"requiresBlockType": ["loop", "move"], "minConnections": 3},
        "difficulty": $difficultyLevel,
        "availableBlockTypes": ["move", "turn", "repeat"],
        "contentStartIndex": 2,
        "contentEndIndex": 4
      },
      "branches": [
        {"id": "branch1", "description": "Continue the adventure", "difficultyLevel": $difficultyLevel, "targetStoryId": "story_branch_1"},
        {"id": "branch2", "description": "Try a harder challenge", "difficultyLevel": ${difficultyLevel + 1}, "targetStoryId": "story_branch_2"}
      ],
      "culturalNotes": {
        "kentePattern": "This pattern represents wisdom",
        "regionalContext": "In Ghana, storytelling is a way of passing knowledge"
      },
      "learningConcepts": ["loops", "sequences"]
    }
    ''';

    try {
      // Use Gemini to generate the story
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );

      // Extract the text response
      final responseText = extractTextFromResponse(response);
      
      // Validate and parse response
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Extract JSON from response text
      final jsonStr = extractJsonFromText(responseText);
      
      // Create a story model from the JSON
      final storyModel = StoryModel.fromJson(jsonDecode(jsonStr));
      
      // Cache the response
      final cacheKey = 'story_${theme}_${skillLevel.toString()}_${characterName ?? ""}_${previousStoryId ?? ""}_${storyType}';
      await _storageService.saveProgress(cacheKey, jsonStr);
      
      // Save cache metadata with timestamp
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'skillLevel': skillLevel.toString(),
        'theme': theme,
        'previousStoryId': previousStoryId,
        'narrativeType': storyType,
      };
      await _storageService.saveProgress('${cacheKey}_metadata', jsonEncode(metadata));
      
      return storyModel;
    } catch (e) {
      debugPrint('Failed to generate enhanced story: $e');
      
      // If we have a cached version, return it as fallback
      final cacheKey = 'story_${theme}_${skillLevel.toString()}_${characterName ?? ""}_${previousStoryId ?? ""}_${storyType}';
      final cachedStory = await _storageService.getProgress(cacheKey);
      
      if (cachedStory != null) {
        try {
          return StoryModel.fromJson(jsonDecode(cachedStory));
        } catch (parseError) {
          debugPrint('Error parsing fallback cached story: $parseError');
        }
      }
      
      throw Exception('Failed to generate enhanced story: $e');
    }
  }
  
  /// Generate story branches based on current story
  Future<List<StoryBranchModel>> generateStoryBranches(
    StoryModel currentStory,
    UserProgress userProgress,
  ) async {
    // Check connectivity first
    await _checkConnectivity();
    
    // If we're offline, return empty branches
    if (!_isOnline) {
      return [];
    }
    
    // Get skill level from user progress
    final skillLevel = _getSkillLevelFromUserProgress(userProgress);
    
    // Create a prompt for generating branches
    final prompt = '''
    Create 2-3 story branch options for continuing a story about ${currentStory.theme} with a character named ${currentStory.characterName}.
    
    Current story summary:
    ${_extractStorySummary(currentStory)}
    
    The learner's skill level is: ${skillLevel.toString().split('.').last}
    
    Generate branches that:
    1. Offer different paths forward in the story
    2. Vary in difficulty level
    3. Focus on different coding concepts
    4. Connect to different aspects of Kente weaving traditions
    
    Format the response as a JSON array:
    [
      {
        "id": "branch_1",
        "description": "Brief description of this branch",
        "targetStoryId": "story_branch_1",
        "difficultyLevel": ${_getDifficultyFromSkillLevel(skillLevel)},
        "focusConcept": "loops"
      },
      {
        "id": "branch_2",
        "description": "Brief description of this branch",
        "targetStoryId": "story_branch_2",
        "difficultyLevel": ${_getDifficultyFromSkillLevel(skillLevel) + 1},
        "focusConcept": "conditionals"
      }
    ]
    ''';
    
    try {
      // Use Gemini to generate branches
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );
      
      // Extract the text response
      final responseText = extractTextFromResponse(response);
      
      // Validate response
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      // Extract JSON from response text
      final jsonStr = extractJsonFromText(responseText);
      
      // Parse JSON array
      final List<dynamic> branchesJson = jsonDecode(jsonStr);
      
      // Convert to StoryBranchModel objects
      final branches = branchesJson.map((json) => StoryBranchModel.fromJson(json)).toList();
      
      return branches;
    } catch (e) {
      debugPrint('Failed to generate story branches: $e');
      return [];
    }
  }
  
  /// Extract a summary of the story for use in prompts
  String _extractStorySummary(StoryModel story) {
    // Extract the first few content blocks to create a summary
    final contentBlocks = story.content.take(3).map((block) => block['text']).join(' ');
    
    // Limit to 200 words
    final words = contentBlocks.split(' ');
    if (words.length > 200) {
      return words.take(200).join(' ') + '...';
    }
    
    return contentBlocks;
  }
  
  /// Get skill level from user progress
  SkillLevel _getSkillLevelFromUserProgress(UserProgress userProgress) {
    // Count mastered concepts
    final masteredCount = userProgress.conceptsMastered.length;
    
    // Determine skill level based on mastered concepts
    if (masteredCount >= 8) {
      return SkillLevel.advanced;
    } else if (masteredCount >= 5) {
      return SkillLevel.intermediate;
    } else if (masteredCount >= 2) {
      return SkillLevel.beginner;
    } else {
      return SkillLevel.novice;
    }
  }

  /// Helper method to get a random narrative type
  String _getRandomNarrativeType() {
    final types = ['adventure', 'mystery', 'exploration', 'challenge'];
    return types[DateTime.now().millisecond % types.length];
  }
}
