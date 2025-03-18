import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/skill_type.dart';
import 'package:kente_codeweaver/models/skill_level.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

/// Extension methods for UserProgress to support skills and progress tracking
extension UserProgressExtensions on UserProgress {
  /// Get the skill level for a specific skill type
  SkillLevel getSkillLevel(SkillType skillType) {
    return skills[skillType] ?? SkillLevel.novice;
  }
  
  /// Improve a skill by one level
  UserProgress improveSkill(SkillType skillType) {
    final Map<SkillType, SkillLevel> updatedSkills = Map.from(skills);
    
    // Get current level
    final currentLevel = updatedSkills[skillType] ?? SkillLevel.novice;
    
    // Determine next level (don't go beyond advanced)
    SkillLevel nextLevel;
    switch (currentLevel) {
      case SkillLevel.novice:
        nextLevel = SkillLevel.beginner;
        break;
      case SkillLevel.beginner:
        nextLevel = SkillLevel.intermediate;
        break;
      case SkillLevel.intermediate:
      case SkillLevel.advanced:
        nextLevel = SkillLevel.advanced;
        break;
    }
    
    // Update skill level
    updatedSkills[skillType] = nextLevel;
    
    // Return updated user progress
    return copyWith(
      skills: updatedSkills,
    );
  }
  
  /// Add experience points to user progress
  UserProgress addExperience(int amount) {
    final newXp = experiencePoints + amount;
    int newLevel = level;
    
    // Check if level up (simple formula: each level requires level*100 XP)
    while (newXp >= newLevel * 100) {
      newLevel++;
    }
    
    return copyWith(
      experiencePoints: newXp,
      level: newLevel,
    );
  }
  
  /// Add a completed challenge ID to user progress
  UserProgress addCompletedChallenge(String challengeId) {
    if (completedChallenges.contains(challengeId)) {
      return this;
    }
    
    final updatedChallenges = List<String>.from(completedChallenges)..add(challengeId);
    
    return copyWith(
      completedChallenges: updatedChallenges,
    );
  }
}