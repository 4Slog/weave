import 'package:flutter/foundation.dart';
import '../../../models/education/coding_skill.dart';
import '../../../models/education/skill_tree.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';

/// Repository for managing coding skills and skill trees.
/// 
/// This repository handles the storage and retrieval of coding skills
/// and skill trees, as well as user skill mastery data.
class CodingSkillRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _skillKeyPrefix = 'coding_skill_';
  static const String _skillTreeKeyPrefix = 'skill_tree_';
  static const String _userSkillMasteryKeyPrefix = 'user_skill_mastery_';
  static const String _allSkillsKey = 'all_coding_skills';
  static const String _allSkillTreesKey = 'all_skill_trees';
  
  /// Creates a new CodingSkillRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  CodingSkillRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a coding skill.
  /// 
  /// [skill] is the coding skill to save.
  Future<void> saveSkill(CodingSkill skill) async {
    final key = _skillKeyPrefix + skill.id;
    await _storage.saveData(key, skill.toJson());
    
    // Update the list of all skills
    await _updateSkillsList(skill.id);
  }
  
  /// Get a coding skill by ID.
  /// 
  /// [skillId] is the ID of the skill to retrieve.
  /// Returns the skill if found, or null if not found.
  Future<CodingSkill?> getSkill(String skillId) async {
    final key = _skillKeyPrefix + skillId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return CodingSkill.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing coding skill: $e');
      return null;
    }
  }
  
  /// Get all coding skills.
  /// 
  /// Returns a list of all coding skills.
  Future<List<CodingSkill>> getAllSkills() async {
    final skillIds = await _getSkillIds();
    final skills = <CodingSkill>[];
    
    for (final id in skillIds) {
      final skill = await getSkill(id);
      if (skill != null) {
        skills.add(skill);
      }
    }
    
    return skills;
  }
  
  /// Get coding skills by category.
  /// 
  /// [category] is the category to filter by (e.g., "Algorithms", "Data").
  /// Returns a list of skills for the specified category.
  Future<List<CodingSkill>> getSkillsByCategory(String category) async {
    final allSkills = await getAllSkills();
    return allSkills.where((skill) => skill.category == category).toList();
  }
  
  /// Get coding skills by difficulty level.
  /// 
  /// [difficultyLevel] is the difficulty level to filter by (1-5).
  /// Returns a list of skills for the specified difficulty level.
  Future<List<CodingSkill>> getSkillsByDifficultyLevel(int difficultyLevel) async {
    final allSkills = await getAllSkills();
    return allSkills.where((skill) => skill.difficultyLevel == difficultyLevel).toList();
  }
  
  /// Get coding skills related to a CS standard.
  /// 
  /// [standardId] is the ID of the CS standard to filter by.
  /// Returns a list of skills related to the specified standard.
  Future<List<CodingSkill>> getSkillsByCSStandard(String standardId) async {
    final allSkills = await getAllSkills();
    return allSkills.where((skill) => skill.relatedCSStandards.contains(standardId)).toList();
  }
  
  /// Get coding skills related to an ISTE standard.
  /// 
  /// [standardId] is the ID of the ISTE standard to filter by.
  /// Returns a list of skills related to the specified standard.
  Future<List<CodingSkill>> getSkillsByISTEStandard(String standardId) async {
    final allSkills = await getAllSkills();
    return allSkills.where((skill) => skill.relatedISTEStandards.contains(standardId)).toList();
  }
  
  /// Get coding skills related to a K-12 CS Framework element.
  /// 
  /// [elementId] is the ID of the K-12 CS Framework element to filter by.
  /// Returns a list of skills related to the specified element.
  Future<List<CodingSkill>> getSkillsByK12Element(String elementId) async {
    final allSkills = await getAllSkills();
    return allSkills.where((skill) => skill.relatedK12Elements.contains(elementId)).toList();
  }
  
  /// Delete a coding skill.
  /// 
  /// [skillId] is the ID of the skill to delete.
  Future<void> deleteSkill(String skillId) async {
    final key = _skillKeyPrefix + skillId;
    await _storage.removeData(key);
    
    // Update the list of all skills
    await _removeFromSkillsList(skillId);
  }
  
  /// Save a skill tree.
  /// 
  /// [skillTree] is the skill tree to save.
  Future<void> saveSkillTree(SkillTree skillTree) async {
    final key = _skillTreeKeyPrefix + skillTree.id;
    await _storage.saveData(key, skillTree.toJson());
    
    // Update the list of all skill trees
    await _updateSkillTreesList(skillTree.id);
    
    // Save all skills in the tree
    for (final skill in skillTree.skills) {
      await saveSkill(skill);
    }
  }
  
  /// Get a skill tree by ID.
  /// 
  /// [skillTreeId] is the ID of the skill tree to retrieve.
  /// Returns the skill tree if found, or null if not found.
  Future<SkillTree?> getSkillTree(String skillTreeId) async {
    final key = _skillTreeKeyPrefix + skillTreeId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return SkillTree.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing skill tree: $e');
      return null;
    }
  }
  
  /// Get all skill trees.
  /// 
  /// Returns a list of all skill trees.
  Future<List<SkillTree>> getAllSkillTrees() async {
    final skillTreeIds = await _getSkillTreeIds();
    final skillTrees = <SkillTree>[];
    
    for (final id in skillTreeIds) {
      final skillTree = await getSkillTree(id);
      if (skillTree != null) {
        skillTrees.add(skillTree);
      }
    }
    
    return skillTrees;
  }
  
  /// Delete a skill tree.
  /// 
  /// [skillTreeId] is the ID of the skill tree to delete.
  /// [deleteSkills] determines whether to also delete the skills in the tree.
  Future<void> deleteSkillTree(String skillTreeId, {bool deleteSkills = false}) async {
    final key = _skillTreeKeyPrefix + skillTreeId;
    
    if (deleteSkills) {
      final skillTree = await getSkillTree(skillTreeId);
      if (skillTree != null) {
        for (final skill in skillTree.skills) {
          await deleteSkill(skill.id);
        }
      }
    }
    
    await _storage.removeData(key);
    
    // Update the list of all skill trees
    await _removeFromSkillTreesList(skillTreeId);
  }
  
  /// Save user skill mastery data.
  /// 
  /// [userId] is the ID of the user.
  /// [skillId] is the ID of the skill.
  /// [masteryLevel] is the user's mastery level for the skill (0.0 to 1.0).
  Future<void> saveUserSkillMastery(String userId, String skillId, double masteryLevel) async {
    final key = _userSkillMasteryKeyPrefix + userId + '_' + skillId;
    await _storage.saveData(key, masteryLevel);
  }
  
  /// Get user skill mastery data.
  /// 
  /// [userId] is the ID of the user.
  /// [skillId] is the ID of the skill.
  /// Returns the user's mastery level for the skill (0.0 to 1.0),
  /// or 0.0 if not found.
  Future<double> getUserSkillMastery(String userId, String skillId) async {
    final key = _userSkillMasteryKeyPrefix + userId + '_' + skillId;
    final data = await _storage.getData(key);
    
    if (data == null) return 0.0;
    
    try {
      if (data is double) {
        return data;
      } else if (data is num) {
        return data.toDouble();
      } else {
        return 0.0;
      }
    } catch (e) {
      debugPrint('Error parsing user skill mastery: $e');
      return 0.0;
    }
  }
  
  /// Get all skill mastery data for a user.
  /// 
  /// [userId] is the ID of the user.
  /// Returns a map of skill IDs to mastery levels.
  Future<Map<String, double>> getAllUserSkillMastery(String userId) async {
    final allSkills = await getAllSkills();
    final masteryMap = <String, double>{};
    
    for (final skill in allSkills) {
      final masteryLevel = await getUserSkillMastery(userId, skill.id);
      masteryMap[skill.id] = masteryLevel;
    }
    
    return masteryMap;
  }
  
  /// Get all mastered skills for a user.
  /// 
  /// [userId] is the ID of the user.
  /// [masteryThreshold] is the threshold for considering a skill mastered (default: 0.8).
  /// Returns a list of skill IDs that the user has mastered.
  Future<List<String>> getUserMasteredSkills(String userId, {double masteryThreshold = 0.8}) async {
    final masteryMap = await getAllUserSkillMastery(userId);
    
    return masteryMap.entries
        .where((entry) => entry.value >= masteryThreshold)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get recommended next skills for a user.
  /// 
  /// [userId] is the ID of the user.
  /// [skillTreeId] is the ID of the skill tree to use for recommendations.
  /// [count] is the maximum number of skills to recommend.
  /// Returns a list of recommended skills for the user to learn next.
  Future<List<CodingSkill>> getRecommendedNextSkills(
    String userId, 
    String skillTreeId, 
    {int count = 3}
  ) async {
    final skillTree = await getSkillTree(skillTreeId);
    if (skillTree == null) return [];
    
    final masteredSkillIds = await getUserMasteredSkills(userId);
    
    return skillTree.getRecommendedNextSkills(masteredSkillIds).take(count).toList();
  }
  
  /// Helper method to update the list of all skills.
  Future<void> _updateSkillsList(String skillId) async {
    final skillIds = await _getSkillIds();
    
    if (!skillIds.contains(skillId)) {
      skillIds.add(skillId);
      await _storage.saveData(_allSkillsKey, skillIds);
    }
  }
  
  /// Helper method to remove a skill from the list of all skills.
  Future<void> _removeFromSkillsList(String skillId) async {
    final skillIds = await _getSkillIds();
    
    if (skillIds.contains(skillId)) {
      skillIds.remove(skillId);
      await _storage.saveData(_allSkillsKey, skillIds);
    }
  }
  
  /// Helper method to get the list of all skill IDs.
  Future<List<String>> _getSkillIds() async {
    final data = await _storage.getData(_allSkillsKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing coding skills list: $e');
      return [];
    }
  }
  
  /// Helper method to update the list of all skill trees.
  Future<void> _updateSkillTreesList(String skillTreeId) async {
    final skillTreeIds = await _getSkillTreeIds();
    
    if (!skillTreeIds.contains(skillTreeId)) {
      skillTreeIds.add(skillTreeId);
      await _storage.saveData(_allSkillTreesKey, skillTreeIds);
    }
  }
  
  /// Helper method to remove a skill tree from the list of all skill trees.
  Future<void> _removeFromSkillTreesList(String skillTreeId) async {
    final skillTreeIds = await _getSkillTreeIds();
    
    if (skillTreeIds.contains(skillTreeId)) {
      skillTreeIds.remove(skillTreeId);
      await _storage.saveData(_allSkillTreesKey, skillTreeIds);
    }
  }
  
  /// Helper method to get the list of all skill tree IDs.
  Future<List<String>> _getSkillTreeIds() async {
    final data = await _storage.getData(_allSkillTreesKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing skill trees list: $e');
      return [];
    }
  }
}
