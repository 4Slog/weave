import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/models/badge_model.dart';
import 'package:kente_codeweaver/models/skill_level.dart';
import 'package:kente_codeweaver/models/skill_type.dart';

/// Represents a user's progress in the Kente Codeweaver application
class UserProgress {
  /// Unique identifier for the user
  final String userId;
  
  /// Name of the user (if provided)
  final String name;
  
  /// List of completed story IDs
  final List<String> completedStories;
  
  /// List of completed story branch IDs
  final List<String> completedStoryBranches;
  
  /// Badges earned by the user
  final List<BadgeModel> earnedBadges;
  
  /// Map of story IDs to completion metrics
  final Map<String, Map<String, dynamic>> storyMetrics;
  
  /// Map of story IDs to user decisions
  final Map<String, Map<String, String>> storyDecisions;
  
  /// Adaptive learning metrics
  final Map<String, dynamic> learningMetrics;
  
  /// Narrative context for personalized stories
  final Map<String, dynamic> narrativeContext;
  
  /// Map of skill types to skill levels
  final Map<SkillType, SkillLevel> skills;
  
  /// List of concepts that have been mastered
  final List<String> conceptsMastered;
  
  /// List of concepts that are currently being learned
  final List<String> conceptsInProgress;
  
  /// Map of challenge IDs to number of attempts
  final Map<String, int> challengeAttempts;
  
  /// List of completed challenge IDs
  final List<String> completedChallenges;
  
  /// User's preferred learning style (visual, logical, practical)
  final String preferredLearningStyle;
  
  /// User's experience points
  final int experiencePoints;
  
  /// User's current level
  final int level;
  
  /// User's streak (consecutive days of activity)
  final int streak;
  
  /// Last active date (for streak calculation)
  final DateTime lastActiveDate;
  
  /// User preferences
  final Map<String, dynamic> preferences;
  
  /// Create a user progress object
  UserProgress({
    required this.userId,
    required this.name,
    this.completedStories = const [],
    this.completedStoryBranches = const [],
    this.earnedBadges = const [],
    this.storyMetrics = const {},
    this.storyDecisions = const {},
    this.learningMetrics = const {},
    this.narrativeContext = const {},
    this.skills = const {},
    this.conceptsMastered = const [],
    this.conceptsInProgress = const [],
    this.challengeAttempts = const {},
    this.completedChallenges = const [],
    this.preferredLearningStyle = 'visual',
    this.experiencePoints = 0,
    this.level = 1,
    this.streak = 0,
    DateTime? lastActiveDate,
    this.preferences = const {},
  }) : this.lastActiveDate = lastActiveDate ?? DateTime.now();
  
  /// Create a copy with updated fields
  UserProgress copyWith({
    String? userId,
    String? name,
    List<String>? completedStories,
    List<String>? completedStoryBranches,
    List<BadgeModel>? earnedBadges,
    Map<String, Map<String, dynamic>>? storyMetrics,
    Map<String, Map<String, String>>? storyDecisions,
    Map<String, dynamic>? learningMetrics,
    Map<String, dynamic>? narrativeContext,
    Map<SkillType, SkillLevel>? skills,
    List<String>? conceptsMastered,
    List<String>? conceptsInProgress,
    Map<String, int>? challengeAttempts,
    List<String>? completedChallenges,
    String? preferredLearningStyle,
    int? experiencePoints,
    int? level,
    int? streak,
    DateTime? lastActiveDate,
    Map<String, dynamic>? preferences,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      completedStories: completedStories ?? this.completedStories,
      completedStoryBranches: completedStoryBranches ?? this.completedStoryBranches,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      storyMetrics: storyMetrics ?? this.storyMetrics,
      storyDecisions: storyDecisions ?? this.storyDecisions,
      learningMetrics: learningMetrics ?? this.learningMetrics,
      narrativeContext: narrativeContext ?? this.narrativeContext,
      skills: skills ?? this.skills,
      conceptsMastered: conceptsMastered ?? this.conceptsMastered,
      conceptsInProgress: conceptsInProgress ?? this.conceptsInProgress,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      preferredLearningStyle: preferredLearningStyle ?? this.preferredLearningStyle,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      preferences: preferences ?? this.preferences,
    );
  }
  
  /// Create from JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // Parse badges
    final List<BadgeModel> badges = [];
    if (json['earnedBadges'] != null) {
      for (final badgeJson in (json['earnedBadges'] as List<dynamic>)) {
        badges.add(BadgeModel.fromJson(badgeJson));
      }
    }
    
