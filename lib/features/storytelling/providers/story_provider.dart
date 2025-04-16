import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/storytelling/services/memory/story_memory_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';

/// Provider to manage stories in the application
/// Enhanced with better support for branching narratives, story state management,
/// and skill-based progression instead of age-based progression.
class StoryProvider with ChangeNotifier {
  final StoryMemoryService _storyMemoryService = StoryMemoryService();
  final GeminiStoryService _geminiStoryService = GeminiStoryService();
  final StorageService _storageService = StorageService();

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// List of all available stories
  List<StoryModel> _stories = [];

  /// Currently selected story
  StoryModel? _selectedStory;

  /// Currently selected story branch
  StoryBranchModel? _selectedBranch;

  /// Story navigation history for continuity
  List<String> _storyHistory = [];

  /// Current story state for branching narratives
  Map<String, dynamic> _currentStoryState = {};

  /// Loading state
  bool _isLoading = false;

  /// Error message
  String? _error;

  /// Get all stories
  List<StoryModel> get stories => _stories;

  /// Get currently selected story
  StoryModel? get selectedStory => _selectedStory;

  /// Get currently selected branch
  StoryBranchModel? get selectedBranch => _selectedBranch;

  /// Get story navigation history
  List<String> get storyHistory => _storyHistory;

  /// Get current story state
  Map<String, dynamic> get currentStoryState => _currentStoryState;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Get completed stories (requires userId)
  Future<List<StoryModel>> getCompletedStories(String userId) async {
    final List<String> completedStoryIds = await _storyMemoryService.getCompletedStories(userId);

    return _stories.where((story) =>
      completedStoryIds.contains(story.id)
    ).toList();
  }

  /// Get uncompleted stories (requires userId)
  Future<List<StoryModel>> getUncompletedStories(String userId) async {
    final List<String> completedStoryIds = await _storyMemoryService.getCompletedStories(userId);

    return _stories.where((story) =>
      !completedStoryIds.contains(story.id)
    ).toList();
  }

