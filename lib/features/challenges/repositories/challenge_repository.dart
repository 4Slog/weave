import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage/base_repository.dart';
import 'package:kente_codeweaver/core/services/storage/storage_strategy.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/challenge_model.dart';
import '../models/validation_result.dart';

/// Repository for managing challenges.
/// 
/// This repository handles the storage and retrieval of challenges,
/// as well as user progress and validation results.
class ChallengeRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _challengeKeyPrefix = 'challenge_';
  static const String _allChallengesKey = 'all_challenges';
  static const String _userProgressKeyPrefix = 'user_challenge_progress_';
  static const String _validationResultKeyPrefix = 'validation_result_';
  
  /// Creates a new ChallengeRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  ChallengeRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a challenge.
  /// 
  /// [challenge] is the challenge to save.
  Future<void> saveChallenge(ChallengeModel challenge) async {
    final key = _challengeKeyPrefix + challenge.id;
    await _storage.saveData(key, challenge.toJson());
    
    // Update the list of all challenges
    await _updateChallengesList(challenge.id);
  }
  
  /// Get a challenge by ID.
  /// 
  /// [challengeId] is the ID of the challenge to retrieve.
  /// Returns the challenge if found, or null if not found.
  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final key = _challengeKeyPrefix + challengeId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return ChallengeModel.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing challenge: $e');
      return null;
    }
  }
  
  /// Get all challenges.
  /// 
  /// Returns a list of all challenges.
  Future<List<ChallengeModel>> getAllChallenges() async {
    final challengeIds = await _getChallengeIds();
    final challenges = <ChallengeModel>[];
    
    for (final id in challengeIds) {
      final challenge = await getChallenge(id);
      if (challenge != null) {
        challenges.add(challenge);
      }
    }
    
    return challenges;
  }
  
  /// Get challenges by type.
  /// 
  /// [type] is the type of challenges to retrieve (e.g., 'pattern', 'sequence').
  /// Returns a list of challenges of the specified type.
  Future<List<ChallengeModel>> getChallengesByType(String type) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where((challenge) => challenge.type == type).toList();
  }
  
  /// Get challenges by difficulty level.
  /// 
  /// [difficulty] is the difficulty level to filter by (1-5).
  /// Returns a list of challenges with the specified difficulty level.
  Future<List<ChallengeModel>> getChallengesByDifficulty(int difficulty) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where((challenge) => challenge.difficulty == difficulty).toList();
  }
  
  /// Get challenges by learning path type.
  /// 
  /// [learningPathType] is the learning path type to filter by.
  /// Returns a list of challenges for the specified learning path type.
  Future<List<ChallengeModel>> getChallengesByLearningPathType(
    LearningPathType learningPathType
  ) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where(
      (challenge) => challenge.learningPathType == learningPathType
    ).toList();
  }
  
  /// Get challenges by tag.
  /// 
  /// [tag] is the tag to filter by.
  /// Returns a list of challenges with the specified tag.
  Future<List<ChallengeModel>> getChallengesByTag(String tag) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where(
      (challenge) => challenge.tags.contains(tag)
    ).toList();
  }
  
  /// Get challenges by required concept.
  /// 
  /// [concept] is the required concept to filter by.
  /// Returns a list of challenges that require the specified concept.
  Future<List<ChallengeModel>> getChallengesByRequiredConcept(String concept) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where(
      (challenge) => challenge.requiredConcepts.contains(concept)
    ).toList();
  }
  
  /// Get challenges by educational standard.
  /// 
  /// [standardId] is the ID of the educational standard to filter by.
  /// Returns a list of challenges aligned with the specified standard.
  Future<List<ChallengeModel>> getChallengesByStandard(String standardId) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where(
      (challenge) => challenge.getStandardIds().contains(standardId)
    ).toList();
  }
  
  /// Get challenges appropriate for a user's skill level.
  /// 
  /// [userSkills] is a map of skill IDs to skill levels.
  /// Returns a list of challenges appropriate for the user's skill level.
  Future<List<ChallengeModel>> getChallengesForSkillLevel(
    Map<String, double> userSkills
  ) async {
    final allChallenges = await getAllChallenges();
    return allChallenges.where(
      (challenge) => challenge.isAppropriateForSkillLevel(userSkills)
    ).toList();
  }
  
  /// Get challenges completed by a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of challenges completed by the user.
  Future<List<ChallengeModel>> getCompletedChallenges(String userId) async {
    final progress = await getUserChallengeProgress(userId);
    final completedChallengeIds = progress.keys
        .where((challengeId) => progress[challengeId]?['completed'] == true)
        .toList();
    
    final completedChallenges = <ChallengeModel>[];
    for (final id in completedChallengeIds) {
      final challenge = await getChallenge(id);
      if (challenge != null) {
        completedChallenges.add(challenge);
      }
    }
    
    return completedChallenges;
  }
  
  /// Get challenges not yet completed by a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of challenges not yet completed by the user.
  Future<List<ChallengeModel>> getUncompletedChallenges(String userId) async {
    final allChallenges = await getAllChallenges();
    final completedChallenges = await getCompletedChallenges(userId);
    final completedIds = completedChallenges.map((c) => c.id).toSet();
    
    return allChallenges.where((challenge) => !completedIds.contains(challenge.id)).toList();
  }
  
  /// Delete a challenge.
  /// 
  /// [challengeId] is the ID of the challenge to delete.
  Future<void> deleteChallenge(String challengeId) async {
    final key = _challengeKeyPrefix + challengeId;
    await _storage.removeData(key);
    
    // Update the list of all challenges
    await _removeFromChallengesList(challengeId);
  }
  
  /// Import a list of challenges.
  /// 
  /// [challenges] is the list of challenges to import.
  /// Returns the number of challenges imported.
  Future<int> importChallenges(List<ChallengeModel> challenges) async {
    int count = 0;
    
    for (final challenge in challenges) {
      await saveChallenge(challenge);
      count++;
    }
    
    return count;
  }
  
  /// Save user challenge progress.
  /// 
  /// [userId] is the ID of the user.
  /// [challengeId] is the ID of the challenge.
  /// [progress] is the progress data to save.
  Future<void> saveUserChallengeProgress(
    String userId,
    String challengeId,
    Map<String, dynamic> progress
  ) async {
    final key = _userProgressKeyPrefix + userId;
    
    // Get existing progress
    final existingProgress = await getUserChallengeProgress(userId);
    
    // Update progress for this challenge
    existingProgress[challengeId] = progress;
    
    // Save updated progress
    await _storage.saveData(key, existingProgress);
  }
  
  /// Get user challenge progress.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a map of challenge IDs to progress data.
  Future<Map<String, Map<String, dynamic>>> getUserChallengeProgress(
    String userId
  ) async {
    final key = _userProgressKeyPrefix + userId;
    final data = await _storage.getData(key);
    
    if (data == null) return {};
    
    try {
      final progressMap = Map<String, dynamic>.from(data);
      return progressMap.map((challengeId, progress) {
        return MapEntry(
          challengeId,
          Map<String, dynamic>.from(progress),
        );
      });
    } catch (e) {
      debugPrint('Error parsing user challenge progress: $e');
      return {};
    }
  }
  
  /// Get user progress for a specific challenge.
  /// 
  /// [userId] is the ID of the user.
  /// [challengeId] is the ID of the challenge.
  /// Returns the progress data for the specified challenge.
  Future<Map<String, dynamic>> getUserProgressForChallenge(
    String userId,
    String challengeId
  ) async {
    final progress = await getUserChallengeProgress(userId);
    return progress[challengeId] ?? {};
  }
  
  /// Mark a challenge as completed by a user.
  /// 
  /// [userId] is the ID of the user.
  /// [challengeId] is the ID of the challenge.
  /// [achievementLevel] is the achievement level reached (basic, proficient, advanced).
  /// [pointsEarned] is the number of points earned.
  Future<void> markChallengeCompleted(
    String userId,
    String challengeId, {
    String achievementLevel = 'basic',
    int pointsEarned = 1,
  }) async {
    final progress = await getUserProgressForChallenge(userId, challengeId);
    
    // Update progress
    progress['completed'] = true;
    progress['completedAt'] = DateTime.now().toIso8601String();
    progress['achievementLevel'] = achievementLevel;
    progress['pointsEarned'] = pointsEarned;
    
    // Save updated progress
    await saveUserChallengeProgress(userId, challengeId, progress);
  }
  
  /// Save a validation result.
  /// 
  /// [result] is the validation result to save.
  /// [userId] is the ID of the user.
  Future<void> saveValidationResult(ValidationResult result, String userId) async {
    final key = _validationResultKeyPrefix + userId + '_' + result.challenge.id;
    await _storage.saveData(key, result.toJson());
    
    // If the solution is successful, mark the challenge as completed
    if (result.success) {
      await markChallengeCompleted(
        userId,
        result.challenge.id,
        achievementLevel: result.assessment.achievementLevel,
        pointsEarned: result.assessment.pointsEarned,
      );
    }
  }
  
  /// Get a validation result.
  /// 
  /// [userId] is the ID of the user.
  /// [challengeId] is the ID of the challenge.
  /// Returns the validation result if found, or null if not found.
  Future<ValidationResult?> getValidationResult(
    String userId,
    String challengeId
  ) async {
    final key = _validationResultKeyPrefix + userId + '_' + challengeId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      final challenge = await getChallenge(challengeId);
      if (challenge == null) return null;
      
      // We need the solution to create a ValidationResult
      // This is a simplified implementation
      // In a real implementation, we would store the solution ID
      // and retrieve it from a pattern repository
      return null;
    } catch (e) {
      debugPrint('Error parsing validation result: $e');
      return null;
    }
  }
  
  /// Get all validation results for a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a list of validation results for the user.
  Future<List<ValidationResult>> getUserValidationResults(String userId) async {
    final allKeys = await _storage.getAllKeys();
    final resultKeys = allKeys.where(
      (key) => key.startsWith(_validationResultKeyPrefix + userId + '_')
    ).toList();
    
    final results = <ValidationResult>[];
    for (final key in resultKeys) {
      final challengeId = key.substring((_validationResultKeyPrefix + userId + '_').length);
      final result = await getValidationResult(userId, challengeId);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  /// Helper method to update the list of all challenges.
  Future<void> _updateChallengesList(String challengeId) async {
    final challengeIds = await _getChallengeIds();
    
    if (!challengeIds.contains(challengeId)) {
      challengeIds.add(challengeId);
      await _storage.saveData(_allChallengesKey, challengeIds);
    }
  }
  
  /// Helper method to remove a challenge from the list of all challenges.
  Future<void> _removeFromChallengesList(String challengeId) async {
    final challengeIds = await _getChallengeIds();
    
    if (challengeIds.contains(challengeId)) {
      challengeIds.remove(challengeId);
      await _storage.saveData(_allChallengesKey, challengeIds);
    }
  }
  
  /// Helper method to get the list of all challenge IDs.
  Future<List<String>> _getChallengeIds() async {
    final data = await _storage.getData(_allChallengesKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing challenge IDs: $e');
      return [];
    }
  }
}
