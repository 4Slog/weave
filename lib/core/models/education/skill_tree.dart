import 'coding_skill.dart';

/// Model representing a skill tree.
/// 
/// This model contains a collection of coding skills organized into a tree structure,
/// with relationships between skills defined by prerequisites.
class SkillTree {
  /// Unique identifier for the skill tree.
  final String id;
  
  /// Display name of the skill tree.
  final String name;
  
  /// Description of the skill tree.
  final String description;
  
  /// List of all skills in the tree.
  final List<CodingSkill> skills;
  
  /// Creates a new SkillTree.
  SkillTree({
    required this.id,
    required this.name,
    required this.description,
    required this.skills,
  });
  
  /// Create a copy of this SkillTree with some fields replaced.
  SkillTree copyWith({
    String? id,
    String? name,
    String? description,
    List<CodingSkill>? skills,
  }) {
    return SkillTree(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      skills: skills ?? this.skills,
    );
  }
  
  /// Convert this SkillTree to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'skills': skills.map((skill) => skill.toJson()).toList(),
    };
  }
  
  /// Create a SkillTree from a JSON map.
  factory SkillTree.fromJson(Map<String, dynamic> json) {
    final skillsList = (json['skills'] as List?)
        ?.map((skillJson) => CodingSkill.fromJson(skillJson))
        .toList() ?? [];
    
    return SkillTree(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      skills: skillsList,
    );
  }
  
  /// Get a skill by its ID.
  CodingSkill? getSkillById(String skillId) {
    try {
      return skills.firstWhere((skill) => skill.id == skillId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all root skills (skills with no prerequisites).
  List<CodingSkill> getRootSkills() {
    return skills.where((skill) => skill.prerequisites.isEmpty).toList();
  }
  
  /// Get all skills that have a given skill as a prerequisite.
  List<CodingSkill> getDependentSkills(String skillId) {
    return skills.where((skill) => skill.prerequisites.contains(skillId)).toList();
  }
  
  /// Get all skills in a specific category.
  List<CodingSkill> getSkillsByCategory(String category) {
    return skills.where((skill) => skill.category == category).toList();
  }
  
  /// Get all skills at a specific difficulty level.
  List<CodingSkill> getSkillsByDifficulty(int difficultyLevel) {
    return skills.where((skill) => skill.difficultyLevel == difficultyLevel).toList();
  }
  
  /// Get all skills related to a specific CS standard.
  List<CodingSkill> getSkillsByCSStandard(String standardId) {
    return skills.where((skill) => skill.relatedCSStandards.contains(standardId)).toList();
  }
  
  /// Get all skills related to a specific ISTE standard.
  List<CodingSkill> getSkillsByISTEStandard(String standardId) {
    return skills.where((skill) => skill.relatedISTEStandards.contains(standardId)).toList();
  }
  
  /// Get all skills related to a specific K-12 CS Framework element.
  List<CodingSkill> getSkillsByK12Element(String elementId) {
    return skills.where((skill) => skill.relatedK12Elements.contains(elementId)).toList();
  }
  
  /// Check if a skill is available to learn based on prerequisites.
  bool isSkillAvailable(String skillId, List<String> masteredSkillIds) {
    final skill = getSkillById(skillId);
    if (skill == null) return false;
    
    // If the skill has no prerequisites, it's available
    if (skill.prerequisites.isEmpty) return true;
    
    // Check if all prerequisites are mastered
    return skill.prerequisites.every((prereqId) => masteredSkillIds.contains(prereqId));
  }
  
  /// Get all skills available to learn based on currently mastered skills.
  List<CodingSkill> getAvailableSkills(List<String> masteredSkillIds) {
    return skills.where((skill) => 
      !masteredSkillIds.contains(skill.id) && 
      isSkillAvailable(skill.id, masteredSkillIds)
    ).toList();
  }
  
  /// Get the recommended next skills to learn based on currently mastered skills.
  List<CodingSkill> getRecommendedNextSkills(List<String> masteredSkillIds) {
    final availableSkills = getAvailableSkills(masteredSkillIds);
    
    // Sort by difficulty level and number of dependent skills
    availableSkills.sort((a, b) {
      // First sort by difficulty
      final diffComparison = a.difficultyLevel.compareTo(b.difficultyLevel);
      if (diffComparison != 0) return diffComparison;
      
      // Then by number of dependent skills (more dependents = higher priority)
      final aDependents = getDependentSkills(a.id).length;
      final bDependents = getDependentSkills(b.id).length;
      return bDependents.compareTo(aDependents);
    });
    
    // Return top 3 recommended skills
    return availableSkills.take(3).toList();
  }
}
