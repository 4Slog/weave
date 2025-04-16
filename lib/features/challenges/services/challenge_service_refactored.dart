import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import '../models/challenge_model.dart';
import '../models/validation_result.dart';
import '../repositories/challenge_repository.dart';
import '../generators/challenge_generator.dart';
import '../validators/challenge_validator.dart';
import '../validators/pattern_challenge_validator.dart';
import '../validators/sequence_challenge_validator.dart';

/// Enhanced service for challenge generation, validation, and assessment.
///
/// This service provides improved challenge generation based on educational standards,
/// better validation for solutions, more sophisticated feedback mechanisms,
/// and educational assessment.
class ChallengeServiceRefactored {
  /// Repository for challenge data
  final ChallengeRepository _challengeRepository;

  /// Generator for creating challenges
  final ChallengeGenerator _challengeGenerator;

  /// Validators for different challenge types
  final List<ChallengeValidator> _validators;

  /// Adaptive learning service for skill assessment
  final AdaptiveLearningService _adaptiveLearningService;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new ChallengeServiceRefactored with optional dependencies
  ChallengeServiceRefactored({
    ChallengeRepository? challengeRepository,
    ChallengeGenerator? challengeGenerator,
    List<ChallengeValidator>? validators,
    AdaptiveLearningService? adaptiveLearningService,

  }) :
    _challengeRepository = challengeRepository ?? ChallengeRepository(StorageService().storage),
    _challengeGenerator = challengeGenerator ?? ChallengeGenerator(),
    _validators = validators ?? [
      PatternChallengeValidator(),
      SequenceChallengeValidator(),
    ],
    _adaptiveLearningService = adaptiveLearningService ?? AdaptiveLearningService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the repository
      await _challengeRepository.initialize();

      // Initialize the adaptive learning service
      await _adaptiveLearningService.initialize();