    // Parse story metrics
    final Map<String, Map<String, dynamic>> metrics = {};
    if (json['storyMetrics'] != null) {
      final metricsMap = json['storyMetrics'] as Map<String, dynamic>;
      metricsMap.forEach((storyId, storyMetric) {
        metrics[storyId] = Map<String, dynamic>.from(storyMetric);
      });
    }
    
    // Parse story decisions
    final Map<String, Map<String, String>> decisions = {};
    if (json['storyDecisions'] != null) {
      final decisionsMap = json['storyDecisions'] as Map<String, dynamic>;
      decisionsMap.forEach((storyId, storyDecision) {
        decisions[storyId] = Map<String, String>.from(storyDecision);
      });
    }
    
    // Parse skills
    final Map<SkillType, SkillLevel> skillMap = {};
    if (json['skills'] != null) {
      final skillsJson = json['skills'] as Map<String, dynamic>;
      skillsJson.forEach((skillTypeStr, skillLevelStr) {
        try {
          final skillType = SkillType.values.firstWhere(
            (type) => type.toString().split('.').last == skillTypeStr,
          );
          final skillLevel = SkillLevel.values.firstWhere(
            (level) => level.toString().split('.').last == skillLevelStr,
          );
          skillMap[skillType] = skillLevel;
        } catch (e) {
          // Skip invalid skill entries
        }
      });
    }
    
    // Parse challenge attempts
    final Map<String, int> attempts = {};
    if (json['challengeAttempts'] != null) {
      final attemptsJson = json['challengeAttempts'] as Map<String, dynamic>;
      attemptsJson.forEach((challengeId, count) {
        attempts[challengeId] = count is int ? count : int.tryParse(count.toString()) ?? 0;
      });
    }
    
    // Parse last active date
    DateTime? lastActive;
    if (json['lastActiveDate'] != null) {
      try {
        lastActive = DateTime.parse(json['lastActiveDate']);
      } catch (e) {
        lastActive = DateTime.now();
      }
    }
    
    return UserProgress(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Learner',
      completedStories: json['completedStories'] != null 
          ? List<String>.from(json['completedStories']) 
          : [],
      completedStoryBranches: json['completedStoryBranches'] != null 
          ? List<String>.from(json['completedStoryBranches']) 
          : [],
      earnedBadges: badges,
      storyMetrics: metrics,
      storyDecisions: decisions,
      learningMetrics: json['learningMetrics'] != null 
          ? Map<String, dynamic>.from(json['learningMetrics']) 
          : {},
      narrativeContext: json['narrativeContext'] != null 
          ? Map<String, dynamic>.from(json['narrativeContext']) 
          : {},
      skills: skillMap,
      conceptsMastered: json['conceptsMastered'] != null 
          ? List<String>.from(json['conceptsMastered']) 
          : [],
      conceptsInProgress: json['conceptsInProgress'] != null 
          ? List<String>.from(json['conceptsInProgress']) 
          : [],
      challengeAttempts: attempts,
      completedChallenges: json['completedChallenges'] != null 
          ? List<String>.from(json['completedChallenges']) 
          : [],
      preferredLearningStyle: json['preferredLearningStyle'] ?? 'visual',
      experiencePoints: json['experiencePoints'] is int 
          ? json['experiencePoints'] 
          : int.tryParse(json['experiencePoints']?.toString() ?? '0') ?? 0,
      level: json['level'] is int 
          ? json['level'] 
          : int.tryParse(json['level']?.toString() ?? '1') ?? 1,
      streak: json['streak'] is int 
          ? json['streak'] 
          : int.tryParse(json['streak']?.toString() ?? '0') ?? 0,
      lastActiveDate: lastActive,
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences']) 
          : {},
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    // Convert skills to JSON-friendly format
    final Map<String, String> skillsJson = {};
    skills.forEach((skillType, skillLevel) {
      skillsJson[skillType.toString().split('.').last] = 
          skillLevel.toString().split('.').last;
    });
    
    return {
      'userId': userId,
      'name': name,
      'completedStories': completedStories,
      'completedStoryBranches': completedStoryBranches,
      'earnedBadges': earnedBadges.map((badge) => badge.toJson()).toList(),
      'storyMetrics': storyMetrics,
      'storyDecisions': storyDecisions,
      'learningMetrics': learningMetrics,
      'narrativeContext': narrativeContext,
      'skills': skillsJson,
      'conceptsMastered': conceptsMastered,
      'conceptsInProgress': conceptsInProgress,
      'challengeAttempts': challengeAttempts,
      'completedChallenges': completedChallenges,
      'preferredLearningStyle': preferredLearningStyle,
      'experiencePoints': experiencePoints,
      'level': level,
      'streak': streak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'preferences': preferences,
    };
  }
  
