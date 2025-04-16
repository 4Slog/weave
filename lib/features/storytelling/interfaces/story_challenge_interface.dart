import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';

/// Interface for the storytelling feature to interact with other features
abstract class StoryChallengeInterface {
  /// Called when a challenge is completed
  Future<void> onChallengeCompleted(String storyId, String challengeId, bool success);
  
  /// Get the required block types for a story's challenge
  List<BlockType> getRequiredBlockTypes(String storyId);
  
  /// Get the difficulty level of a story's challenge
  int getChallengeDifficulty(String storyId);
}
