import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/ai/story_cache_service.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural/services/cultural_data_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Import the mock implementations
import 'gemini_story_service_test.mocks.dart';

@GenerateMocks([StorageService, EnhancedCulturalDataService, StoryCacheService])
void main() {
  group('GeminiStoryService', () {
    late GeminiStoryService storyService;
    late MockStorageService mockStorageService;
    late MockEnhancedCulturalDataService mockCulturalDataService;
    late MockStoryCacheService mockCacheService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCulturalDataService = MockEnhancedCulturalDataService();
      mockCacheService = MockStoryCacheService();

      storyService = GeminiStoryService(
        storageService: mockStorageService,
        culturalDataService: mockCulturalDataService,
        cacheService: mockCacheService,
      );
    });

    test('generateStory returns cached story when available', () async {
      // Arrange
      final userProgress = UserProgress(
        userId: 'test_user',
        name: 'Test User',
        level: 1,
        conceptsMastered: ['loops'],
        conceptsInProgress: ['conditionals'],
      );

      final learningConcepts = ['loops', 'conditionals'];
      final cacheKey = 'story_${userProgress.userId}_${learningConcepts.join('_')}_${EmotionalTone.neutral.name}';

      final cachedStory = StoryModel(
        title: 'Cached Story',
        theme: 'cultural',
        region: 'Ghana',
        characterName: 'Kofi',
        ageGroup: '7-15',
        content: [],
      );

      when(mockCacheService.getCachedStory(cacheKey))
          .thenAnswer((_) async => cachedStory);

      // Act
      final result = await storyService.generateStory(
        userProgress: userProgress,
        learningConcepts: learningConcepts,
      );

      // Assert
      expect(result, equals(cachedStory));
      verify(mockCacheService.getCachedStory(cacheKey)).called(1);
      verifyNoMoreInteractions(mockCacheService);
    });

    test('generateStory returns default story when offline', () async {
      // Arrange
      final userProgress = UserProgress(
        userId: 'test_user',
        name: 'Test User',
        level: 1,
        conceptsMastered: ['loops'],
        conceptsInProgress: ['conditionals'],
      );

      final learningConcepts = ['loops', 'conditionals'];
      final cacheKey = 'story_${userProgress.userId}_${learningConcepts.join('_')}_${EmotionalTone.neutral.name}';

      when(mockCacheService.getCachedStory(cacheKey))
          .thenAnswer((_) async => null);

      // Set service to offline mode
      storyService.setOfflineMode(true);

      // Act
      final result = await storyService.generateStory(
        userProgress: userProgress,
        learningConcepts: learningConcepts,
      );

      // Assert
      expect(result, isA<StoryModel>());
      expect(result.title, contains('Kente Weaver'));
      verify(mockCacheService.getCachedStory(cacheKey)).called(1);
    });

    test('generateEnhancedStory returns cached story when available', () async {
      // Arrange
      final userProgress = UserProgress(
        userId: 'test_user',
        name: 'Test User',
        level: 1,
        conceptsMastered: ['loops'],
        conceptsInProgress: ['conditionals'],
      );

      final theme = 'cultural';
      final skillLevel = SkillLevel.beginner;
      final cacheKey = 'enhanced_story_${theme}_${skillLevel.toString().split('.').last}_default';

      final cachedStory = StoryModel(
        title: 'Cached Enhanced Story',
        theme: 'cultural',
        region: 'Ghana',
        characterName: 'Kofi',
        ageGroup: '7-15',
        content: [],
      );

      when(mockCacheService.getCachedStory(cacheKey))
          .thenAnswer((_) async => cachedStory);

      // Act
      final result = await storyService.generateEnhancedStory(
        skillLevel: skillLevel,
        theme: theme,
        userProgress: userProgress,
      );

      // Assert
      expect(result, equals(cachedStory));
      verify(mockCacheService.getCachedStory(cacheKey)).called(1);
      verifyNoMoreInteractions(mockCacheService);
    });

    test('generateStoryBranches returns cached branches when available', () async {
      // Arrange
      final userProgress = UserProgress(
        userId: 'test_user',
        name: 'Test User',
        level: 1,
        conceptsMastered: ['loops'],
        conceptsInProgress: ['conditionals'],
      );

      final parentStory = StoryModel(
        id: 'test_story',
        title: 'Test Story',
        theme: 'cultural',
        region: 'Ghana',
        characterName: 'Kofi',
        ageGroup: '7-15',
        content: [],
      );

      final cacheKey = 'branches_${parentStory.id}_2';
      final cachedBranches = [
        StoryBranchModel(
          description: 'Branch 1',
          targetStoryId: 'target_1',
          choiceText: 'Choice 1',
          content: 'Content 1',
        ),
        StoryBranchModel(
          description: 'Branch 2',
          targetStoryId: 'target_2',
          choiceText: 'Choice 2',
          content: 'Content 2',
        ),
      ];

      when(mockCacheService.getCachedBranches(cacheKey))
          .thenAnswer((_) async => cachedBranches);

      // Act
      final result = await storyService.generateStoryBranches(
        parentStory: parentStory,
        userProgress: userProgress,
      );

      // Assert
      expect(result, equals(cachedBranches));
      verify(mockCacheService.getCachedBranches(cacheKey)).called(1);
      verifyNoMoreInteractions(mockCacheService);
    });
  });
}
