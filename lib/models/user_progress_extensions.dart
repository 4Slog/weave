import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/skill_type.dart';
import 'package:kente_codeweaver/models/skill_level.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

/// Extension methods for UserProgress to support skills and progress tracking
extension UserProgressExtensions on UserProgress {
  /// Get the preferred learning style as a string (for backward compatibility)
  String get preferredLearningStyleString => preferredLearningStyle.toStringValue();
  
  /// Create a copy with updated preferred learning style from string
  UserProgress withPreferredLearningStyleString(String styleString) {
    return copyWith(
      preferredLearningStyle: LearningStyleExtension.fromString(styleString),
    );
  }
  
  /// Update skill proficiency for a specific concept
  UserProgress updateSkillProficiency(String conceptId, double proficiency) {
    final updatedProficiency = Map<String, double>.from(skillProficiency);
    updatedProficiency[conceptId] = proficiency.clamp(0.0, 1.0);
    
    // Check if concept should be marked as mastered (proficiency >= 0.8)
    if (proficiency >= 0.8 && !conceptsMastered.contains(conceptId)) {
      final updatedMastered = List<String>.from(conceptsMastered)..add(conceptId);
      final updatedInProgress = List<String>.from(conceptsInProgress)
        ..remove(conceptId);
      
      return copyWith(
        skillProficiency: updatedProficiency,
        conceptsMastered: updatedMastered,
        conceptsInProgress: updatedInProgress,
      );
    } 
    // Check if concept should be marked as in progress (0.0 < proficiency < 0.8)
    else if (proficiency > 0.0 && 
             proficiency < 0.8 && 
             !conceptsInProgress.contains(conceptId) &&
             !conceptsMastered.contains(conceptId)) {
      final updatedInProgress = List<String>.from(conceptsInProgress)..add(conceptId);
      
      return copyWith(
        skillProficiency: updatedProficiency,
        conceptsInProgress: updatedInProgress,
      );
    } else {
      return copyWith(
        skillProficiency: updatedProficiency,
      );
    }
  }
  
  /// Get the proficiency level for a specific concept
  double getConceptProficiency(String conceptId) {
    return skillProficiency[conceptId] ?? 0.0;
  }
  
  /// Update learning style confidence
  UserProgress updateLearningStyleConfidence(LearningStyle style, double confidence) {
    final updatedConfidence = Map<LearningStyle, double>.from(learningStyleConfidence);
    updatedConfidence[style] = confidence.clamp(0.0, 1.0);
    
    // Update preferred learning style if this style has the highest confidence
    LearningStyle bestStyle = preferredLearningStyle;
    double highestConfidence = updatedConfidence[preferredLearningStyle] ?? 0.0;
    
    updatedConfidence.forEach((s, c) {
      if (c > highestConfidence) {
        highestConfidence = c;
        bestStyle = s;
      }
    });
    
    return copyWith(
      learningStyleConfidence: updatedConfidence,
      preferredLearningStyle: bestStyle,
    );
  }
  
  /// Record a session in the user's history
  UserProgress recordSession(Map<String, dynamic> sessionData) {
    final updatedHistory = List<Map<String, dynamic>>.from(sessionHistory)
      ..add(sessionData);
    
    // Keep only the last 20 sessions to avoid excessive storage
    if (updatedHistory.length > 20) {
      updatedHistory.removeAt(0);
    }
    
    return copyWith(
      sessionHistory: updatedHistory,
    );
  }
  
  /// Update engagement metrics
  UserProgress updateEngagementMetrics(Map<String, dynamic> metrics) {
    final updatedMetrics = Map<String, dynamic>.from(engagementMetrics)
      ..addAll(metrics);
    
    return copyWith(
      engagementMetrics: updatedMetrics,
    );
  }
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
