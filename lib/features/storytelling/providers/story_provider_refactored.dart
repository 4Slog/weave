import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/enhanced_story_model.dart';
import '../models/story_progress_model.dart';
import '../repositories/story_repository.dart';
import '../services/story_generation_service.dart';
import '../services/educational_content_service.dart';

/// Enhanced provider for story management with educational features.
///
/// This provider manages stories, story generation, and educational
/// content alignment.
class StoryProviderRefactored extends ChangeNotifier {
  // Protected fields for subclasses to access
  final StoryRepository _repository;
  final StoryGenerationService _generationService;
  final EducationalContentService _educationalService;
  final StorageService _storageService;

  /// Currently selected story
  EnhancedStoryModel? _currentStory;

  /// List of available stories
  List<EnhancedStoryModel> _stories = [];

  /// Flag indicating if stories are being loaded
  bool _isLoading = false;

  /// Error message, if any
  String? _errorMessage;

  // Getters for subclasses to access protected fields
  @protected
  StoryRepository get protectedRepository => _repository;
  @protected
  StoryGenerationService get protectedGenerationService => _generationService;
  @protected
  EducationalContentService get protectedEducationalService => _educationalService;
  @protected
  StorageService get protectedStorageService => _storageService;
  @protected
  EnhancedStoryModel? get protectedCurrentStory => _currentStory;
  @protected
  set protectedCurrentStory(EnhancedStoryModel? value) => _currentStory = value;
  @protected
  List<EnhancedStoryModel> get protectedStories => _stories;
  @protected
  bool get protectedIsLoading => _isLoading;
  @protected
  set protectedIsLoading(bool value) => _isLoading = value;
  @protected
  String? get protectedErrorMessage => _errorMessage;
  @protected
  set protectedErrorMessage(String? value) => _errorMessage = value;

  /// Create a new StoryProviderRefactored.
  StoryProviderRefactored({
    StoryRepository? repository,
    StoryGenerationService? generationService,
    EducationalContentService? educationalService,
    StorageService? storageService,
  }) :
    _repository = repository ?? StoryRepository(StorageService().storage),
    _generationService = generationService ?? StoryGenerationService(),
    _educationalService = educationalService ?? EducationalContentService(),
    _storageService = storageService ?? StorageService();

  /// Initialize the provider.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.initialize();
      await _generationService.initialize();
      await _educationalService.initialize();

      // Load stories
      await loadStories();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all available stories.
  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stories = await _repository.getAllStories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stories: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a story by ID.
  Future<EnhancedStoryModel?> getStory(String storyId) async {
    try {
      return await _repository.getStory(storyId);
    } catch (e) {
      _errorMessage = 'Failed to get story: $e';
      notifyListeners();
      return null;
    }
  }

