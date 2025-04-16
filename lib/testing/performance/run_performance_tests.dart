import 'package:flutter_test/flutter_test.dart';
import 'storage_performance_test.dart' as storage_performance_test;
import 'story_generation_performance_test.dart' as story_generation_performance_test;
import 'challenge_engagement_performance_test.dart' as challenge_engagement_performance_test;

/// Main entry point for running all performance tests.
void main() {
  group('Performance Tests', () {
    group('Storage Performance Tests', () {
      storage_performance_test.main();
    });
    
    group('Story Generation Performance Tests', () {
      story_generation_performance_test.main();
    });
    
    group('Challenge and Engagement Performance Tests', () {
      challenge_engagement_performance_test.main();
    });
  });
}