  /// Helper method to add a completed story
  UserProgress addCompletedStory(String storyId, Map<String, dynamic> metrics) {
    final newCompletedStories = List<String>.from(completedStories);
    if (!newCompletedStories.contains(storyId)) {
      newCompletedStories.add(storyId);
    }
    
    final newStoryMetrics = Map<String, Map<String, dynamic>>.from(storyMetrics);
    newStoryMetrics[storyId] = metrics;
    
    // Update last active date and check streak
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    
    int newStreak = streak;
    if (lastActiveDate.year == yesterday.year && 
        lastActiveDate.month == yesterday.month && 
        lastActiveDate.day == yesterday.day) {
      // Consecutive day, increment streak
      newStreak++;
    } else if (lastActiveDate.year != now.year || 
               lastActiveDate.month != now.month || 
               lastActiveDate.day != now.day) {
      // Not consecutive and not today, reset streak
      newStreak = 1;
    }
    
    return copyWith(
      completedStories: newCompletedStories,
      storyMetrics: newStoryMetrics,
      lastActiveDate: now,
      streak: newStreak,
    );
  }
  
  /// Helper method to add a completed story branch
  UserProgress addCompletedStoryBranch(String branchId) {
    final newCompletedBranches = List<String>.from(completedStoryBranches);
    if (!newCompletedBranches.contains(branchId)) {
      newCompletedBranches.add(branchId);
    }
    
    return copyWith(
      completedStoryBranches: newCompletedBranches,
      lastActiveDate: DateTime.now(),
    );
  }
  
  /// Helper method to add a story decision
  UserProgress addStoryDecision(String storyId, Map<String, String> decisions) {
    final newStoryDecisions = Map<String, Map<String, String>>.from(storyDecisions);
    newStoryDecisions[storyId] = decisions;
    
    return copyWith(
      storyDecisions: newStoryDecisions,
    );
  }
  
  /// Helper method to add a badge
  UserProgress addBadge(BadgeModel badge) {
    final newBadges = List<BadgeModel>.from(earnedBadges);
    
    // Check if badge already exists
    if (!newBadges.any((existing) => existing.id == badge.id)) {
      newBadges.add(badge);
      
      // Add experience points for earning a badge
      final newXp = experiencePoints + 50;
      
      return copyWith(
        earnedBadges: newBadges,
        experiencePoints: newXp,
      );
    }
    
    return copyWith(earnedBadges: newBadges);
  }
  
  /// Update narrative context
  UserProgress updateNarrativeContext(Map<String, dynamic> newContext) {
    final updatedContext = Map<String, dynamic>.from(narrativeContext)
      ..addAll(newContext);
    
    return copyWith(narrativeContext: updatedContext);
  }
  
  /// Update learning metrics
  UserProgress updateLearningMetrics(Map<String, dynamic> newMetrics) {
    final updatedMetrics = Map<String, dynamic>.from(learningMetrics)
      ..addAll(newMetrics);
    
    return copyWith(learningMetrics: updatedMetrics);
  }
  
  /// Set a user preference
  UserProgress setPreference(String key, dynamic value) {
    final updatedPreferences = Map<String, dynamic>.from(preferences);
    updatedPreferences[key] = value;
    
    return copyWith(preferences: updatedPreferences);
  }
  
  /// Add a concept to the in-progress list
  UserProgress addConceptInProgress(String conceptId) {
    if (conceptsMastered.contains(conceptId) || 
        conceptsInProgress.contains(conceptId)) {
      return this;
    }
    
    final updatedConcepts = List<String>.from(conceptsInProgress)..add(conceptId);
    
    return copyWith(conceptsInProgress: updatedConcepts);
  }
  
