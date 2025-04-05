import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/challenges/interfaces/challenge_interface.dart';

/// Implementation of the ChallengeInterface
class ChallengeServiceImpl implements ChallengeInterface {
  /// Block provider
  final BlockProvider _blockProvider;

  /// Learning provider
  final LearningProvider _learningProvider;

  /// Current challenge ID
  String? _currentChallengeId;

  /// Required block types
  List<String> _requiredBlockTypes = [];

  /// Constructor
  ChallengeServiceImpl({
    required BlockProvider blockProvider,
    required LearningProvider learningProvider,
  })  : _blockProvider = blockProvider,
        _learningProvider = learningProvider;

  /// Factory constructor to create from BuildContext
  factory ChallengeServiceImpl.fromContext(BuildContext context) {
    return ChallengeServiceImpl(
      blockProvider: Provider.of<BlockProvider>(context, listen: false),
      learningProvider: Provider.of<LearningProvider>(context, listen: false),
    );
  }

  @override
  Future<void> prepareChallenge(String challengeId, List<String> requiredBlockTypes) async {
    _currentChallengeId = challengeId;
    _requiredBlockTypes = List<String>.from(requiredBlockTypes);

    // Initialize block provider with user ID and workspace ID
    await _blockProvider.initialize('current_user', challengeId);

    // Clear existing blocks
    _blockProvider.clearBlocks();
  }

  @override
  Future<bool> validateSolution() async {
    if (_currentChallengeId == null) {
      return false;
    }

    // Check if all required block types are present
    for (final blockType in _requiredBlockTypes) {
      if (!_blockProvider.hasBlockType(blockType)) {
        return false;
      }
    }

    // Check if blocks are connected properly
    // For now, just check if there's at least one connection
    final blocks = _blockProvider.blocks;
    bool hasConnection = false;

    for (final block in blocks) {
      if (block.connections.isNotEmpty) {
        hasConnection = true;
        break;
      }
    }

    return hasConnection;
  }

  @override
  Future<int> getDifficultyLevel(String challengeId) async {
    // For now, return mock data
    switch (challengeId) {
      case 'challenge_001':
        return 1;
      case 'challenge_002':
        return 1;
      case 'challenge_003':
        return 2;
      case 'challenge_004':
        return 2;
      case 'challenge_005':
        return 2;
      case 'challenge_006':
        return 3;
      case 'challenge_007':
        return 3;
      case 'challenge_008':
        return 3;
      case 'challenge_009':
        return 3;
      default:
        return 1;
    }
  }

  @override
  Future<bool> isChallengeCompleted(String challengeId) async {
    return _learningProvider.isChallengeCompleted(challengeId);
  }

  @override
  List<String> getRequiredBlockTypes(String challengeId) {
    // For now, return mock data
    switch (challengeId) {
      case 'challenge_001':
        return ['start', 'action', 'end'];
      case 'challenge_002':
        return ['start', 'action', 'end'];
      case 'challenge_003':
        return ['start', 'condition', 'action', 'end'];
      case 'challenge_004':
        return ['start', 'condition', 'action', 'end'];
      case 'challenge_005':
        return ['start', 'condition', 'action', 'end'];
      case 'challenge_006':
        return ['start', 'loop', 'action', 'end'];
      case 'challenge_007':
        return ['start', 'loop', 'action', 'end'];
      case 'challenge_008':
        return ['start', 'loop', 'condition', 'action', 'end'];
      case 'challenge_009':
        return ['start', 'loop', 'condition', 'action', 'end'];
      default:
        return ['start', 'action', 'end'];
    }
  }

  @override
  String getHint(String challengeId) {
    // For now, return mock data
    switch (challengeId) {
      case 'challenge_001':
        return 'Try connecting the start block to the action block, then to the end block.';
      case 'challenge_002':
        return 'Try connecting the start block to the action block, then to the end block.';
      case 'challenge_003':
        return 'Use a condition block to check if a value is true or false.';
      case 'challenge_004':
        return 'Use a condition block to check if a value is true or false.';
      case 'challenge_005':
        return 'Use a condition block to check if a value is true or false.';
      case 'challenge_006':
        return 'Use a loop block to repeat an action multiple times.';
      case 'challenge_007':
        return 'Use a loop block to repeat an action multiple times.';
      case 'challenge_008':
        return 'Use a loop block with a condition to repeat an action until a condition is met.';
      case 'challenge_009':
        return 'Use a loop block with a condition to repeat an action until a condition is met.';
      default:
        return 'Connect the blocks in a logical sequence.';
    }
  }

  @override
  String? getNextChallenge(String currentChallengeId) {
    // For now, return mock data
    switch (currentChallengeId) {
      case 'challenge_001':
        return 'challenge_002';
      case 'challenge_002':
        return 'challenge_003';
      case 'challenge_003':
        return 'challenge_004';
      case 'challenge_004':
        return 'challenge_005';
      case 'challenge_005':
        return 'challenge_006';
      case 'challenge_006':
        return 'challenge_007';
      case 'challenge_007':
        return 'challenge_008';
      case 'challenge_008':
        return 'challenge_009';
      case 'challenge_009':
        return null;
      default:
        return null;
    }
  }

  @override
  Future<void> resetChallenge(String challengeId) async {
    if (_currentChallengeId == challengeId) {
      // Clear existing blocks
      _blockProvider.clearBlocks();
    }
  }
}
