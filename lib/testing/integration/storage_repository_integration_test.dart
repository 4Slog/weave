import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/storytelling/models/enhanced_story_model.dart';
import 'package:kente_codeweaver/features/challenges/models/challenge_model.dart';
import 'package:kente_codeweaver/features/engagement/models/engagement_event.dart';
import 'package:kente_codeweaver/features/storytelling/repositories/story_repository.dart';
import 'package:kente_codeweaver/features/challenges/repositories/challenge_repository.dart';
import 'package:kente_codeweaver/features/engagement/repositories/engagement_repository.dart';
import 'test_utils.dart';

void main() {
  group('Storage and Repository Integration Tests', () {
    late StorageService storageService;
    late StoryRepository storyRepository;
    late ChallengeRepository challengeRepository;
    late EngagementRepository engagementRepository;

    setUp(() {
      // Create a storage service with in-memory storage for testing
      storageService = IntegrationTestUtils.createTestStorageService();

      // Create repositories using the same storage service
      storyRepository = StoryRepository(storageService.storage);
      challengeRepository = ChallengeRepository(storageService.storage);
      engagementRepository = EngagementRepository(storageService.storage);
    });

    test('Repositories should initialize successfully', () async {
      // Initialize all repositories
      await storyRepository.initialize();
      await challengeRepository.initialize();
      await engagementRepository.initialize();

      // Verify that all repositories are initialized
      expect(storyRepository.storage, equals(storageService.storage));
      expect(challengeRepository.storage, equals(storageService.storage));
      expect(engagementRepository.storage, equals(storageService.storage));
    });

    test('Story repository should save and retrieve stories', () async {
      // Initialize repository
      await storyRepository.initialize();

      // Create a test story
      final testStory = IntegrationTestUtils.createTestStory();

      // Save the story
      await storyRepository.saveStory(testStory);

      // Retrieve the story
      final retrievedStory = await storyRepository.getStory(testStory.id);

      // Verify that the retrieved story matches the original
      expect(retrievedStory, isNotNull);
      expect(retrievedStory!.id, equals(testStory.id));
      expect(retrievedStory.title, equals(testStory.title));
      expect(retrievedStory.theme, equals(testStory.theme));
      expect(retrievedStory.learningConcepts, equals(testStory.learningConcepts));
    });

    test('Challenge repository should save and retrieve challenges', () async {
      // Initialize repository
      await challengeRepository.initialize();

      // Create a test challenge
      final testChallenge = IntegrationTestUtils.createTestChallenge();

      // Save the challenge
      await challengeRepository.saveChallenge(testChallenge);

      // Retrieve the challenge
      final retrievedChallenge = await challengeRepository.getChallenge(testChallenge.id);

      // Verify that the retrieved challenge matches the original
      expect(retrievedChallenge, isNotNull);
      expect(retrievedChallenge!.id, equals(testChallenge.id));
      expect(retrievedChallenge.title, equals(testChallenge.title));
      expect(retrievedChallenge.type, equals(testChallenge.type));
      expect(retrievedChallenge.requiredConcepts, equals(testChallenge.requiredConcepts));
    });

    test('Engagement repository should save and retrieve events', () async {
      // Initialize repository
      await engagementRepository.initialize();

      // Create a test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Create a test engagement event
      final testEvent = IntegrationTestUtils.createTestEngagementEvent(
        userId: userId,
        eventType: 'test_event',
      );

      // Save the event
      await engagementRepository.saveEvent(testEvent);

      // Retrieve recent events
      final recentEvents = await engagementRepository.getRecentEvents(userId);

      // Verify that the event was saved and retrieved
      expect(recentEvents, isNotEmpty);
      expect(recentEvents.first.id, equals(testEvent.id));
      expect(recentEvents.first.eventType, equals(testEvent.eventType));
      expect(recentEvents.first.userId, equals(userId));
    });

    test('Multiple repositories should work with the same storage', () async {
      // Initialize all repositories
      await storyRepository.initialize();
      await challengeRepository.initialize();
      await engagementRepository.initialize();

      // Create test data
      final userId = IntegrationTestUtils.createTestUserId();
      final testStory = IntegrationTestUtils.createTestStory();
      final testChallenge = IntegrationTestUtils.createTestChallenge();
      final testEvent = IntegrationTestUtils.createTestEngagementEvent(
        userId: userId,
        eventType: 'story_view',
        details: {
          'story_id': testStory.id,
          'challenge_id': testChallenge.id,
        },
      );

      // Save data to all repositories
      await storyRepository.saveStory(testStory);
      await challengeRepository.saveChallenge(testChallenge);
      await engagementRepository.saveEvent(testEvent);

      // Retrieve data from all repositories
      final retrievedStory = await storyRepository.getStory(testStory.id);
      final retrievedChallenge = await challengeRepository.getChallenge(testChallenge.id);
      final recentEvents = await engagementRepository.getRecentEvents(userId);

      // Verify that all data was saved and retrieved correctly
      expect(retrievedStory, isNotNull);
      expect(retrievedChallenge, isNotNull);
      expect(recentEvents, isNotEmpty);

      // Verify that the event references the story and challenge
      expect(recentEvents.first.details['story_id'], equals(testStory.id));
      expect(recentEvents.first.details['challenge_id'], equals(testChallenge.id));
    });

    test('Storage service should handle concurrent access from multiple repositories', () async {
      // Initialize all repositories
      await storyRepository.initialize();
      await challengeRepository.initialize();
      await engagementRepository.initialize();

      // Create test data
      final userId = IntegrationTestUtils.createTestUserId();
      final testStories = List.generate(5, (index) =>
        IntegrationTestUtils.createTestStory(
          title: 'Test Story $index',
        )
      );
      final testChallenges = List.generate(5, (index) =>
        IntegrationTestUtils.createTestChallenge(
          title: 'Test Challenge $index',
        )
      );

      // Save data concurrently
      await Future.wait([
        ...testStories.map((story) => storyRepository.saveStory(story)),
        ...testChallenges.map((challenge) => challengeRepository.saveChallenge(challenge)),
      ]);

      // Create events referencing the saved data
      final testEvents = List.generate(10, (index) =>
        IntegrationTestUtils.createTestEngagementEvent(
          userId: userId,
          eventType: index % 2 == 0 ? 'story_view' : 'challenge_attempt',
          details: {
            if (index % 2 == 0) 'story_id': testStories[index ~/ 2].id,
            if (index % 2 == 1) 'challenge_id': testChallenges[index ~/ 2].id,
          },
        )
      );

      // Save events concurrently
      await Future.wait(
        testEvents.map((event) => engagementRepository.saveEvent(event))
      );

      // Retrieve all data
      final allStories = await storyRepository.getAllStories();
      final allChallenges = await challengeRepository.getAllChallenges();
      final recentEvents = await engagementRepository.getRecentEvents(userId, limit: 20);

      // Verify that all data was saved and retrieved correctly
      expect(allStories.length, equals(testStories.length));
      expect(allChallenges.length, equals(testChallenges.length));
      expect(recentEvents.length, equals(testEvents.length));
    });
  });
}
