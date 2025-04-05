import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';

/// Interface for the block workspace feature to interact with other features
abstract class ChallengeInterface {
  /// Prepare a challenge with the given ID and required block types
  Future<void> prepareChallenge(String challengeId, List<BlockType> requiredBlockTypes);
  
  /// Validate the current solution
  Future<bool> validateSolution();
  
  /// Get the current challenge ID
  String? getCurrentChallengeId();
}
