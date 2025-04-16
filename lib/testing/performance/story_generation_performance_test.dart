import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_generation_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/educational_content_service.dart';
import 'package:kente_codeweaver/features/storytelling/repositories/story_repository.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../integration/test_utils.dart';
import 'performance_test_utils.dart';

void main() {
  group('Story Generation Performance Tests', () {
    late StorageService storageService;
    late StoryRepository storyRepository;
    late StoryGenerationService generationService;
    late EducationalContentService educationalService;

    setUp(() {
      // Create storage service with in-memory storage for testing
      storageService = PerformanceTestUtils.createTestStorageService();

      // Create repository and services
      storyRepository = StoryRepository(storageService.storage);
      generationService = StoryGenerationService(
        repository: storyRepository,
        storageService: storageService,
      );
      educationalService = EducationalContentService(
        repository: storyRepository,
        storageService: storageService,
      );
    });

    test('Measure story generation performance', () async {
      // Initialize services
      await storyRepository.initialize();
      await generationService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Measure story generation performance
      final generationResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Story Generation',
        function: () async {
          await generationService.generateStory(
            userId: userId,
            theme: 'wisdom',
            learningConcepts: ['sequences', 'loops'],
          );
        },
        iterations: 5,
      );

      // Verify that story generation completes in a reasonable time
      expect(generationResults['averageTime'], lessThan(5000)); // Less than 5 seconds
    });

    test('Compare story generation performance for different learning paths', () async {
      // Initialize services
      await storyRepository.initialize();
      await generationService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Measure logic-based story generation
      final logicResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Logic-Based Story Generation',
        function: () async {
          await generationService.generateStoryForLearningPath(
            learningPathType: LearningPathType.logicBased,
            userId: userId,
          );
        },
        iterations: 3,
      );

      // Measure creativity-based story generation
      final creativityResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Creativity-Based Story Generation',
        function: () async {
          await generationService.generateStoryForLearningPath(
            learningPathType: LearningPathType.creativityBased,
            userId: userId,
          );
        },
        iterations: 3,
      );

      // Measure challenge-based story generation
      final challengeResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Challenge-Based Story Generation',
        function: () async {
          await generationService.generateStoryForLearningPath(
            learningPathType: LearningPathType.challengeBased,
            userId: userId,
          );
        },
        iterations: 3,
      );

      // Compare results
      debugPrint('Logic-based average time: ${logicResults['averageTime']}ms');
      debugPrint('Creativity-based average time: ${creativityResults['averageTime']}ms');
      debugPrint('Challenge-based average time: ${challengeResults['averageTime']}ms');
    });

    test('Measure educational content alignment performance', () async {
      // Initialize services
      await storyRepository.initialize();
      await generationService.initialize();
      await educationalService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate a story
      final story = await generationService.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops'],
      );

      // Measure standards alignment performance
      final standardsResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Standards Alignment',
        function: () async {
          await educationalService.alignStoryWithStandards(
            story,
            ['CSTA-1A-AP-12', 'K12CS-P4.3'],
          );
        },
        iterations: 5,
      );

      // Measure learning objectives addition performance
      final objectivesResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Learning Objectives Addition',
        function: () async {
          await educationalService.addLearningObjectives(
            story,
            ['Create a sequence of instructions', 'Use loops to repeat actions'],
          );
        },
        iterations: 5,
      );

      // Measure assessment questions creation performance
      final questionsResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Assessment Questions Creation',
        function: () async {
          await educationalService.createAssessmentQuestions(
            story,
            3,
          );
        },
        iterations: 5,
      );

      // Compare results
      debugPrint('Standards alignment average time: ${standardsResults['averageTime']}ms');
      debugPrint('Learning objectives addition average time: ${objectivesResults['averageTime']}ms');
      debugPrint('Assessment questions creation average time: ${questionsResults['averageTime']}ms');

      // Verify that operations complete in a reasonable time
      expect(standardsResults['averageTime'], lessThan(1000)); // Less than 1 second
      expect(objectivesResults['averageTime'], lessThan(1000)); // Less than 1 second
      expect(questionsResults['averageTime'], lessThan(1000)); // Less than 1 second
    });

    test('Measure story recommendation performance', () async {
      // Initialize services
      await storyRepository.initialize();
      await generationService.initialize();
      await educationalService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate multiple stories
      for (int i = 0; i < 10; i++) {
        await generationService.generateStory(
          userId: userId,
          theme: 'wisdom',
          learningConcepts: ['sequences', 'loops'],
        );
      }

      // Measure recommendation performance
      final recommendationResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Story Recommendation',
        function: () async {
          await educationalService.getRecommendedStories(userId, 3);
        },
        iterations: 10,
      );

      // Verify that recommendation completes in a reasonable time
      expect(recommendationResults['averageTime'], lessThan(500)); // Less than 500ms
    });
  });
}
