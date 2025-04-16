import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/block_workspace/interfaces/challenge_interface.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';
import 'package:kente_codeweaver/features/block_workspace/services/challenge_service.dart';

/// Implementation of the ChallengeInterface for the block workspace feature
class ChallengeServiceImpl implements ChallengeInterface {
  final BlockProvider _blockProvider;
  final ChallengeService _challengeService;

  String? _currentChallengeId;

  ChallengeServiceImpl({
    required BlockProvider blockProvider,
    required ChallengeService challengeService,
  }) :
    _blockProvider = blockProvider,
    _challengeService = challengeService;

  @override
  Future<void> prepareChallenge(String challengeId, List<BlockType> requiredBlockTypes) async {
    // Set the current challenge ID
    _currentChallengeId = challengeId;

    // Set available block types in provider
    _blockProvider.setAvailableBlockTypes(requiredBlockTypes);

    // Load challenge data
    final challengeData = await _challengeService.getChallengeData(challengeId);

    // Clear existing blocks
    _blockProvider.clearBlocks();

    // Initialize workspace with challenge-specific settings
    await _blockProvider.initialize(
      'current_user',
      'workspace_$challengeId',
    );

    // If the challenge has a template, load it
    if (challengeData != null && challengeData.containsKey('templateId')) {
      final templateId = challengeData['templateId'] as String;
      await _blockProvider.loadTemplate(templateId);
    }

    debugPrint('Challenge $challengeId prepared with ${requiredBlockTypes.length} block types');
  }

  @override
  Future<bool> validateSolution() async {
    if (_currentChallengeId == null) {
      debugPrint('No active challenge to validate');
      return false;
    }

    // Get challenge requirements
    final challengeData = await _challengeService.getChallengeData(_currentChallengeId!);
    if (challengeData == null) {
      debugPrint('Challenge data not found for $_currentChallengeId');
      return false;
    }

    // Check if the pattern meets the requirements
    final requirements = challengeData['requirements'] as Map<String, dynamic>? ?? {};
    final isValid = _blockProvider.patternMeetsRequirements(requirements);

    debugPrint('Challenge $_currentChallengeId validation result: $isValid');
    return isValid;
  }

  @override
  String? getCurrentChallengeId() {
    return _currentChallengeId;
  }
}