  /// Set the current story.
  Future<void> setCurrentStory(String storyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final story = await _repository.getStory(storyId);
      if (story != null) {
        _currentStory = story;
      } else {
        _errorMessage = 'Story not found: $storyId';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set current story: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a new story.
  Future<EnhancedStoryModel?> generateStory({
    required String userId,
    String? theme,
    String? region,
    String? ageGroup,
    List<String>? learningConcepts,
    int? difficultyLevel,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final story = await _generationService.generateStory(
        userId: userId,
        theme: theme,
        region: region,
        ageGroup: ageGroup,
        learningConcepts: learningConcepts,
        difficultyLevel: difficultyLevel,
      );

      // Save the generated story
      await _repository.saveStory(story);

      // Add to stories list
      _stories.add(story);

      _isLoading = false;
      notifyListeners();

      return story;
    } catch (e) {
      _errorMessage = 'Failed to generate story: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Save story progress.
  Future<void> saveProgress(StoryProgressModel progress) async {
    try {
      await _repository.saveStoryProgress(progress);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save progress: $e';
      notifyListeners();
    }
  }

  /// Get story progress.
  Future<StoryProgressModel?> getProgress(String userId, String storyId) async {
    try {
      return await _repository.getStoryProgress(userId, storyId);
    } catch (e) {
      _errorMessage = 'Failed to get progress: $e';
      notifyListeners();
      return null;
    }
  }

  /// Mark a story as completed.
  Future<void> markStoryCompleted(String userId, String storyId) async {
    try {
      // Get existing progress or create new progress
      StoryProgressModel progress = await _repository.getStoryProgress(userId, storyId) ??
                                   StoryProgressModel(
                                     userId: userId,
                                     storyId: storyId,
                                   );

      // Mark as completed
      progress = progress.markAsCompleted();

      // Save progress
      await _repository.saveStoryProgress(progress);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark story as completed: $e';
      notifyListeners();
    }
  }

  /// Get stories by theme.
  Future<List<EnhancedStoryModel>> getStoriesByTheme(String theme) async {
    try {
      return await _repository.getStoriesByTheme(theme);
    } catch (e) {
      _errorMessage = 'Failed to get stories by theme: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories by region.
  Future<List<EnhancedStoryModel>> getStoriesByRegion(String region) async {
    try {
      return await _repository.getStoriesByRegion(region);
    } catch (e) {
      _errorMessage = 'Failed to get stories by region: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories by age group.
  Future<List<EnhancedStoryModel>> getStoriesByAgeGroup(String ageGroup) async {
    try {
      return await _repository.getStoriesByAgeGroup(ageGroup);
    } catch (e) {
      _errorMessage = 'Failed to get stories by age group: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories by difficulty level.
  Future<List<EnhancedStoryModel>> getStoriesByDifficultyLevel(int difficultyLevel) async {
    try {
      return await _repository.getStoriesByDifficultyLevel(difficultyLevel);
    } catch (e) {
      _errorMessage = 'Failed to get stories by difficulty level: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories by learning concept.
  Future<List<EnhancedStoryModel>> getStoriesByLearningConcept(String concept) async {
    try {
      return await _repository.getStoriesByLearningConcept(concept);
    } catch (e) {
      _errorMessage = 'Failed to get stories by learning concept: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories completed by a user.
  Future<List<EnhancedStoryModel>> getCompletedStories(String userId) async {
    try {
      return await _repository.getCompletedStories(userId);
    } catch (e) {
      _errorMessage = 'Failed to get completed stories: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories not yet completed by a user.
  Future<List<EnhancedStoryModel>> getUncompletedStories(String userId) async {
    try {
      return await _repository.getUncompletedStories(userId);
    } catch (e) {
      _errorMessage = 'Failed to get uncompleted stories: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories in progress for a user.
  Future<List<EnhancedStoryModel>> getStoriesInProgress(String userId) async {
    try {
      return await _repository.getStoriesInProgress(userId);
    } catch (e) {
      _errorMessage = 'Failed to get stories in progress: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get recommended stories for a user.
  Future<List<EnhancedStoryModel>> getRecommendedStories(String userId, int count) async {
    try {
      return await _educationalService.getRecommendedStories(userId, count);
    } catch (e) {
      _errorMessage = 'Failed to get recommended stories: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories for a learning path.
  Future<List<EnhancedStoryModel>> getStoriesForLearningPath(LearningPathType learningPathType) async {
    try {
      return await _repository.getStoriesForLearningPath(learningPathType);
    } catch (e) {
      _errorMessage = 'Failed to get stories for learning path: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories aligned with educational standards.
  Future<List<EnhancedStoryModel>> getStoriesAlignedWithStandards(List<String> standardIds) async {
    try {
      return await _educationalService.getStoriesAlignedWithStandards(standardIds);
    } catch (e) {
      _errorMessage = 'Failed to get stories aligned with standards: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get stories covering specific coding concepts.
  Future<List<EnhancedStoryModel>> getStoriesCoveringConcepts(List<String> conceptIds) async {
    try {
      return await _educationalService.getStoriesCoveringConcepts(conceptIds);
    } catch (e) {
      _errorMessage = 'Failed to get stories covering concepts: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get the currently selected story.
  EnhancedStoryModel? get currentStory => _currentStory;

  /// Get all available stories.
  List<EnhancedStoryModel> get stories => _stories;

  /// Check if stories are being loaded.
  bool get isLoading => _isLoading;

  /// Get the error message, if any.
  String? get errorMessage => _errorMessage;

  /// Clear the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
