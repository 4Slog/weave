import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/storytelling/repositories/story_repository.dart';
import '../integration/test_utils.dart';
import 'performance_test_utils.dart';

void main() {
  group('Storage Performance Tests', () {
    late StorageService storageService;

    setUp(() {
      // Create storage service
      storageService = PerformanceTestUtils.createTestStorageService();
    });

    test('Measure storage service performance for saving user progress', () async {
      // Test storage service
      final results = await PerformanceTestUtils.runPerformanceTest(
        name: 'Storage Service - Save User Progress',
        function: () async {
          final userProgress = IntegrationTestUtils.createTestUserProgress(
            userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
          );
          await storageService.saveUserProgress(userProgress);
        },
        iterations: 50,
      );

      // Verify performance is reasonable
      expect(results['averageTime'], lessThan(500)); // Less than 500ms
    });

    test('Measure storage service performance for retrieving user progress', () async {
      // Create and save test user progress
      final userId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      final userProgress = IntegrationTestUtils.createTestUserProgress(
        userId: userId,
      );
      await storageService.saveUserProgress(userProgress);

      // Test storage service
      final results = await PerformanceTestUtils.runPerformanceTest(
        name: 'Storage Service - Get User Progress',
        function: () async {
          await storageService.getUserProgress(userId);
        },
        iterations: 50,
      );

      // Verify performance is reasonable
      expect(results['averageTime'], lessThan(500)); // Less than 500ms
    });

    test('Measure repository performance with caching', () async {
      // Create repository
      final repository = StoryRepository(storageService.storage);
      await repository.initialize();

      // Create test story
      final testStory = IntegrationTestUtils.createTestStory();

      // Save the story
      await repository.saveStory(testStory);

      // Measure first retrieval (no cache)
      final firstRetrievalResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Story Repository - First Retrieval',
        function: () async {
          await repository.getStory(testStory.id);
        },
        iterations: 1,
      );

      // Measure subsequent retrievals (with cache)
      final cachedRetrievalResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Story Repository - Cached Retrieval',
        function: () async {
          await repository.getStory(testStory.id);
        },
        iterations: 50,
      );

      // Compare results
      expect(cachedRetrievalResults['averageTime'], lessThan(firstRetrievalResults['averageTime']));
    });

    test('Measure bulk operation performance', () async {
      // Create repository
      final repository = StoryRepository(storageService.storage);
      await repository.initialize();

      // Create test stories
      final testStories = List.generate(20, (index) =>
        IntegrationTestUtils.createTestStory(
          title: 'Test Story $index',
        )
      );

      // Measure bulk save performance
      final bulkSaveResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Repository - Bulk Save Stories',
        function: () async {
          for (final story in testStories.sublist(0, 5)) {
            await repository.saveStory(story);
          }
        },
        iterations: 5,
      );

      // Measure get all stories performance
      final getAllResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Repository - Get All Stories',
        function: () async {
          await repository.getAllStories();
        },
        iterations: 10,
      );

      // Verify that operations complete in a reasonable time
      expect(bulkSaveResults['averageTime'], lessThan(1000)); // Less than 1 second
      expect(getAllResults['averageTime'], lessThan(1000)); // Less than 1 second
    });
  });
}