  /// Load stories from assets
  Future<void> loadStories() async {
    _setLoading(true);

    try {
      // Load story data from JSON asset
      final String jsonData = await rootBundle.loadString('assets/data/stories.json');
      final List<dynamic> jsonList = jsonDecode(jsonData) as List<dynamic>;

      _stories = jsonList.map((json) => StoryModel.fromJson(json)).toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stories: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Select a story by ID
  void selectStory(String storyId) {
    try {
      _selectedStory = _stories.firstWhere((story) => story.id == storyId);
      notifyListeners();
    } catch (e) {
      _setError('Story not found with ID: $storyId');
    }
  }

  /// Clear selected story
  void clearSelectedStory() {
    _selectedStory = null;
    notifyListeners();
  }

  /// Initialize the story provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      // Initialize the Gemini story service
      await _geminiStoryService.initialize();

      // Load stories from assets
      await loadStories();

      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize story provider: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Generate a personalized story based on user progress
  Future<StoryModel?> generatePersonalizedStory(String userId, {
    String theme = 'coding',
    String? characterName,
  }) async {
    _setLoading(true);

    try {
      // Ensure the service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Get user narrative context
      final Map<String, dynamic> narrativeContext =
        await _storyMemoryService.getNarrativeContext(userId);

      // Get user progress
      final UserProgress userProgress = UserProgress(
        userId: userId,
        name: narrativeContext['userName'] ?? 'Learner',
        level: 1, // Default level
        conceptsMastered: narrativeContext['masteredConcepts'] ?? [],
        conceptsInProgress: narrativeContext['inProgressConcepts'] ?? [],
      );

      // Determine skill level based on user progress
      final SkillLevel skillLevel = _getSkillLevelFromUserProgress(userProgress);

      // Generate story using AI service
      final StoryModel generatedStory = await _geminiStoryService.generateEnhancedStory(
        skillLevel: skillLevel,
        theme: theme,
        characterName: characterName,
        narrativeContext: narrativeContext,
        userProgress: userProgress,
      );

      // Add to stories list
      _stories.add(generatedStory);
      notifyListeners();

      _setLoading(false);
      return generatedStory;
    } catch (e) {
      _setError('Failed to generate personalized story: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Generate a story based on theme and skill level
  Future<StoryModel?> generateStory({
    required SkillLevel skillLevel,
    required String theme,
    String? characterName,
    UserProgress? userProgress,
  }) async {
    _setLoading(true);

    try {
      // Ensure the service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Generate story using AI service
      final StoryModel generatedStory = await _geminiStoryService.generateStory(
        learningConcepts: ['variables', 'loops', 'conditionals'],
        userProgress: userProgress!,
      );

      // Add to stories list
      _stories.add(generatedStory);
      notifyListeners();

      _setLoading(false);
      return generatedStory;
    } catch (e) {
      _setError('Failed to generate story: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Get stories filtered by difficulty level
  List<StoryModel> getStoriesByDifficulty(String difficultyLevel) {
    return _stories.where((story) {
      final storyDifficulty = story.challenge?.difficulty;
      return storyDifficulty != null &&
        storyDifficulty.toString() == difficultyLevel;
    }).toList();
  }

  /// Get a story by ID
  StoryModel? getStoryById(String storyId) {
    try {
      return _stories.firstWhere((story) => story.id == storyId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new content block in the selected story
  void addContentBlock(ContentBlockModel contentBlock) {
    if (_selectedStory == null) return;

    final updatedContent = List<ContentBlockModel>.from(_selectedStory!.content)..add(contentBlock);

    // Create a new story with the updated content
    _selectedStory = StoryModel(
      id: _selectedStory!.id,
      title: _selectedStory!.title,
      theme: _selectedStory!.theme,
      region: _selectedStory!.region,
      characterName: _selectedStory!.characterName,
      ageGroup: _selectedStory!.ageGroup,
      content: updatedContent,
      challenge: _selectedStory!.challenge,
      branches: _selectedStory!.branches,
      culturalNotes: _selectedStory!.culturalNotes,
      learningConcepts: _selectedStory!.learningConcepts,
    );

    notifyListeners();
  }

  /// Check if a story is completed by a user
  Future<bool> isStoryCompleted(String userId, String storyId) async {
    return _storyMemoryService.isStoryCompleted(userId, storyId);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
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

  /// Helper method to convert StoryBranchModel to StoryBranch
  List<StoryBranch> _convertToStoryBranches(List<StoryBranchModel> branchModels) {
    return branchModels.map((model) => StoryBranch(
      id: model.id,
      description: model.description,
      targetStoryId: model.targetStoryId,
      requirements: model.requirements,
      difficultyLevel: model.difficultyLevel,
    )).toList();
  }

  /// Generate story branches for the current story
  Future<List<StoryBranchModel>> generateStoryBranches(String userId) async {
    if (_selectedStory == null) {
      _setError('No story selected for branch generation');
      return [];
    }

    _setLoading(true);

    try {
      // Get user progress
      final narrativeContext = await _storyMemoryService.getNarrativeContext(userId);

      final userProgress = UserProgress(
        userId: userId,
        name: narrativeContext['userName'] ?? 'Learner',
        level: narrativeContext['level'] ?? 1,
        conceptsMastered: List<String>.from(narrativeContext['masteredConcepts'] ?? []),
        conceptsInProgress: List<String>.from(narrativeContext['inProgressConcepts'] ?? []),
      );

      // Generate branches using AI service
      final branchModels = await _geminiStoryService.generateStoryBranches(
        parentStory: _selectedStory!,
        userProgress: userProgress!,
      );

      // Convert StoryBranchModel to StoryBranch for the story
      final storyBranches = _convertToStoryBranches(branchModels);

      // Update the selected story with the new branches
      _selectedStory = StoryModel(
        id: _selectedStory!.id,
        title: _selectedStory!.title,
        theme: _selectedStory!.theme,
        region: _selectedStory!.region,
        characterName: _selectedStory!.characterName,
        ageGroup: _selectedStory!.ageGroup,
        content: _selectedStory!.content,
        challenge: _selectedStory!.challenge,
        branches: storyBranches,
        culturalNotes: _selectedStory!.culturalNotes,
        learningConcepts: _selectedStory!.learningConcepts,
      );

      _setLoading(false);
      notifyListeners();

      return branchModels;
    } catch (e) {
      _setError('Failed to generate story branches: ${e.toString()}');
      _setLoading(false);
      return [];
    }
  }

  /// Select a story branch
  void selectBranch(StoryBranchModel branch) {
    _selectedBranch = branch;

    // Add current story to history for continuity
    if (_selectedStory != null) {
      _storyHistory.add(_selectedStory!.id);

      // Limit history size
      if (_storyHistory.length > 10) {
        _storyHistory.removeAt(0);
      }
    }

    notifyListeners();
  }

  /// Follow a story branch to generate a new story
  Future<StoryModel?> followBranch(String userId) async {
    if (_selectedBranch == null || _selectedStory == null) {
      _setError('No branch selected to follow');
      return null;
    }

    _setLoading(true);

    try {
      // Get user progress
      final narrativeContext = await _storyMemoryService.getNarrativeContext(userId);

      final userProgress = UserProgress(
        userId: userId,
        name: narrativeContext['userName'] ?? 'Learner',
        level: narrativeContext['level'] ?? 1,
        conceptsMastered: List<String>.from(narrativeContext['masteredConcepts'] ?? []),
        conceptsInProgress: List<String>.from(narrativeContext['inProgressConcepts'] ?? []),
      );

      // Determine skill level based on branch difficulty
      final skillLevel = _getSkillLevelFromDifficulty(_selectedBranch!.difficultyLevel);

      // Generate a new story based on the branch
      final newStory = await _geminiStoryService.generateEnhancedStory(
        skillLevel: skillLevel,
        theme: _selectedStory!.theme,
        characterName: _selectedStory!.characterName,
        previousStoryId: _selectedStory!.id,
        narrativeType: _selectedBranch!.focusConcept,
        userProgress: userProgress,
      );

      // Add to stories list
      _stories.add(newStory);

      // Update story state for continuity
      _updateStoryState(_selectedStory!, newStory);

      // Select the new story
      _selectedStory = newStory;
      _selectedBranch = null;

      _setLoading(false);
      notifyListeners();

      return newStory;
    } catch (e) {
      _setError('Failed to follow story branch: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Update story state for continuity between stories
  void _updateStoryState(StoryModel previousStory, StoryModel newStory) {
    // Merge previous state with new information
    final updatedState = Map<String, dynamic>.from(_currentStoryState);

    // Add characters
    if (!updatedState.containsKey('characters')) {
      updatedState['characters'] = <String>[];
    }
    if (!updatedState['characters'].contains(previousStory.characterName)) {
      (updatedState['characters'] as List<String>).add(previousStory.characterName);
    }

    // Add themes
    if (!updatedState.containsKey('themes')) {
      updatedState['themes'] = <String>[];
    }
    if (!updatedState['themes'].contains(previousStory.theme)) {
      (updatedState['themes'] as List<String>).add(previousStory.theme);
    }

    // Add learning concepts
    if (!updatedState.containsKey('learningConcepts')) {
      updatedState['learningConcepts'] = <String>[];
    }
    for (final concept in previousStory.learningConcepts) {
      if (!(updatedState['learningConcepts'] as List<String>).contains(concept)) {
        (updatedState['learningConcepts'] as List<String>).add(concept);
      }
    }

    // Add story connections
    if (!updatedState.containsKey('storyConnections')) {
      updatedState['storyConnections'] = <Map<String, String>>[];
    }
    (updatedState['storyConnections'] as List<Map<String, String>>).add({
      'from': previousStory.id,
      'to': newStory.id,
      'via': _selectedBranch?.id ?? 'direct',
    });

    // Update the current story state
    _currentStoryState = updatedState;
  }

  /// Get skill level from difficulty value
  SkillLevel _getSkillLevelFromDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return SkillLevel.novice;
      case 2:
        return SkillLevel.beginner;
      case 3:
      case 4:
        return SkillLevel.intermediate;
      case 5:
        return SkillLevel.advanced;
      default:
        return SkillLevel.beginner;
    }
  }

  /// Navigate back to a previous story in the history
  void navigateBack() {
    if (_storyHistory.isEmpty) return;

    // Get the last story ID from history
    final previousStoryId = _storyHistory.removeLast();

    // Find and select that story
    selectStory(previousStoryId);

    notifyListeners();
  }

  /// Save story state for a user
  Future<void> saveStoryState(String userId) async {
    if (_currentStoryState.isEmpty) return;

    try {
      // Convert state to JSON
      final stateJson = jsonEncode(_currentStoryState);

      // Save to storage
      await _storageService.saveProgress('story_state_$userId', stateJson);
    } catch (e) {
      _setError('Failed to save story state: ${e.toString()}');
    }
  }

  /// Load story state for a user
  Future<void> loadStoryState(String userId) async {
    try {
      // Get state from storage
      final stateJson = await _storageService.getProgress('story_state_$userId');

      if (stateJson != null) {
        // Parse JSON
        _currentStoryState = jsonDecode(stateJson);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load story state: ${e.toString()}');
    }
  }
}

