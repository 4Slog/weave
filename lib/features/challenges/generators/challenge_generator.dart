import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/challenge_model.dart';
import '../repositories/challenge_repository.dart';

/// Generator for creating challenges based on educational criteria.
///
/// This class provides methods for generating challenges based on
/// educational standards, skill requirements, and learning paths.
class ChallengeGenerator {
  final ChallengeRepository _challengeRepository;
  final StorageService _storageService;

  /// Create a new ChallengeGenerator.
  ChallengeGenerator({
    ChallengeRepository? challengeRepository,
    StorageService? storageService,
  }) :
    _challengeRepository = challengeRepository ?? ChallengeRepository(StorageService().storage),
    _storageService = storageService ?? StorageService();

  /// Generate a challenge based on user skills.
  ///
  /// [userId] is the ID of the user.
  /// [preferredType] is the preferred type of challenge (optional).
  /// [preferredDifficulty] is the preferred difficulty level (optional).
  /// [preferredLearningPathType] is the preferred learning path type (optional).
  ///
  /// Returns a challenge appropriate for the user's skill level.
  Future<ChallengeModel?> generateChallengeForUser(
    String userId, {
    String? preferredType,
    int? preferredDifficulty,
    LearningPathType? preferredLearningPathType,
  }) async {
    // Get user skills
    final userSkills = await _storageService.getAllUserSkillMastery(userId);

    // Get user learning style
    final learningProfile = await _storageService.getLearningStyleProfile(userId);

    // Get challenges appropriate for the user's skill level
    final appropriateChallenges = await _challengeRepository.getChallengesForSkillLevel(userSkills);

    // Get challenges not yet completed by the user
    final uncompletedChallenges = await _challengeRepository.getUncompletedChallenges(userId);

    // Filter challenges that are both appropriate and not yet completed
    final candidateChallenges = appropriateChallenges
        .where((challenge) => uncompletedChallenges.any((c) => c.id == challenge.id))
        .toList();

    // If there are no candidate challenges, return null
    if (candidateChallenges.isEmpty) return null;

    // Apply filters based on preferences
    var filteredChallenges = candidateChallenges;

    // Filter by type if specified
    if (preferredType != null) {
      final typeFiltered = filteredChallenges
          .where((challenge) => challenge.type == preferredType)
          .toList();

      // Only apply the filter if it doesn't eliminate all challenges
      if (typeFiltered.isNotEmpty) {
        filteredChallenges = typeFiltered;
      }
    }

    // Filter by difficulty if specified
    if (preferredDifficulty != null) {
      final difficultyFiltered = filteredChallenges
          .where((challenge) => challenge.difficulty == preferredDifficulty)
          .toList();

      // Only apply the filter if it doesn't eliminate all challenges
      if (difficultyFiltered.isNotEmpty) {
        filteredChallenges = difficultyFiltered;
      }
    }

    // Filter by learning path type if specified
    if (preferredLearningPathType != null) {
      final pathFiltered = filteredChallenges
          .where((challenge) =>
              challenge.learningPathType == preferredLearningPathType ||
              challenge.learningPathType == null)
          .toList();

      // Only apply the filter if it doesn't eliminate all challenges
      if (pathFiltered.isNotEmpty) {
        filteredChallenges = pathFiltered;
      }
    }

    // If there are no filtered challenges, use the original candidates
    if (filteredChallenges.isEmpty) {
      filteredChallenges = candidateChallenges;
    }

    // Sort challenges by relevance to the user's learning style
    if (learningProfile != null) {
      filteredChallenges.sort((a, b) {
        final aRelevance = _calculateLearningStyleRelevance(a, learningProfile);
        final bRelevance = _calculateLearningStyleRelevance(b, learningProfile);
        return bRelevance.compareTo(aRelevance);
      });
    }

    // Return the most relevant challenge
    return filteredChallenges.isNotEmpty ? filteredChallenges.first : null;
  }

  /// Generate a sequence of challenges for a learning path.
  ///
  /// [userId] is the ID of the user.
  /// [learningPathType] is the type of learning path.
  /// [count] is the number of challenges to generate.
  ///
  /// Returns a list of challenges for the learning path.
  Future<List<ChallengeModel>> generateLearningPathChallenges(
    String userId,
    LearningPathType learningPathType,
    {int count = 5}
  ) async {
    // Get user skills
    final userSkills = await _storageService.getAllUserSkillMastery(userId);

    // Get challenges appropriate for the user's skill level
    final appropriateChallenges = await _challengeRepository.getChallengesForSkillLevel(userSkills);

    // Get challenges not yet completed by the user
    final uncompletedChallenges = await _challengeRepository.getUncompletedChallenges(userId);

    // Filter challenges that are both appropriate and not yet completed
    final candidateChallenges = appropriateChallenges
        .where((challenge) => uncompletedChallenges.any((c) => c.id == challenge.id))
        .toList();

    // Filter by learning path type
    var filteredChallenges = candidateChallenges
        .where((challenge) =>
            challenge.learningPathType == learningPathType ||
            challenge.learningPathType == null)
        .toList();

    // If there are not enough filtered challenges, use the original candidates
    if (filteredChallenges.length < count) {
      filteredChallenges = candidateChallenges;
    }

    // Sort challenges by difficulty
    filteredChallenges.sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Return the specified number of challenges
    return filteredChallenges.take(count).toList();
  }

