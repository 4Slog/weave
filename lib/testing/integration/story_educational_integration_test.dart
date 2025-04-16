import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_progress_model.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider_educational.dart';
import 'package:kente_codeweaver/features/storytelling/services/educational_content_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_generation_service.dart';
import 'package:kente_codeweaver/features/storytelling/repositories/story_repository.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'test_utils.dart';

void main() {
  group('Story Provider and Educational Content Integration Tests', () {
    late StorageService storageService;
    late StoryRepository storyRepository;
    late StoryGenerationService generationService;
    late EducationalContentService educationalService;
    late StoryProviderEducational storyProvider;

    setUp(() {
      // Create a storage service with in-memory storage for testing
      storageService = IntegrationTestUtils.createTestStorageService();

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

      // Create story provider
      storyProvider = StoryProviderEducational(
        repository: storyRepository,
        generationService: generationService,
        educationalService: educationalService,
        storageService: storageService,
      );
    });

    test('Services should initialize successfully', () async {
      // Initialize all components
      await storyRepository.initialize();
      await generationService.initialize();
      await educationalService.initialize();
      await storyProvider.initialize();

      // Verify that components are initialized
      expect(storyProvider.isLoading, isFalse);
      expect(storyProvider.errorMessage, isNull);
    });

    test('Story generation should create stories with educational metadata', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate a story
      final story = await storyProvider.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops'],
      );

      // Verify that the story was created with educational metadata
      expect(story, isNotNull);
      expect(story!.educationalStandards, isNotEmpty);
      expect(story.learningObjectives, isNotEmpty);
      expect(story.prerequisiteConcepts, isNotNull);
      expect(story.skillLevel, greaterThan(0));

      // Verify that the story was added to the provider's stories list
      expect(storyProvider.stories, contains(story));
    });

    test('Educational content service should align stories with standards', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate a story
      final story = await storyProvider.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops'],
      );

      // Define additional standards to align with
      final additionalStandards = ['CSTA-1A-AP-12', 'K12CS-P4.3'];

      // Align the story with additional standards
      final alignedStory = await storyProvider.alignStoryWithStandards(
        story!.id,
        additionalStandards,
      );

      // Verify that the story was aligned with the additional standards
      expect(alignedStory, isNotNull);
      expect(
        alignedStory!.educationalStandards,
        containsAll(additionalStandards),
      );

      // Get the story metadata
      final metadata = await storyProvider.getStoryMetadata(story.id);

      // Verify that the metadata includes the standards alignment
      expect(metadata, isNotNull);
      expect(
        metadata!.standardsAlignment.map((s) => s.standardId),
        containsAll(additionalStandards),
      );
    });

    test('Story provider should generate stories for different learning paths', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate stories for different learning paths
      final logicStory = await storyProvider.generateStoryForLearningPath(
        learningPathType: LearningPathType.logicBased,
        userId: userId,
      );

      final creativityStory = await storyProvider.generateStoryForLearningPath(
        learningPathType: LearningPathType.creativityBased,
        userId: userId,
      );

      final challengeStory = await storyProvider.generateStoryForLearningPath(
        learningPathType: LearningPathType.challengeBased,
        userId: userId,
      );

      // Verify that stories were generated for each learning path
      expect(logicStory, isNotNull);
      expect(creativityStory, isNotNull);
      expect(challengeStory, isNotNull);

      // Verify that the stories have different learning concepts
      expect(logicStory!.learningConcepts, isNot(equals(creativityStory!.learningConcepts)));
      expect(logicStory.learningConcepts, isNot(equals(challengeStory!.learningConcepts)));
      expect(creativityStory.learningConcepts, isNot(equals(challengeStory.learningConcepts)));

      // Verify that the logic-based story includes logical concepts
      expect(
        logicStory.learningConcepts.any((concept) =>
          ['sequences', 'conditionals', 'algorithms'].contains(concept)
        ),
        isTrue,
      );

      // Verify that the creativity-based story includes creative concepts
      expect(
        creativityStory.learningConcepts.any((concept) =>
          ['sequences', 'loops', 'patterns'].contains(concept)
        ),
        isTrue,
      );

      // Verify that the challenge-based story includes advanced concepts
      expect(
        challengeStory.learningConcepts.any((concept) =>
          ['conditionals', 'functions', 'algorithms'].contains(concept)
        ),
        isTrue,
      );
    });

    test('Story provider should create assessment questions for stories', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate a story
      final story = await storyProvider.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops', 'conditionals'],
      );

      // Create assessment questions for the story
      final storyWithQuestions = await storyProvider.createAssessmentQuestions(
        story!.id,
        3, // Create 3 questions
      );

      // Verify that assessment questions were created
      expect(storyWithQuestions, isNotNull);
      expect(storyWithQuestions!.assessmentQuestions, isNotEmpty);
      expect(storyWithQuestions.assessmentQuestions.length, equals(3));

      // Verify that questions cover the story's learning concepts
      final conceptsCovered = storyWithQuestions.assessmentQuestions
          .map((q) => q.conceptAssessed)
          .toSet();

      expect(
        conceptsCovered.any((concept) => story.learningConcepts.contains(concept)),
        isTrue,
      );

      // Verify that each question has the required properties
      for (final question in storyWithQuestions.assessmentQuestions) {
        expect(question.question, isNotEmpty);
        expect(question.options, isNotEmpty);
        expect(question.correctAnswerIndex, lessThan(question.options.length));
        expect(question.explanation, isNotEmpty);
        expect(question.conceptAssessed, isNotEmpty);
      }
    });

    test('Story provider should track story progress', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate a story
      final story = await storyProvider.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops'],
      );

      // Set the current position in the story
      final progress = StoryProgressModel(
        userId: userId,
        storyId: story!.id,
        currentPosition: 3,
        completed: false,
      );
      await storyProvider.saveProgress(progress);

      // Get the progress
      final savedProgress = await storyProvider.getProgress(userId, story.id);

      // Verify that progress was saved
      expect(savedProgress, isNotNull);
      expect(savedProgress!.currentPosition, equals(3));
      expect(savedProgress.completed, isFalse);

      // Mark the story as completed
      await storyProvider.markStoryCompleted(userId, story.id);

      // Get the updated progress
      final updatedProgress = await storyProvider.getProgress(userId, story.id);

      // Verify that the story is marked as completed
      expect(updatedProgress!.completed, isTrue);

      // Get completed stories for the user
      final completedStories = await storyProvider.getCompletedStories(userId);

      // Verify that the story is in the completed stories list
      expect(completedStories, isNotEmpty);
      expect(completedStories.first.id, equals(story.id));
    });

    test('Story provider should recommend stories based on user progress', () async {
      // Initialize all components
      await storyProvider.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Generate multiple stories with different concepts
      final story1 = await storyProvider.generateStory(
        userId: userId,
        theme: 'wisdom',
        learningConcepts: ['sequences', 'loops'],
      );

      final story2 = await storyProvider.generateStory(
        userId: userId,
        theme: 'courage',
        learningConcepts: ['conditionals', 'variables'],
      );

      final story3 = await storyProvider.generateStory(
        userId: userId,
        theme: 'unity',
        learningConcepts: ['functions', 'events'],
      );

      // Mark the first story as completed
      await storyProvider.markStoryCompleted(userId, story1!.id);

      // Get recommended stories for the user
      final recommendedStories = await storyProvider.getRecommendedStories(userId, 2);

      // Verify that recommendations were provided
      expect(recommendedStories, isNotEmpty);
      expect(recommendedStories.length, equals(2));

      // Verify that the completed story is not recommended
      expect(
        recommendedStories.any((s) => s.id == story1.id),
        isFalse,
      );

      // Verify that the other stories are recommended
      expect(
        recommendedStories.any((s) => s.id == story2!.id || s.id == story3!.id),
        isTrue,
      );
    });
  });
}
