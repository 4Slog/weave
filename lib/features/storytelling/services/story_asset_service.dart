import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/optimized_asset_loader.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';

/// Service for managing story assets
class StoryAssetService {
  // Singleton implementation
  static final StoryAssetService _instance = StoryAssetService._internal();

  factory StoryAssetService() {
    return _instance;
  }

  StoryAssetService._internal();
  
  // Dependencies
  late final OptimizedAssetLoader _assetLoader;
  
  // Cache for story data
  List<StoryModel>? _stories;
  Map<String, dynamic>? _rawStoryData;
  
  // Initialization state
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get dependencies
      _assetLoader = ServiceProvider.get<OptimizedAssetLoader>();
      
      // Load story data
      await _loadStoryData();
      
      // Preload story images
      await _preloadStoryImages();
      
      _isInitialized = true;
      debugPrint('StoryAssetService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize StoryAssetService: $e');
    }
  }
  
  /// Load story data
  Future<void> _loadStoryData() async {
    final data = await _assetLoader.loadJson('assets/data/stories.json');
    _rawStoryData = data;
    
    final stories = data['stories'] as List<dynamic>;
    _stories = stories.map((story) => StoryModel.fromJson(story as Map<String, dynamic>)).toList();
  }
  
  /// Preload story images
  Future<void> _preloadStoryImages() async {
    if (_stories == null) return;
    
    final imagePaths = <String>[];
    
    // Collect image paths from story content
    for (final story in _stories!) {
      for (final contentBlock in story.content) {
        if (contentBlock.imagePath != null && contentBlock.imagePath!.isNotEmpty) {
          imagePaths.add(contentBlock.imagePath!);
        }
      }
    }
    
    // Add character images
    imagePaths.addAll([
      'assets/images/characters/ananse.png',
      'assets/images/characters/ananse_explaining.png',
      'assets/images/characters/ananse_teaching.png',
    ]);
    
    // Preload in parallel
    await Future.wait(
      imagePaths.map((path) => _assetLoader.loadImage(path))
    );
  }
  
  /// Get story by ID
  StoryModel? getStory(String storyId) {
    if (_stories == null) return null;
    
    try {
      return _stories!.firstWhere((story) => story.id == storyId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all stories
  List<StoryModel> getAllStories() {
    return _stories ?? [];
  }
  
  /// Get stories by theme
  List<StoryModel> getStoriesByTheme(String theme) {
    if (_stories == null) return [];
    
    return _stories!.where((story) => story.theme == theme).toList();
  }
  
  /// Get stories by difficulty level
  List<StoryModel> getStoriesByDifficulty(int difficultyLevel) {
    if (_stories == null) return [];
    
    return _stories!.where((story) => story.difficultyLevel == difficultyLevel).toList();
  }
  
  /// Get stories by region
  List<StoryModel> getStoriesByRegion(String region) {
    if (_stories == null) return [];
    
    return _stories!.where((story) => story.region == region).toList();
  }
  
  /// Get stories by character name
  List<StoryModel> getStoriesByCharacter(String characterName) {
    if (_stories == null) return [];
    
    return _stories!.where((story) => story.characterName == characterName).toList();
  }
  
  /// Get character image path
  String getCharacterImagePath(String characterName, String pose) {
    return 'assets/images/characters/${characterName.toLowerCase()}_${pose.toLowerCase()}.png';
  }
  
  /// Get story themes
  List<String> getAllThemes() {
    if (_stories == null) return [];
    
    final themes = <String>{};
    for (final story in _stories!) {
      themes.add(story.theme);
    }
    
    return themes.toList();
  }
  
  /// Get story regions
  List<String> getAllRegions() {
    if (_stories == null) return [];
    
    final regions = <String>{};
    for (final story in _stories!) {
      regions.add(story.region);
    }
    
    return regions.toList();
  }
  
  /// Get story characters
  List<String> getAllCharacters() {
    if (_stories == null) return [];
    
    final characters = <String>{};
    for (final story in _stories!) {
      characters.add(story.characterName);
    }
    
    return characters.toList();
  }
  
  /// Get story learning concepts
  List<String> getAllLearningConcepts() {
    if (_stories == null) return [];
    
    final concepts = <String>{};
    for (final story in _stories!) {
      concepts.addAll(story.learningConcepts);
    }
    
    return concepts.toList();
  }
}
