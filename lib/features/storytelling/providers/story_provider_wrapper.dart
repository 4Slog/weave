import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import '../models/enhanced_story_model.dart';
import '../models/story_progress_model.dart';
import '../repositories/story_repository.dart';
import 'story_provider_refactored.dart';

/// Wrapper for the refactored story provider to maintain backward compatibility.
///
/// This wrapper provides the same API as the original StoryProvider,
/// but uses the refactored implementation internally.
class StoryProvider extends ChangeNotifier {
  /// The refactored story provider
  final StoryProviderRefactored _refactoredProvider;

  /// Flag indicating if the provider is initialized
  bool _isInitialized = false;

  /// Create a new StoryProvider with optional dependencies
  StoryProvider({
    StoryProviderRefactored? refactoredProvider,
  }) :
    _refactoredProvider = refactoredProvider ?? StoryProviderRefactored();

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the refactored provider
      await _refactoredProvider.initialize();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize StoryProvider: $e');
      throw Exception('Failed to initialize StoryProvider: $e');
    }
  }

  /// Ensure the provider is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load all available stories
  Future<void> loadStories() async {
    await _ensureInitialized();

    await _refactoredProvider.loadStories();
    notifyListeners();
  }

  /// Get a story by ID
  Future<StoryModel?> getStory(String storyId) async {
    await _ensureInitialized();

    final enhancedStory = await _refactoredProvider.getStory(storyId);
    return enhancedStory;
  }

  /// Set the current story
  Future<void> setCurrentStory(String storyId) async {
    await _ensureInitialized();

    await _refactoredProvider.setCurrentStory(storyId);
    notifyListeners();
  }

  /// Generate a new story
  Future<StoryModel?> generateStory({
    required String userId,
    String? theme,
    String? region,
    String? ageGroup,
    List<String>? learningConcepts,
    int? difficultyLevel,
  }) async {
    await _ensureInitialized();

    final enhancedStory = await _refactoredProvider.generateStory(
      userId: userId,
      theme: theme,
      region: region,
      ageGroup: ageGroup,
      learningConcepts: learningConcepts,
      difficultyLevel: difficultyLevel,
    );

    notifyListeners();
    return enhancedStory;
  }

  /// Save story progress
  Future<void> saveProgress({
    required String userId,
    required String storyId,
    required int position,
    Map<String, String>? decisions,
  }) async {
    await _ensureInitialized();

    // Get existing progress or create new progress
    final existingProgress = await _refactoredProvider.getProgress(userId, storyId);

    if (existingProgress != null) {
      // Update existing progress
      final updatedProgress = existingProgress.updatePosition(position);

      // Add decisions if provided
      if (decisions != null) {
        for (final entry in decisions.entries) {
          updatedProgress.addDecision(entry.key, entry.value);
        }
      }

      await _refactoredProvider.saveProgress(updatedProgress);
    } else {
      // Create new progress
      final newProgress = StoryProgressModel(
        userId: userId,
        storyId: storyId,
        currentPosition: position,
        decisions: decisions ?? {},
      );

      await _refactoredProvider.saveProgress(newProgress);
    }

    notifyListeners();
  }

  /// Get story progress
  Future<Map<String, dynamic>> getProgress(String userId, String storyId) async {
    await _ensureInitialized();

    final progress = await _refactoredProvider.getProgress(userId, storyId);

    if (progress == null) {
      return {
        'position': 0,
        'completed': false,
      };
    }

    return {
      'position': progress.currentPosition,
      'completed': progress.completed,
      'decisions': progress.decisions,
    };
  }

  /// Mark a story as completed
  Future<void> markStoryCompleted(String userId, String storyId) async {
    await _ensureInitialized();

    await _refactoredProvider.markStoryCompleted(userId, storyId);
    notifyListeners();
  }

  /// Get stories by theme
  Future<List<StoryModel>> getStoriesByTheme(String theme) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesByTheme(theme);
    return enhancedStories;
  }

  /// Get stories by region
  Future<List<StoryModel>> getStoriesByRegion(String region) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesByRegion(region);
    return enhancedStories;
  }

  /// Get stories by age group
  Future<List<StoryModel>> getStoriesByAgeGroup(String ageGroup) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesByAgeGroup(ageGroup);
    return enhancedStories;
  }

  /// Get stories by difficulty level
  Future<List<StoryModel>> getStoriesByDifficultyLevel(int difficultyLevel) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesByDifficultyLevel(difficultyLevel);
    return enhancedStories;
  }

  /// Get stories by learning concept
  Future<List<StoryModel>> getStoriesByLearningConcept(String concept) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesByLearningConcept(concept);
    return enhancedStories;
  }

  /// Get stories completed by a user
  Future<List<StoryModel>> getCompletedStories(String userId) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getCompletedStories(userId);
    return enhancedStories;
  }

  /// Get stories not yet completed by a user
  Future<List<StoryModel>> getUncompletedStories(String userId) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getUncompletedStories(userId);
    return enhancedStories;
  }

  /// Get stories in progress for a user
  Future<List<StoryModel>> getStoriesInProgress(String userId) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getStoriesInProgress(userId);
    return enhancedStories;
  }

  /// Get recommended stories for a user
  Future<List<StoryModel>> getRecommendedStories(String userId, {int count = 3}) async {
    await _ensureInitialized();

    final enhancedStories = await _refactoredProvider.getRecommendedStories(userId, count);
    return enhancedStories;
  }

  /// Create a new story
  Future<StoryModel> createStory({
    required String title,
    required String theme,
    required String region,
    required String characterName,
    required String ageGroup,
    required List<ContentBlockModel> content,
    StoryChallenge? challenge,
    List<StoryBranch> branches = const [],
    Map<String, String> culturalNotes = const {},
    List<String> learningConcepts = const [],
    EmotionalTone emotionalTone = EmotionalTone.neutral,
    int difficultyLevel = 1,
    String description = '',
  }) async {
    await _ensureInitialized();

    // Create a new enhanced story
    final enhancedStory = EnhancedStoryModel(
      title: title,
      theme: theme,
      region: region,
      characterName: characterName,
      ageGroup: ageGroup,
      content: content,
      challenge: challenge,
      branches: branches,
      culturalNotes: culturalNotes,
      learningConcepts: learningConcepts,
      emotionalTone: emotionalTone,
      difficultyLevel: difficultyLevel,
      description: description,
    );

    // Create a new repository instance to save the story
    final storageService = StorageService();
    final repository = StoryRepository(storageService.storage);
    await repository.saveStory(enhancedStory);

    // Update the stories list
    await _refactoredProvider.loadStories();

    notifyListeners();
    return enhancedStory;
  }

  /// Update an existing story
  Future<void> updateStory(StoryModel story) async {
    await _ensureInitialized();

    // Convert to enhanced story if needed
    final enhancedStory = story is EnhancedStoryModel
        ? story
        : EnhancedStoryModel.fromStoryModel(story);

    // Create a new repository instance to save the story
    final storageService = StorageService();
    final repository = StoryRepository(storageService.storage);
    await repository.saveStory(enhancedStory);

    // Reload stories to ensure the list is updated
    await _refactoredProvider.loadStories();

    notifyListeners();
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    await _ensureInitialized();

    // Create a new repository instance to delete the story
    final storageService = StorageService();
    final repository = StoryRepository(storageService.storage);
    await repository.deleteStory(storyId);

    // Reload stories to ensure the list is updated
    await _refactoredProvider.loadStories();

    // Clear current story if it was deleted
    final currentStory = _refactoredProvider.currentStory;
    if (currentStory?.id == storyId) {
      // We can't set it directly, so we'll need to use a different approach
      // For now, just reload stories which should clear the current story
      await _refactoredProvider.loadStories();
    }

    notifyListeners();
  }

  /// Get the currently selected story
  StoryModel? get currentStory => _refactoredProvider.currentStory;

  /// Get all available stories
  List<StoryModel> get stories => _refactoredProvider.stories;

  /// Check if stories are being loaded
  bool get isLoading => _refactoredProvider.isLoading;

  /// Get the error message, if any
  String? get errorMessage => _refactoredProvider.errorMessage;

  /// Clear the error message
  void clearError() {
    _refactoredProvider.clearError();
    notifyListeners();
  }
}