  /// Mark a concept as mastered
  UserProgress masterConcept(String conceptId) {
    // Remove from in-progress if present
    final updatedInProgress = List<String>.from(conceptsInProgress);
    updatedInProgress.remove(conceptId);
    
    // Add to mastered if not already present
    final updatedMastered = List<String>.from(conceptsMastered);
    if (!updatedMastered.contains(conceptId)) {
      updatedMastered.add(conceptId);
    }
    
    // Award experience points for mastering a concept
    final newXp = experiencePoints + 25;
    
    return copyWith(
      conceptsInProgress: updatedInProgress,
      conceptsMastered: updatedMastered,
      experiencePoints: newXp,
    );
  }
  
  /// Record a challenge attempt
  UserProgress recordChallengeAttempt(String challengeId) {
    final updatedAttempts = Map<String, int>.from(challengeAttempts);
    updatedAttempts[challengeId] = (updatedAttempts[challengeId] ?? 0) + 1;
    
    return copyWith(
      challengeAttempts: updatedAttempts,
      lastActiveDate: DateTime.now(),
    );
  }
  
  /// Add a completed challenge
  UserProgress addCompletedChallenge(String challengeId) {
    if (completedChallenges.contains(challengeId)) {
      return this;
    }
    
    final updatedChallenges = List<String>.from(completedChallenges)..add(challengeId);
    
    // Award experience points for completing a challenge
    final newXp = experiencePoints + 30;
    
    return copyWith(
      completedChallenges: updatedChallenges,
      experiencePoints: newXp,
      lastActiveDate: DateTime.now(),
    );
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
    
    // Award experience points for improving a skill
    final newXp = experiencePoints + 15;
    
    // Return updated user progress
    return copyWith(
      skills: updatedSkills,
      experiencePoints: newXp,
      lastActiveDate: DateTime.now(),
    );
  }
  
  /// Get the skill level for a specific skill type
  SkillLevel getSkillLevel(SkillType skillType) {
    return skills[skillType] ?? SkillLevel.novice;
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
      lastActiveDate: DateTime.now(),
    );
  }
  
  /// Check if a story is completed
  bool isStoryCompleted(String storyId) {
    return completedStories.contains(storyId);
  }
  
  /// Check if a story branch is completed
  bool isStoryBranchCompleted(String branchId) {
    return completedStoryBranches.contains(branchId);
  }
  
  /// Check if a challenge is completed
  bool isChallengeCompleted(String challengeId) {
    return completedChallenges.contains(challengeId);
  }
  
  /// Check if a concept is mastered
  bool isConceptMastered(String conceptId) {
    return conceptsMastered.contains(conceptId);
  }
  
  /// Check if a concept is in progress
  bool isConceptInProgress(String conceptId) {
    return conceptsInProgress.contains(conceptId);
  }
  
  /// Get the number of attempts for a challenge
  int getChallengeAttempts(String challengeId) {
    return challengeAttempts[challengeId] ?? 0;
  }
  
  /// Get the number of completed stories
  int get completedStoriesCount => completedStories.length;
  
  /// Get the number of earned badges
  int get earnedBadgesCount => earnedBadges.length;
  
  /// Get the number of mastered concepts
  int get masteredConceptsCount => conceptsMastered.length;
  
  /// Get the number of completed challenges
  int get completedChallengesCount => completedChallenges.length;
  
  /// Get the total number of challenge attempts
  int get totalChallengeAttempts {
    int total = 0;
    challengeAttempts.forEach((_, count) => total += count);
    return total;
  }
  
  /// Get the experience needed for the next level
  int get experienceForNextLevel => level * 100;
  
  /// Get the progress percentage towards the next level (0-100)
  int get levelProgressPercentage {
    final required = experienceForNextLevel;
    final current = experiencePoints - ((level - 1) * 100);
    return ((current / required) * 100).clamp(0, 100).toInt();
  }
  
  /// Check if user has earned a specific badge
  bool hasBadge(String badgeId) {
    return earnedBadges.any((badge) => badge.id == badgeId);
  }
  
  /// Get a summary of the user's progress
  Map<String, dynamic> getProgressSummary() {
    return {
      'level': level,
      'experiencePoints': experiencePoints,
      'levelProgress': levelProgressPercentage,
      'streak': streak,
      'completedStories': completedStoriesCount,
      'earnedBadges': earnedBadgesCount,
      'masteredConcepts': masteredConceptsCount,
      'completedChallenges': completedChallengesCount,
      'preferredLearningStyle': preferredLearningStyle,
      'lastActiveDate': lastActiveDate.toIso8601String(),
    };
  }
}