  /// Generate challenges for a specific educational standard.
  ///
  /// [standardId] is the ID of the educational standard.
  /// [userId] is the ID of the user (optional).
  /// [count] is the number of challenges to generate (optional).
  ///
  /// Returns a list of challenges aligned with the standard.
  Future<List<ChallengeModel>> generateChallengesForStandard(
    String standardId, {
    String? userId,
    int count = 3,
  }) async {
    // Get challenges aligned with the standard
    final standardChallenges = await _challengeRepository.getChallengesByStandard(standardId);

    // If a user ID is provided, filter out completed challenges
    List<ChallengeModel> candidateChallenges = standardChallenges;
    if (userId != null) {
      final completedChallenges = await _challengeRepository.getCompletedChallenges(userId);
      final completedIds = completedChallenges.map((c) => c.id).toSet();

      candidateChallenges = standardChallenges
          .where((challenge) => !completedIds.contains(challenge.id))
          .toList();

      // If there are not enough uncompleted challenges, use all standard challenges
      if (candidateChallenges.length < count) {
        candidateChallenges = standardChallenges;
      }
    }

    // Sort challenges by difficulty
    candidateChallenges.sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Return the specified number of challenges
    return candidateChallenges.take(count).toList();
  }

  /// Generate challenges for a specific concept.
  ///
  /// [concept] is the concept to generate challenges for.
  /// [userId] is the ID of the user (optional).
  /// [count] is the number of challenges to generate (optional).
  ///
  /// Returns a list of challenges for the concept.
  Future<List<ChallengeModel>> generateChallengesForConcept(
    String concept, {
    String? userId,
    int count = 3,
  }) async {
    // Get challenges for the concept
    final conceptChallenges = await _challengeRepository.getChallengesByRequiredConcept(concept);

    // If a user ID is provided, filter out completed challenges
    List<ChallengeModel> candidateChallenges = conceptChallenges;
    if (userId != null) {
      final completedChallenges = await _challengeRepository.getCompletedChallenges(userId);
      final completedIds = completedChallenges.map((c) => c.id).toSet();

      candidateChallenges = conceptChallenges
          .where((challenge) => !completedIds.contains(challenge.id))
          .toList();

      // If there are not enough uncompleted challenges, use all concept challenges
      if (candidateChallenges.length < count) {
        candidateChallenges = conceptChallenges;
      }
    }

    // Sort challenges by difficulty
    candidateChallenges.sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Return the specified number of challenges
    return candidateChallenges.take(count).toList();
  }

  /// Generate a practice challenge for a specific skill.
  ///
  /// [skillId] is the ID of the skill to practice.
  /// [userId] is the ID of the user (optional).
  ///
  /// Returns a challenge for practicing the skill.
  Future<ChallengeModel?> generatePracticeChallenge(
    String skillId, {
    String? userId,
  }) async {
    // Get user's current skill level
    double skillLevel = 0.0;
    if (userId != null) {
      skillLevel = await _storageService.getUserSkillMastery(userId, skillId);
    }

    // Get all challenges
    final allChallenges = await _challengeRepository.getAllChallenges();

    // Filter challenges that require this skill
    final skillChallenges = allChallenges
        .where((challenge) => challenge.skillRequirements.containsKey(skillId))
        .toList();

    // If there are no skill challenges, return null
    if (skillChallenges.isEmpty) return null;

    // Filter challenges by appropriate difficulty based on skill level
    final targetDifficulty = _calculateTargetDifficulty(skillLevel);
    final difficultyRange = 1;

    final appropriateChallenges = skillChallenges
        .where((challenge) =>
            challenge.difficulty >= targetDifficulty - difficultyRange &&
            challenge.difficulty <= targetDifficulty + difficultyRange)
        .toList();

    // If there are no appropriate challenges, use all skill challenges
    final candidateChallenges = appropriateChallenges.isNotEmpty
        ? appropriateChallenges
        : skillChallenges;

    // If a user ID is provided, filter out completed challenges
    List<ChallengeModel> filteredChallenges = candidateChallenges;
    if (userId != null) {
      final completedChallenges = await _challengeRepository.getCompletedChallenges(userId);
      final completedIds = completedChallenges.map((c) => c.id).toSet();

      filteredChallenges = candidateChallenges
          .where((challenge) => !completedIds.contains(challenge.id))
          .toList();

      // If there are no uncompleted challenges, use all candidate challenges
      if (filteredChallenges.isEmpty) {
        filteredChallenges = candidateChallenges;
      }
    }

    // Sort challenges by how closely they match the target difficulty
    filteredChallenges.sort((a, b) {
      final aDiff = (a.difficulty - targetDifficulty).abs();
      final bDiff = (b.difficulty - targetDifficulty).abs();
      return aDiff.compareTo(bDiff);
    });

    // Return the most appropriate challenge
    return filteredChallenges.isNotEmpty ? filteredChallenges.first : null;
  }

  /// Calculate the relevance of a challenge to a learning style profile.
  double _calculateLearningStyleRelevance(
    ChallengeModel challenge,
    dynamic learningProfile
  ) {
    // This is a simplified implementation
    // A more sophisticated approach would analyze the challenge's
    // learning style compatibility in detail

    // For now, we'll return a random relevance score
    return 0.5;
  }

  /// Calculate the target difficulty based on skill level.
  int _calculateTargetDifficulty(double skillLevel) {
    // Convert skill level (0.0 to 1.0) to difficulty (1 to 5)
    final difficulty = (skillLevel * 5).round();

    // Ensure difficulty is in the valid range
    return difficulty.clamp(1, 5);
  }
}