      _isInitialized = true;
      debugPrint('ChallengeServiceRefactored initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ChallengeServiceRefactored: $e');
      throw Exception('Failed to initialize ChallengeServiceRefactored: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get a challenge based on user progress
  ///
  /// [userProgress] is the user's current progress
  /// [challengeType] is the type of challenge to generate (e.g., 'pattern', 'sequence')
  /// [difficultyOverride] is an optional override for difficulty level
  /// [learningPathType] is an optional learning path type to consider
  /// [frustrationLevel] is an optional frustration level to consider for dynamic difficulty adjustment
  /// [targetConcept] is an optional specific concept to focus on
  ///
  /// Returns a challenge appropriate for the user
  Future<ChallengeModel> getChallenge({
    required UserProgress userProgress,
    String? challengeType,
    int? difficultyOverride,
    LearningPathType? learningPathType,
    double? frustrationLevel,
    String? targetConcept,
  }) async {
    await _ensureInitialized();

    // Get difficulty level based on user progress or override, considering learning path and frustration
    final difficultyLevel = difficultyOverride ??
        await _adaptiveLearningService.calculateDifficultyLevel(
          userProgress: userProgress,
          learningPathType: learningPathType,
          conceptId: targetConcept,
          frustrationLevel: frustrationLevel,
        );

    // Try to get a challenge from the repository
    ChallengeModel? challenge;

    if (targetConcept != null) {
      // If a target concept is specified, get challenges for that concept
      final conceptChallenges = await _challengeGenerator.generateChallengesForConcept(
        targetConcept,
        userId: userProgress.userId,
        count: 1,
      );

      if (conceptChallenges.isNotEmpty) {
        challenge = conceptChallenges.first;
      }
    } else if (challengeType != null) {
      // If a challenge type is specified, get challenges of that type
      final typeChallenges = await _challengeRepository.getChallengesByType(challengeType);

      // Filter by difficulty
      final difficultyFiltered = typeChallenges
          .where((c) => (c.difficulty - difficultyLevel).abs() <= 1)
          .toList();

      // Filter out completed challenges
      final completedChallenges = await _challengeRepository.getCompletedChallenges(userProgress.userId);
      final completedIds = completedChallenges.map((c) => c.id).toSet();

      final uncompletedChallenges = difficultyFiltered
          .where((c) => !completedIds.contains(c.id))
          .toList();

      if (uncompletedChallenges.isNotEmpty) {
        challenge = uncompletedChallenges.first;
      } else if (difficultyFiltered.isNotEmpty) {
        challenge = difficultyFiltered.first;
      }
    }

    // If no challenge was found, generate one for the user
    challenge ??= await _challengeGenerator.generateChallengeForUser(
      userProgress.userId,
      preferredType: challengeType,
      preferredDifficulty: difficultyLevel,
      preferredLearningPathType: learningPathType,
    );

    // If still no challenge, create a default one
    challenge ??= _createDefaultChallenge(
      challengeType: challengeType ?? 'pattern',
      difficultyLevel: difficultyLevel,
      masteredConcepts: userProgress.conceptsMastered,
      inProgressConcepts: userProgress.conceptsInProgress,
      targetConcept: targetConcept,
      learningPathType: learningPathType,
    );

    return challenge;
  }

  /// Validate a user's solution to a challenge
  ///
  /// [challenge] is the challenge to validate against
  /// [solution] is the user's solution to the challenge
  /// [userId] is the ID of the user (optional)
  ///
  /// Returns a validation result with success flag, feedback, and assessment
  Future<ValidationResult> validateSolution({
    required ChallengeModel challenge,
    required PatternModel solution,
    String? userId,
  }) async {
    await _ensureInitialized();

    // Find a validator that can handle this challenge type
    final validator = _validators.firstWhere(
      (validator) => validator.canHandle(challenge.type),
      orElse: () => throw ArgumentError('No validator found for challenge type ${challenge.type}'),
    );

    // Validate the solution
    final result = await validator.validate(
      challenge: challenge,
      solution: solution,
    );

    // If a user ID is provided, save the validation result
    if (userId != null) {
      await _challengeRepository.saveValidationResult(result, userId);
    }

    return result;
  }

  /// Update user progress based on challenge completion
  ///
  /// [userProgress] is the user's current progress
  /// [challenge] is the completed challenge
  /// [validationResult] is the result of solution validation
  ///
  /// Returns updated user progress
  Future<UserProgress> updateProgressForChallenge({
    required UserProgress userProgress,
    required ChallengeModel challenge,
    required ValidationResult validationResult,
  }) async {
    await _ensureInitialized();

    // Get challenge ID
    final challengeId = challenge.id;

    // Get required concepts from the challenge
    final requiredConcepts = challenge.requiredConcepts;

    // Get success flag from validation result
    final wasSuccessful = validationResult.success;

    // Update user progress using adaptive learning service
    return _adaptiveLearningService.updateProgressForChallenge(
      userProgress: userProgress,
      challengeId: challengeId,
      requiredConcepts: requiredConcepts,
      wasSuccessful: wasSuccessful,
    );
  }

  /// Check if a user has reached a milestone
  ///
  /// [userProgress] is the user's current progress
  ///
  /// Returns a milestone if reached, null otherwise
  Future<Map<String, dynamic>?> checkMilestone(UserProgress userProgress) async {
    await _ensureInitialized();

    // Get completed challenges count
    final completedChallengesCount = userProgress.completedChallenges.length;

    // Get mastered concepts count
    final masteredConceptsCount = userProgress.conceptsMastered.length;

    // Define milestones
    final milestones = [
      {
        'id': 'first_challenge',
        'name': 'First Challenge Completed',
        'description': 'You completed your first challenge!',
        'condition': completedChallengesCount >= 1,
        'reward': 'New block types unlocked',
        'educationalContext': 'Completing challenges helps you practice coding concepts and build your skills.',
      },
      {
        'id': 'five_challenges',
        'name': 'Challenge Master',
        'description': 'You completed 5 challenges!',
        'condition': completedChallengesCount >= 5,
        'reward': 'Advanced pattern creation tools unlocked',
        'educationalContext': 'Regular practice with different challenges helps reinforce your understanding of coding concepts.',
      },
      {
        'id': 'three_concepts',
        'name': 'Concept Explorer',
        'description': 'You mastered 3 coding concepts!',
        'condition': masteredConceptsCount >= 3,
        'reward': 'New story themes unlocked',
        'educationalContext': 'Mastering coding concepts allows you to create more complex and interesting patterns.',
      },
      {
        'id': 'pattern_expert',
        'name': 'Pattern Expert',
        'description': 'You\'ve become an expert in creating patterns!',
        'condition': userProgress.completedChallenges.where((id) => id.contains('pattern')).length >= 10,
        'reward': 'Special pattern blocks unlocked',
        'educationalContext': 'Patterns are a fundamental concept in computer science, used to recognize and create repeating structures.',
      },
      {
        'id': 'sequence_master',
        'name': 'Sequence Master',
        'description': 'You\'ve mastered creating sequences!',
        'condition': userProgress.completedChallenges.where((id) => id.contains('sequence')).length >= 10,
        'reward': 'Special sequence blocks unlocked',
        'educationalContext': 'Sequences are the foundation of algorithms, determining the order in which instructions are executed.',
      },
    ];

    // Check if any milestone has been reached
    for (final milestone in milestones) {
      if (milestone['condition'] as bool && !userProgress.completedMilestones.contains(milestone['id'])) {
        return milestone;
      }
    }

    return null;
  }

  /// Get challenges by educational standard
  ///
  /// [standardId] is the ID of the educational standard
  /// [userId] is the ID of the user (optional)
  ///
  /// Returns a list of challenges aligned with the standard
  Future<List<ChallengeModel>> getChallengesByStandard(
    String standardId, {
    String? userId,
  }) async {
    await _ensureInitialized();

    return _challengeRepository.getChallengesByStandard(standardId);
  }

  /// Get challenges by concept
  ///
  /// [concept] is the concept to get challenges for
  /// [userId] is the ID of the user (optional)
  ///
  /// Returns a list of challenges for the concept
  Future<List<ChallengeModel>> getChallengesByConcept(
    String concept, {
    String? userId,
  }) async {
    await _ensureInitialized();

    return _challengeRepository.getChallengesByRequiredConcept(concept);
  }

  /// Get challenges by learning path type
  ///
  /// [learningPathType] is the learning path type
  /// [userId] is the ID of the user (optional)
  ///
  /// Returns a list of challenges for the learning path
  Future<List<ChallengeModel>> getChallengesByLearningPath(
    LearningPathType learningPathType, {
    String? userId,
  }) async {
    await _ensureInitialized();

    return _challengeRepository.getChallengesByLearningPathType(learningPathType);
  }

  /// Get challenges completed by a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of completed challenges
  Future<List<ChallengeModel>> getCompletedChallenges(String userId) async {
    await _ensureInitialized();

    return _challengeRepository.getCompletedChallenges(userId);
  }

  /// Get challenges not yet completed by a user
  ///
  /// [userId] is the ID of the user
  ///
  /// Returns a list of uncompleted challenges
  Future<List<ChallengeModel>> getUncompletedChallenges(String userId) async {
    await _ensureInitialized();

    return _challengeRepository.getUncompletedChallenges(userId);
  }

  /// Get a learning path for a user
  ///
  /// [userId] is the ID of the user
  /// [learningPathType] is the type of learning path
  /// [count] is the number of challenges to include (optional)
  ///
  /// Returns a list of challenges for the learning path
  Future<List<ChallengeModel>> getLearningPath(
    String userId,
    LearningPathType learningPathType, {
    int count = 5,
  }) async {
    await _ensureInitialized();

    return _challengeGenerator.generateLearningPathChallenges(
      userId,
      learningPathType,
      count: count,
    );
  }

  /// Create a default challenge when no suitable challenges are found
  ChallengeModel _createDefaultChallenge({
    required String challengeType,
    required int difficultyLevel,
    required List<String> masteredConcepts,
    required List<String> inProgressConcepts,
    String? targetConcept,
    LearningPathType? learningPathType,
  }) {
    // Determine which concepts to focus on
    List<String> focusConcepts;

    if (targetConcept != null) {
      // If target concept is specified, prioritize it
      focusConcepts = [targetConcept];

      // Add related concepts if needed
      if (inProgressConcepts.isNotEmpty) {
        focusConcepts.addAll(inProgressConcepts.where((c) => c != targetConcept).take(1));
      }
    } else {
      // Otherwise use in-progress or mastered concepts
      focusConcepts = inProgressConcepts.isNotEmpty
          ? inProgressConcepts
          : masteredConcepts.isNotEmpty
              ? masteredConcepts
              : ['sequences', 'basic patterns', 'simple loops'];
    }

    // Determine required block types based on difficulty and learning path
    List<String> requiredBlockTypes;

    if (learningPathType == LearningPathType.logicBased) {
      // Logic-based paths emphasize structured learning
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'loop']
              : ['move', 'turn', 'loop', 'condition'];
    } else if (learningPathType == LearningPathType.creativityBased) {
      // Creativity-based paths emphasize exploration
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn', 'color']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'color', 'pattern']
              : ['move', 'turn', 'color', 'pattern', 'variable'];
    } else if (learningPathType == LearningPathType.challengeBased) {
      // Challenge-based paths are more difficult
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn', 'loop']
          : difficultyLevel <= 3
              ? ['move', 'turn', 'loop', 'condition']
              : ['move', 'turn', 'loop', 'condition', 'variable'];
    } else {
      // Default block types based on difficulty
      requiredBlockTypes = difficultyLevel <= 2
          ? ['move', 'turn']
          : difficultyLevel <= 4
              ? ['move', 'turn', 'loop']
              : ['move', 'turn', 'loop', 'condition'];
    }

    // Determine minimum connections based on difficulty and learning path
    int minConnections;

    if (learningPathType == LearningPathType.challengeBased) {
      // Challenge-based paths require more connections
      minConnections = difficultyLevel * 3;
    } else if (learningPathType == LearningPathType.creativityBased) {
      // Creativity-based paths are more flexible
      minConnections = difficultyLevel * 1;
    } else {
      // Default connections based on difficulty
      minConnections = difficultyLevel * 2;
    }

    // Create appropriate title and description based on learning path
    String title;
    String description;

    if (learningPathType == LearningPathType.logicBased) {
      title = 'Create a Logical ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Create a structured pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Focus on logical organization.';
    } else if (learningPathType == LearningPathType.creativityBased) {
      title = 'Design a Creative ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Express yourself by creating a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Be creative!';
    } else if (learningPathType == LearningPathType.challengeBased) {
      title = 'Master the ${_getDifficultyName(difficultyLevel)} Pattern Challenge';
      description = 'Overcome this challenge by creating a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections. Push your skills!';
    } else {
      title = 'Create a ${_getDifficultyName(difficultyLevel)} Pattern';
      description = 'Create a pattern using ${requiredBlockTypes.join(', ')} blocks with at least $minConnections connections.';
    }

    // Create appropriate hints based on learning path
    List<String> hints;

    if (learningPathType == LearningPathType.logicBased) {
      hints = [
        'Start by planning your pattern structure with ${requiredBlockTypes.first} blocks.',
        'Think about the logical flow of your pattern and how blocks connect.',
        'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
      ];
    } else if (learningPathType == LearningPathType.creativityBased) {
      hints = [
        'Experiment with different combinations of ${requiredBlockTypes.join(', ')} blocks.',
        'Try creating a pattern that tells a story or expresses an emotion.',
        'There are many ways to solve this challenge - be creative!',
      ];
    } else if (learningPathType == LearningPathType.challengeBased) {
      hints = [
        'This is a challenging pattern - start with the core structure using ${requiredBlockTypes.first} blocks.',
        'Build up complexity gradually to reach at least $minConnections connections.',
        'Challenge yourself to use all required block types efficiently: ${requiredBlockTypes.join(', ')}.',
      ];
    } else {
      hints = [
        'Start by placing a ${requiredBlockTypes.first} block.',
        'Connect blocks to create a pattern with at least $minConnections connections.',
        'Make sure to use all required block types: ${requiredBlockTypes.join(', ')}.',
      ];
    }

    // Create tags based on learning path
    List<String> tags = ['generated', challengeType];

    if (learningPathType == LearningPathType.logicBased) {
      tags.add('logical');
      tags.add('structured');
    } else if (learningPathType == LearningPathType.creativityBased) {
      tags.add('creative');
      tags.add('open-ended');
    } else if (learningPathType == LearningPathType.challengeBased) {
      tags.add('challenge');
      tags.add('advanced');
    }

    // Add concept-related tags
    tags.addAll(focusConcepts);

    // Create success criteria
    final successCriteria = SuccessCriteria(
      requiresBlockType: requiredBlockTypes,
      minConnections: minConnections,
    );

    // Create educational standards
    final educationalStandards = EducationalStandards(
      csStandardIds: _getDefaultStandardsForConcepts(focusConcepts, 'cs'),
      isteStandardIds: _getDefaultStandardsForConcepts(focusConcepts, 'iste'),
      k12FrameworkIds: _getDefaultStandardsForConcepts(focusConcepts, 'k12'),
    );

    // Create assessment rubric
    final assessmentRubric = AssessmentRubric(
      basicCriteria: {
        'uses_required_blocks': 'Uses all required block types',
        'has_min_connections': 'Has at least $minConnections connections',
      },
      proficientCriteria: {
        'uses_required_blocks': 'Uses all required block types',
        'has_min_connections': 'Has at least $minConnections connections',
        'efficient_solution': 'Creates an efficient solution',
      },
      advancedCriteria: {
        'uses_required_blocks': 'Uses all required block types',
        'has_min_connections': 'Has at least $minConnections connections',
        'efficient_solution': 'Creates an efficient solution',
        'creative_approach': 'Uses a creative or innovative approach',
      },
    );

    return ChallengeModel(
      id: 'default_${challengeType}_${difficultyLevel}_${DateTime.now().millisecondsSinceEpoch}',
      type: challengeType,
      title: title,
      description: description,
      difficulty: difficultyLevel,
      requiredConcepts: focusConcepts.take(2).toList(),
      successCriteria: successCriteria,
      availableBlockTypes: ['move', 'turn', 'loop', 'condition', 'variable', 'color', 'pattern'],
      hints: hints,
      tags: tags,
      learningPathType: learningPathType,
      educationalStandards: educationalStandards,
      assessmentRubric: assessmentRubric,
      scaffoldingLevel: _getScaffoldingLevelForDifficulty(difficultyLevel),
      estimatedTimeMinutes: difficultyLevel * 5,
      culturalContext: 'This challenge connects to Kente weaving traditions, where patterns have cultural significance.',
    );
  }

  /// Get a human-readable name for a difficulty level
  String _getDifficultyName(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return 'Simple';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Custom';
    }
  }

  /// Get the appropriate scaffolding level for a difficulty level
  int _getScaffoldingLevelForDifficulty(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return 3; // Highly guided
      case 2:
        return 2; // Structured
      case 3:
        return 1; // Light guidance
      case 4:
      case 5:
        return 0; // Open-ended
      default:
        return 1; // Light guidance
    }
  }

  /// Get default educational standards for concepts
  List<String> _getDefaultStandardsForConcepts(
    List<String> concepts,
    String standardType
  ) {
    // This is a simplified implementation
    // A more sophisticated approach would use a mapping of concepts to standards

    // For now, return some default standards based on the standard type
    if (standardType == 'cs') {
      return ['1A-AP-10', '1A-AP-11', '1A-AP-12'];
    } else if (standardType == 'iste') {
      return ['1.c', '1.d', '4.d'];
    } else if (standardType == 'k12') {
      return ['4-6.AP.10', '4-6.AP.11', '4-6.AP.12'];
    }

    return [];
  }
}
