import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/services/gemini_story_service.dart';

class StoryProvider with ChangeNotifier {
  final GeminiStoryService _storyService = GeminiStoryService();
  List<StoryModel> _stories = [];
  StoryModel? _currentStory;
  bool _isLoading = false;
  String? _error;
  
  List<StoryModel> get stories => _stories;
  StoryModel? get currentStory => _currentStory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> initialize() async {
    try {
      await _storyService.initialize();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> generateStory({
    required int age,
    required String theme,
    String? characterName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final story = await _storyService.generateStory(
        age: age,
        theme: theme,
        characterName: characterName,
      );
      
      _currentStory = story;
      
      // Add to stories list if not already there
      if (!_stories.any((s) => s.id == story.id)) {
        _stories.add(story);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  void setCurrentStory(StoryModel story) {
    _currentStory = story;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}