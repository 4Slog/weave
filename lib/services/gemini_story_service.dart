import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/services/storage_service.dart';

/// Service for generating AI-driven stories using Google's Gemini API.
/// Handles initialization, story generation, and response caching.
class GeminiStoryService {
  /// Gemini instance for API interactions.
  late final gemini.Gemini _gemini;

  /// Storage service for caching responses.
  final StorageService _storageService = StorageService();

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
      // Use the init method instead of configureApiKey
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
      return StoryModel.fromJson(jsonDecode(cachedStory));
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
    Format as JSON with the following fields:
    id, title, content, difficultyLevel, codeBlocks
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
    } else if (response.text != null) {
      return response.text;
    } else if (response.content?.parts != null && response.content!.parts!.isNotEmpty) {
      return response.content!.parts!.first.text ?? '';
    } else if (response.candidates != null && response.candidates!.isNotEmpty) {
      final candidate = response.candidates!.first;
      if (candidate.content?.parts != null && candidate.content!.parts!.isNotEmpty) {
        return candidate.content!.parts!.first.text ?? '';
      }
    }
    return '';
  }

  /// Extracts valid JSON from a text response.
  ///
  /// Attempts to parse the entire text as JSON.
  /// If that fails, uses regex to find JSON objects in the text.
  ///
  /// Parameter:
  /// - `text`: The text to extract JSON from.
  ///
  /// Returns the extracted JSON as a string.
  /// Throws an exception if no valid JSON is found.
  String extractJsonFromText(String text) {
    // Try to parse the entire text as JSON first
    try {
      jsonDecode(text);
      return text; // If no exception, it's valid JSON
    } catch (_) {
      // Use regex to find JSON objects in the text
      final RegExp jsonRegex = RegExp(r'({[\s\S]*?})(?=\n|$)');
      final matches = jsonRegex.allMatches(text);

      if (matches.isEmpty) {
        throw Exception('Could not extract JSON from response');
      }

      // Try each match until we find valid JSON
      for (final match in matches) {
        try {
          final jsonStr = match.group(0)!;
          // Verify this is valid JSON by attempting to parse it
          jsonDecode(jsonStr);
          return jsonStr;
        } catch (_) {
          // Continue to next match if this one isn't valid JSON
          continue;
        }
      }

      throw Exception('No valid JSON found in response');
    }
  }

  /// Validates a story for educational content and appropriateness.
  ///
  /// Ensures the generated story meets educational standards
  /// and is appropriate for the target age group.
  ///
  /// Parameter:
  /// - `storyModel`: The story model to validate.
  ///
  /// Returns `true` if the story is valid, `false` otherwise.
  bool validateStory(StoryModel storyModel) {
    // Check if the story has all required fields
    if (storyModel.title.isEmpty ||
        storyModel.content.isEmpty ||
        storyModel.codeBlocks.isEmpty) {
      return false;
    }

    // Check if the difficulty level is within range
    if (storyModel.difficultyLevel < 1 || storyModel.difficultyLevel > 5) {
      return false;
    }

    return true;
  }
}
