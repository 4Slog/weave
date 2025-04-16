import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/challenges/services/challenge_service_refactored.dart';
import 'package:kente_codeweaver/features/engagement/services/engagement_service_refactored.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/challenges/models/validation_result.dart';
import '../integration/test_utils.dart';
import 'performance_test_utils.dart';

void main() {
  group('Challenge and Engagement Performance Tests', () {
    late StorageService storageService;
    late ChallengeServiceRefactored challengeService;
    late EngagementServiceRefactored engagementService;

    setUp(() {
      // Create storage service with in-memory storage for testing
      storageService = PerformanceTestUtils.createTestStorageService();

      // Create services
      challengeService = ChallengeServiceRefactored();

      engagementService = EngagementServiceRefactored(
        storageService: storageService,
      );
    });

    test('Measure challenge generation performance', () async {
      // Initialize services
      await challengeService.initialize();

      // Create test user progress
      final userProgress = IntegrationTestUtils.createTestUserProgress();

      // Measure challenge generation performance
      final generationResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Challenge Generation',
        function: () async {
          await challengeService.getChallenge(
            userProgress: userProgress,
            challengeType: 'pattern',
          );
        },
        iterations: 10,
      );

      // Verify that challenge generation completes in a reasonable time
      expect(generationResults['averageTime'], lessThan(500)); // Less than 500ms
    });

    test('Measure challenge validation performance', () async {
      // Initialize services
      await challengeService.initialize();

      // Create test user progress
      final userProgress = IntegrationTestUtils.createTestUserProgress();

      // Get a challenge
      final challenge = await challengeService.getChallenge(
        userProgress: userProgress,
        challengeType: 'pattern',
      );

      // Create a mock solution
      final blockCollection = BlockCollection(blocks: []);
      final solution = PatternModel(
        id: 'test_solution',
        userId: 'test_user',
        name: 'Test Solution',
        blockCollection: blockCollection,
      );

      // Measure validation performance
      final validationResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Challenge Validation',
        function: () async {
          await challengeService.validateSolution(
            challenge: challenge,
            solution: solution,
            userId: userProgress.userId,
          );
        },
        iterations: 20,
      );

      // Verify that validation completes in a reasonable time
      expect(validationResults['averageTime'], lessThan(200)); // Less than 200ms
    });

    test('Measure engagement tracking performance', () async {
      // Initialize services
      await engagementService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Measure event tracking performance
      final trackingResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Engagement Event Tracking',
        function: () async {
          await engagementService.trackChallengeAttempt(
            userId: userId,
            challengeId: 'test_challenge',
            success: true,
            details: {
              'time_spent_seconds': 60,
              'screen': 'test_screen',
            },
            concepts: ['sequences', 'loops'],
          );
        },
        iterations: 50,
      );

      // Verify that event tracking completes in a reasonable time
      expect(trackingResults['averageTime'], lessThan(100)); // Less than 100ms
    });

    test('Measure engagement metrics calculation performance', () async {
      // Initialize services
      await engagementService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Track multiple events
      for (int i = 0; i < 100; i++) {
        await engagementService.trackChallengeAttempt(
          userId: userId,
          challengeId: 'test_event_$i',
          success: i % 2 == 0,
          details: {
            'time_spent_seconds': 60,
            'screen': 'test_screen',
            'index': i,
          },
          concepts: ['sequences'],
        );
      }

      // Measure metrics calculation performance
      final metricsResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Engagement Metrics Calculation',
        function: () async {
          await engagementService.getEngagementMetrics(userId);
        },
        iterations: 10,
      );

      // Measure score calculation performance
      final scoreResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Engagement Score Calculation',
        function: () async {
          await engagementService.getEngagementScore(userId);
        },
        iterations: 10,
      );

      // Verify that calculations complete in a reasonable time
      expect(metricsResults['averageTime'], lessThan(500)); // Less than 500ms
      expect(scoreResults['averageTime'], lessThan(200)); // Less than 200ms
    });

    test('Measure educational metrics calculation performance', () async {
      // Initialize services
      await engagementService.initialize();

      // Create test user ID
      final userId = IntegrationTestUtils.createTestUserId();

      // Track multiple events with educational context
      for (int i = 0; i < 50; i++) {
        await engagementService.trackChallengeAttempt(
          userId: userId,
          challengeId: i % 2 == 0 ? 'story_view_$i' : 'challenge_complete_$i',
          success: true,
          details: {
            'time_spent_seconds': 60,
            'index': i,
          },
          concepts: ['sequences', 'loops'],
        );
      }

      // Measure educational metrics calculation performance
      final educationalMetricsResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'Educational Metrics Calculation',
        function: () async {
          await engagementService.getEducationalMetrics(userId);
        },
        iterations: 10,
      );

      // Verify that calculation completes in a reasonable time
      expect(educationalMetricsResults['averageTime'], lessThan(500)); // Less than 500ms
    });

    test('Measure user progress update performance', () async {
      // Initialize services
      await challengeService.initialize();
      await engagementService.initialize();

      // Create test user progress
      final userProgress = IntegrationTestUtils.createTestUserProgress();

      // Get a challenge
      final challenge = await challengeService.getChallenge(
        userProgress: userProgress,
        challengeType: 'pattern',
      );

      // Create a mock solution
      final blockCollection = BlockCollection(blocks: []);
      final solution = PatternModel(
        id: 'test_solution',
        userId: 'test_user',
        name: 'Test Solution',
        blockCollection: blockCollection,
      );

      // Create a proper ValidationResult
      final feedback = ValidationFeedback(
        title: 'Success',
        message: 'Great job!',
        suggestions: [],
      );

      final assessment = SolutionAssessment(
        achievementLevel: 'advanced',
        pointsEarned: 100,
      );

      final validationResult = ValidationResult(
        success: true,
        challenge: challenge,
        solution: solution,
        feedback: feedback,
        assessment: assessment,
      );

      // Measure progress update performance
      final progressUpdateResults = await PerformanceTestUtils.runPerformanceTest(
        name: 'User Progress Update',
        function: () async {
          await challengeService.updateProgressForChallenge(
            userProgress: userProgress,
            challenge: challenge,
            validationResult: validationResult,
          );
        },
        iterations: 10,
      );

      // Verify that progress update completes in a reasonable time
      expect(progressUpdateResults['averageTime'], lessThan(200)); // Less than 200ms
    });
  });
}
