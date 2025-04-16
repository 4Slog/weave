import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/base_repository.dart';
import 'package:kente_codeweaver/core/services/storage/storage_strategy.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/enhanced_story_model.dart';
import '../models/story_progress_model.dart';
import '../models/story_metadata_model.dart';

/// Repository for managing stories and story-related data.
/// 
/// This repository handles the storage and retrieval of stories,
/// story progress, and story metadata.
class StoryRepository implements BaseRepository {
  final StorageStrategy _storage;
  
  static const String _storyKeyPrefix = 'story_';
  static const String _allStoriesKey = 'all_stories';
  static const String _storyProgressKeyPrefix = 'story_progress_';
  static const String _storyMetadataKeyPrefix = 'story_metadata_';
  
  /// Creates a new StoryRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  StoryRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a story.
  /// 
  /// [story] is the story to save.
  Future<void> saveStory(EnhancedStoryModel story) async {
    final key = _storyKeyPrefix + story.id;
    await _storage.saveData(key, story.toJson());
    
    // Update the list of all stories
    await _updateStoriesList(story.id);
  }
  
  /// Get a story by ID.
  /// 
  /// [storyId] is the ID of the story to retrieve.
  /// Returns the story if found, or null if not found.
  Future<EnhancedStoryModel?> getStory(String storyId) async {
    final key = _storyKeyPrefix + storyId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return EnhancedStoryModel.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing story: $e');
      return null;
    }
  }
  
  /// Get all stories.
  /// 
  /// Returns a list of all stories.
  Future<List<EnhancedStoryModel>> getAllStories() async {
    final storyIds = await _getStoryIds();
    final stories = <EnhancedStoryModel>[];
    
    for (final id in storyIds) {
      final story = await getStory(id);
      if (story != null) {
        stories.add(story);
      }
    }
    
    return stories;
  }
  
  /// Get stories by theme.
  /// 
  /// [theme] is the theme of stories to retrieve.
  /// Returns a list of stories with the specified theme.
  Future<List<EnhancedStoryModel>> getStoriesByTheme(String theme) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.theme == theme).toList();
  }
  
  /// Get stories by region.
  /// 
  /// [region] is the region of stories to retrieve.
  /// Returns a list of stories from the specified region.
  Future<List<EnhancedStoryModel>> getStoriesByRegion(String region) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.region == region).toList();
  }
  
  /// Get stories by age group.
  /// 
  /// [ageGroup] is the age group of stories to retrieve.
  /// Returns a list of stories for the specified age group.
  Future<List<EnhancedStoryModel>> getStoriesByAgeGroup(String ageGroup) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.ageGroup == ageGroup).toList();
  }
  
  /// Get stories by difficulty level.
  /// 
  /// [difficultyLevel] is the difficulty level of stories to retrieve.
  /// Returns a list of stories with the specified difficulty level.
  Future<List<EnhancedStoryModel>> getStoriesByDifficultyLevel(int difficultyLevel) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.difficultyLevel == difficultyLevel).toList();
  }
  
  /// Get stories by learning concept.
  /// 
  /// [concept] is the learning concept to filter by.
  /// Returns a list of stories that teach the specified concept.
  Future<List<EnhancedStoryModel>> getStoriesByLearningConcept(String concept) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.learningConcepts.contains(concept)).toList();
  }
  
  /// Get stories by educational standard.
  /// 
  /// [standardId] is the ID of the educational standard to filter by.
  /// Returns a list of stories aligned with the specified standard.
  Future<List<EnhancedStoryModel>> getStoriesByStandard(String standardId) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.educationalStandards.contains(standardId)).toList();
  }
  
  /// Get stories appropriate for a user's skill level.
  /// 
  /// [skillLevel] is the user's skill level.
  /// Returns a list of stories appropriate for the user's skill level.
  Future<List<EnhancedStoryModel>> getStoriesForSkillLevel(int skillLevel) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.isAppropriateForSkillLevel(skillLevel)).toList();
  }
  
  /// Get stories with prerequisites satisfied by a user's mastered concepts.
  /// 
  /// [masteredConcepts] is a list of concepts the user has mastered.
  /// Returns a list of stories with prerequisites satisfied by the user's mastered concepts.
  Future<List<EnhancedStoryModel>> getStoriesWithPrerequisitesSatisfied(
    List<String> masteredConcepts
  ) async {
    final allStories = await getAllStories();
    return allStories.where((story) => story.hasPrerequisites(masteredConcepts)).toList();
  }
  
  /// Get stories for a learning path.
  /// 
  /// [learningPathType] is the type of learning path.
  /// Returns a list of stories suitable for the specified learning path.
  Future<List<EnhancedStoryModel>> getStoriesForLearningPath(
    LearningPathType learningPathType
  ) async {
    final allStories = await getAllStories();
    
    // Filter stories based on learning path type
    switch (learningPathType) {
      case LearningPathType.logicBased:
        // For logic-based paths, prioritize stories with logical concepts
        return allStories.where((story) => 
          story.learningConcepts.any((concept) => 
            ['sequences', 'loops', 'conditionals', 'functions', 'algorithms'].contains(concept)
          )
        ).toList();
        
      case LearningPathType.creativityBased:
        // For creativity-based paths, prioritize stories with creative concepts
        return allStories.where((story) => 
          story.learningConcepts.any((concept) => 
            ['patterns', 'design', 'creativity', 'expression', 'art'].contains(concept)
          )
        ).toList();
        
      case LearningPathType.challengeBased:
        // For challenge-based paths, prioritize more difficult stories
        return allStories.where((story) => story.difficultyLevel >= 3).toList();
        
      case LearningPathType.balanced:
      default:
        // For balanced paths, return all stories
        return allStories;
    }
  }
  
  /// Get stories completed by a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of stories completed by the user.
  Future<List<EnhancedStoryModel>> getCompletedStories(String userId) async {
    final progress = await getAllStoryProgress(userId);
    final completedStoryIds = progress
        .where((p) => p.completed)
        .map((p) => p.storyId)
        .toList();
    
    final completedStories = <EnhancedStoryModel>[];
    for (final id in completedStoryIds) {
      final story = await getStory(id);
      if (story != null) {
        completedStories.add(story);
      }
    }
    
    return completedStories;
  }
  
  /// Get stories not yet completed by a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of stories not yet completed by the user.
  Future<List<EnhancedStoryModel>> getUncompletedStories(String userId) async {
    final allStories = await getAllStories();
    final completedStories = await getCompletedStories(userId);
    final completedIds = completedStories.map((s) => s.id).toSet();
    
    return allStories.where((story) => !completedIds.contains(story.id)).toList();
  }
  
  /// Get stories in progress for a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of stories in progress for the user.
  Future<List<EnhancedStoryModel>> getStoriesInProgress(String userId) async {
    final progress = await getAllStoryProgress(userId);
    final inProgressStoryIds = progress
        .where((p) => !p.completed && p.currentPosition > 0)
        .map((p) => p.storyId)
        .toList();
    
    final inProgressStories = <EnhancedStoryModel>[];
    for (final id in inProgressStoryIds) {
      final story = await getStory(id);
      if (story != null) {
        inProgressStories.add(story);
      }
    }
    
    return inProgressStories;
  }
  
  /// Delete a story.
  /// 
  /// [storyId] is the ID of the story to delete.
  Future<void> deleteStory(String storyId) async {
    final key = _storyKeyPrefix + storyId;
    await _storage.removeData(key);
    
    // Update the list of all stories
    await _removeFromStoriesList(storyId);
  }
  
  /// Save story progress.
  /// 
  /// [progress] is the story progress to save.
  Future<void> saveStoryProgress(StoryProgressModel progress) async {
    final key = _storyProgressKeyPrefix + progress.userId + '_' + progress.storyId;
    await _storage.saveData(key, progress.toJson());
  }
  
  /// Get story progress.
  /// 
  /// [userId] is the ID of the user.
  /// [storyId] is the ID of the story.
  /// Returns the story progress if found, or null if not found.
  Future<StoryProgressModel?> getStoryProgress(String userId, String storyId) async {
    final key = _storyProgressKeyPrefix + userId + '_' + storyId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return StoryProgressModel.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing story progress: $e');
      return null;
    }
  }
  
  /// Get all story progress for a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of all story progress for the user.
  Future<List<StoryProgressModel>> getAllStoryProgress(String userId) async {
    final allKeys = await _storage.getAllKeys();
    final progressKeys = allKeys.where(
      (key) => key.startsWith(_storyProgressKeyPrefix + userId + '_')
    ).toList();
    
    final progressList = <StoryProgressModel>[];
    for (final key in progressKeys) {
      final data = await _storage.getData(key);
      if (data != null) {
        try {
          progressList.add(StoryProgressModel.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing story progress: $e');
        }
      }
    }
    
    return progressList;
  }
  
  /// Save story metadata.
  /// 
  /// [metadata] is the story metadata to save.
  Future<void> saveStoryMetadata(StoryMetadataModel metadata) async {
    final key = _storyMetadataKeyPrefix + metadata.storyId;
    await _storage.saveData(key, metadata.toJson());
  }
  
  /// Get story metadata.
  /// 
  /// [storyId] is the ID of the story.
  /// Returns the story metadata if found, or null if not found.
  Future<StoryMetadataModel?> getStoryMetadata(String storyId) async {
    final key = _storyMetadataKeyPrefix + storyId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return StoryMetadataModel.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing story metadata: $e');
      return null;
    }
  }
  
  /// Get all story metadata.
  /// 
  /// Returns a list of all story metadata.
  Future<List<StoryMetadataModel>> getAllStoryMetadata() async {
    final allKeys = await _storage.getAllKeys();
    final metadataKeys = allKeys.where(
      (key) => key.startsWith(_storyMetadataKeyPrefix)
    ).toList();
    
    final metadataList = <StoryMetadataModel>[];
    for (final key in metadataKeys) {
      final data = await _storage.getData(key);
      if (data != null) {
        try {
          metadataList.add(StoryMetadataModel.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing story metadata: $e');
        }
      }
    }
    
    return metadataList;
  }
  
  /// Get story metadata by standard.
  /// 
  /// [standardId] is the ID of the educational standard.
  /// Returns a list of story metadata aligned with the specified standard.
  Future<List<StoryMetadataModel>> getStoryMetadataByStandard(String standardId) async {
    final allMetadata = await getAllStoryMetadata();
    return allMetadata.where(
      (metadata) => metadata.alignsWithStandard(standardId)
    ).toList();
  }
  
  /// Get story metadata by coding concept.
  /// 
  /// [conceptId] is the ID of the coding concept.
  /// Returns a list of story metadata covering the specified coding concept.
  Future<List<StoryMetadataModel>> getStoryMetadataByCodingConcept(String conceptId) async {
    final allMetadata = await getAllStoryMetadata();
    return allMetadata.where(
      (metadata) => metadata.coversCodingConcept(conceptId)
    ).toList();
  }
  
  /// Get story metadata by age range.
  /// 
  /// [age] is the age to filter by.
  /// Returns a list of story metadata appropriate for the specified age.
  Future<List<StoryMetadataModel>> getStoryMetadataByAge(int age) async {
    final allMetadata = await getAllStoryMetadata();
    return allMetadata.where(
      (metadata) => metadata.isAppropriateForAge(age)
    ).toList();
  }
  
  /// Import a list of stories.
  /// 
  /// [stories] is the list of stories to import.
  /// Returns the number of stories imported.
  Future<int> importStories(List<EnhancedStoryModel> stories) async {
    int count = 0;
    
    for (final story in stories) {
      await saveStory(story);
      count++;
    }
    
    return count;
  }
  
  /// Helper method to update the list of all stories.
  Future<void> _updateStoriesList(String storyId) async {
    final storyIds = await _getStoryIds();
    
    if (!storyIds.contains(storyId)) {
      storyIds.add(storyId);
      await _storage.saveData(_allStoriesKey, storyIds);
    }
  }
  
  /// Helper method to remove a story from the list of all stories.
  Future<void> _removeFromStoriesList(String storyId) async {
    final storyIds = await _getStoryIds();
    
    if (storyIds.contains(storyId)) {
      storyIds.remove(storyId);
      await _storage.saveData(_allStoriesKey, storyIds);
    }
  }
  
  /// Helper method to get the list of all story IDs.
  Future<List<String>> _getStoryIds() async {
    final data = await _storage.getData(_allStoriesKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing story IDs: $e');
      return [];
    }
  }
}
