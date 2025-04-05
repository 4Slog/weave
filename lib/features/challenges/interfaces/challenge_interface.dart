/// Interface for challenge-related functionality
abstract class ChallengeInterface {
  /// Prepare a challenge
  Future<void> prepareChallenge(String challengeId, List<String> requiredBlockTypes);
  
  /// Validate the current solution
  Future<bool> validateSolution();
  
  /// Get the difficulty level of a challenge
  Future<int> getDifficultyLevel(String challengeId);
  
  /// Check if a challenge is completed
  Future<bool> isChallengeCompleted(String challengeId);
  
  /// Get the required block types for a challenge
  List<String> getRequiredBlockTypes(String challengeId);
  
  /// Get a hint for a challenge
  String getHint(String challengeId);
  
  /// Get the next challenge
  String? getNextChallenge(String currentChallengeId);
  
  /// Reset a challenge
  Future<void> resetChallenge(String challengeId);
}
