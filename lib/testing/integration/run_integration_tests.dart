import 'package:flutter_test/flutter_test.dart';
import 'storage_repository_integration_test.dart' as storage_repository_test;
import 'challenge_engagement_integration_test.dart' as challenge_engagement_test;
import 'story_educational_integration_test.dart' as story_educational_test;
import 'end_to_end_user_journey_test.dart' as end_to_end_test;

/// Main entry point for running all integration tests.
void main() {
  group('Integration Tests', () {
    group('Storage and Repository Integration Tests', () {
      storage_repository_test.main();
    });
    
    group('Challenge and Engagement Integration Tests', () {
      challenge_engagement_test.main();
    });
    
    group('Story and Educational Content Integration Tests', () {
      story_educational_test.main();
    });
    
    group('End-to-End User Journey Tests', () {
      end_to_end_test.main();
    });
  });
}
