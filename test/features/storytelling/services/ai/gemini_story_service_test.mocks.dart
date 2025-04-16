// Mock implementation of the required classes
// This is a temporary solution until we can generate the proper mocks with mockito

import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/story_cache_service.dart';
import 'package:mockito/mockito.dart';

class MockStorageService extends Mock implements StorageService {
  @override
  Future<void> saveProgress(String key, String data) async {}
  
  @override
  Future<String?> getProgress(String key) async => null;
  
  @override
  Future<void> removeProgress(String key) async {}
  
  @override
  Future<List<String>> getAllKeys() async => [];
}

class MockEnhancedCulturalDataService extends Mock implements EnhancedCulturalDataService {
  @override
  Future<Map<String, dynamic>> getRandomCulturalInfo() async => {
    'description': 'Test cultural info'
  };
}

class MockStoryCacheService extends Mock implements StoryCacheService {
  @override
  Future<StoryModel?> getCachedStory(String cacheKey) async => null;
  
  @override
  Future<void> cacheStory(String cacheKey, StoryModel story) async {}
  
  @override
  Future<List<StoryBranchModel>?> getCachedBranches(String cacheKey) async => null;
  
  @override
  Future<void> cacheBranches(String cacheKey, List<StoryBranchModel> branches) async {}
}
