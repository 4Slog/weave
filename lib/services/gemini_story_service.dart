import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/story_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for generating AI-driven stories using Google's Gemini API.
/// Handles initialization, story generation, and response caching.
class GeminiStoryService {
  /// Gemini instance for API interactions.
  late final gemini.Gemini _gemini;

  /// Storage service for caching responses.
  final StorageService _storageService;

  /// HTTP client for API requests.
  final http.Client? _client;

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
      
    } catch (e) {
      throw Exception('Failed to initialize GeminiStoryService: $e');
    }
  }

  /// Generates a story based on age, theme, and optional character name.
  ///
  /// First checks the cache for an existing story with the same parameters.
  /// If not found, generates a new story using the Gemini API.
  ///
  /// Parameters:
  /// - `age`: Target age of the audience (e.g., 8).
  /// - `theme`: Theme of the story (e.g., "Space").
  /// - `characterName`: Optional name of the main character.
  ///
  /// Returns a `StoryModel` containing the generated story and related metadata.
  Future<StoryModel> generateStory({
    required int age,
    required String theme,
    String? characterName,
  }) async {
    // Create a unique cache key based on the input parameters
    final cacheKey = 'story_${theme}_${age}_${characterName ?? ""}';

    // Check if a cached response exists
    final cachedStory = await _storageService.getProgress(cacheKey);
    if (cachedStory != null) {
      try {
        return StoryModel.fromJson(jsonDecode(cachedStory));
      } catch (e) {
        debugPrint('Error parsing cached story: $e');
        // Continue to generate a new story if parsing fails
      }
    }

    // Construct a prompt for the Gemini model
    final prompt = '''
    Create an educational coding story for a child aged $age about $theme.
    ${characterName != null ? 'Include the character named $characterName.' : ''}
    The story should include:
    1. A beginning that introduces a problem
    2. A middle that shows how coding concepts help solve the problem
    3. An ending with a lesson learned
    4. A list of 5 coding blocks that would be relevant to the story
    5. A difficulty level from 1-5
    
    Include cultural context about Kente weaving traditions from Ghana.
    
    Format as JSON with the following structure:
    {
      "id": "unique_id_string",
      "title": "Story Title",
      "theme": "$theme",
      "region": "Ghana",
      "characterName": "${characterName ?? 'Kofi'}",
      "ageGroup": "$age",
      "content": [
        {"id": "block1", "text": "Story text paragraph 1", "delay": 0, "displayDuration": 3000, "waitForInteraction": false},
        {"id": "block2", "text": "Story text paragraph 2", "delay": 0, "displayDuration": 3000, "waitForInteraction": true}
      ],
      "challenge": {
        "id": "challenge_id",
        "title": "Challenge Title",
        "description": "Brief description of the challenge",
        "successCriteria": {"requiresBlockType": ["loop", "move"], "minConnections": 3},
        "difficulty": 2,
        "availableBlockTypes": ["move", "turn", "repeat"],
        "contentStartIndex": 2,
        "contentEndIndex": 4
      },
      "branches": [
        {"id": "branch1", "description": "Continue the adventure", "difficultyLevel": 1},
        {"id": "branch2", "description": "Try a harder challenge", "difficultyLevel": 2}
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

      return storyModel;
    } catch (e) {
      throw Exception('Failed to generate story: $e');
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
    required int age,
    required String theme,
    String? characterName,
    String? previousStoryId,
    String? narrativeType,
    Map<String, dynamic>? narrativeContext,
    List<String>? conceptsToTeach,
  }) async {
    // Get narrative context if not provided
    if (narrativeContext == null && previousStoryId != null) {
      final userId = 'current_user'; // Replace with actual user ID
      final memoryService = StoryMemoryService();
      narrativeContext = await memoryService.getNarrativeContext(
        userId: userId,
        storyId: previousStoryId,
      );
    }
    
    final storyType = narrativeType ?? _getRandomNarrativeType();
    
    // Create an enhanced prompt for Gemini
    final prompt = '''
    Create an educational coding story for children aged $age about $theme.
    Story type: $storyType
    ${characterName != null ? 'Main character: $characterName' : ''}
    ${conceptsToTeach != null ? 'Concepts to teach: ${conceptsToTeach.join(", ")}' : ''}
    
    ${narrativeContext != null ? 'Previous story context: ${jsonEncode(narrativeContext)}' : ''}
    
    The story must include:
    1. A clear connection to Kente weaving from Ghana
    2. Coding concepts explained through cultural metaphors
    3. Interactive elements that encourage the child to solve problems
    4. A moral or lesson related to both coding and culture
    
    Format the response as a JSON object with:
    {
      "id": "unique_id_string",
      "title": "Story Title",
      "theme": "$theme",
      "region": "Ghana",
      "characterName": "${characterName ?? 'Kofi'}",
      "ageGroup": "$age",
      "content": [
        {"id": "block1", "text": "Story text paragraph 1", "delay": 0, "displayDuration": 3000, "waitForInteraction": false},
        {"id": "block2", "text": "Story text paragraph 2", "delay": 0, "displayDuration": 3000, "waitForInteraction": true}
      ],
      "challenge": {
        "id": "challenge_id",
        "title": "Challenge Title",
        "description": "Brief description of the challenge",
        "successCriteria": {"requiresBlockType": ["loop", "move"], "minConnections": 3},
        "difficulty": 2,
        "availableBlockTypes": ["move", "turn", "repeat"],
        "contentStartIndex": 2,
        "contentEndIndex": 4
      },
      "branches": [
        {"id": "branch1", "description": "Continue the adventure", "difficultyLevel": 1},
        {"id": "branch2", "description": "Try a harder challenge", "difficultyLevel": 2}
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
      final cacheKey = 'story_${theme}_${age}_${characterName ?? ""}_${previousStoryId ?? ""}_${storyType}';
      await _storageService.saveProgress(cacheKey, jsonStr);
      
      return storyModel;
    } catch (e) {
      throw Exception('Failed to generate enhanced story: $e');
    }
  }

  /// Helper method to get a random narrative type
  String _getRandomNarrativeType() {
    final types = ['adventure', 'mystery', 'exploration', 'challenge'];
    return types[DateTime.now().millisecond % types.length];
  }
}
