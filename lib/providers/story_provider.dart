import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/content_block_model.dart';
import 'package:kente_codeweaver/services/story_memory_service.dart';
import 'package:kente_codeweaver/services/gemini_story_service.dart';

/// Provider to manage stories in the application
class StoryProvider with ChangeNotifier {
  final StoryMemoryService _storyMemoryService = StoryMemoryService();
  final GeminiStoryService _geminiStoryService = GeminiStoryService();
  
  /// List of all available stories
  List<StoryModel> _stories = [];
  
  /// Currently selected story
  StoryModel? _selectedStory;
  
  /// Loading state
  bool _isLoading = false;
  
  /// Error message
  String? _error;
  
  /// Get all stories
  List<StoryModel> get stories => _stories;
  
  /// Get currently selected story
  StoryModel? get selectedStory => _selectedStory;
  
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
  
  /// Generate a personalized story based on user progress
  Future<StoryModel?> generatePersonalizedStory(String userId) async {
    _setLoading(true);
    
    try {
      // Get user narrative context
      final Map<String, dynamic> narrativeContext = 
        await _storyMemoryService.getNarrativeContext(userId);
      
      // Generate story using AI service
      final StoryModel? generatedStory = 
        await _geminiStoryService.generateStory(narrativeContext);
      
      if (generatedStory != null) {
        // Add to stories list
        _stories.add(generatedStory);
        notifyListeners();
      }
      
      _setLoading(false);
      return generatedStory;
    } catch (e) {
      _setError('Failed to generate personalized story: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  /// Get stories filtered by difficulty level
  List<StoryModel> getStoriesByDifficulty(String difficultyLevel) {
    return _stories.where((story) {
      final storyDifficulty = story.metadata?['difficultyLevel'];
      return storyDifficulty != null && 
        storyDifficulty.toString().toLowerCase() == difficultyLevel.toLowerCase();
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
  void addContentBlock(ContentBlock contentBlock) {
    if (_selectedStory == null) return;
    
    final updatedContent = List<dynamic>.from(_selectedStory!.content)..add(contentBlock);
    
    _selectedStory = _selectedStory!.copyWith(content: updatedContent);
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
}