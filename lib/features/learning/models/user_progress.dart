import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/skill_type.dart';

/// Enum representing different learning styles
enum LearningStyle {
  /// Visual learners prefer image-based and spatial content
  visual,
  
  /// Logical learners prefer structured, analytical content
  logical,
  
  /// Practical learners prefer hands-on examples and applications
  practical,
  
  /// Verbal learners prefer text and explanation-based content
  verbal,
  
  /// Social learners prefer collaborative challenges and sharing
  social,
  
  /// Reflective learners prefer taking time to think and analyze
  reflective,
}

/// Extension methods for learning style
extension LearningStyleExtension on LearningStyle {
  /// Get a human-readable name for the learning style
  String get displayName {
    switch (this) {
      case LearningStyle.visual:
        return 'Visual';
      case LearningStyle.logical:
        return 'Logical';
      case LearningStyle.practical:
        return 'Practical';
      case LearningStyle.verbal:
        return 'Verbal';
      case LearningStyle.social:
        return 'Social';
      case LearningStyle.reflective:
        return 'Reflective';
    }
  }
  
  /// Get a description of the learning style
  String get description {
    switch (this) {
      case LearningStyle.visual:
        return 'You learn best through images, diagrams, and spatial arrangements';
      case LearningStyle.logical:
        return 'You learn best through logic, reasoning, and systems';
      case LearningStyle.practical:
        return 'You learn best through hands-on practice and real-world applications';
      case LearningStyle.verbal:
        return 'You learn best through words, both written and spoken';
      case LearningStyle.social:
        return 'You learn best through interaction with others and collaborative work';
      case LearningStyle.reflective:
        return 'You learn best through thinking, analyzing, and reflecting';
    }
  }
  
  /// Get the string representation of the learning style
  String toStringValue() {
    return toString().split('.').last;
  }
  
  /// Create a learning style from a string
  static LearningStyle fromString(String value) {
    return LearningStyle.values.firstWhere(
      (style) => style.toString().split('.').last == value,
      orElse: () => LearningStyle.visual,
    );
  }
}

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
  
  /// Map of concept IDs to proficiency values (0.0 to 1.0)
  final Map<String, double> skillProficiency;
  
  /// List of concepts that have been mastered
  final List<String> conceptsMastered;
  
  /// List of concepts that are currently being learned
  final List<String> conceptsInProgress;
  
  /// Map of challenge IDs to number of attempts
  final Map<String, int> challengeAttempts;
  
  /// List of completed challenge IDs
  final List<String> completedChallenges;
  
  /// User's preferred learning style
  final LearningStyle preferredLearningStyle;
  
  /// Learning style confidence scores (0.0 to 1.0)
  final Map<LearningStyle, double> learningStyleConfidence;
  
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
  
  /// Engagement metrics
  final Map<String, dynamic> engagementMetrics;
  
  /// Session history
  final List<Map<String, dynamic>> sessionHistory;
  
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
    this.skillProficiency = const {},
    this.conceptsMastered = const [],
    this.conceptsInProgress = const [],
    this.challengeAttempts = const {},
    this.completedChallenges = const [],
    this.preferredLearningStyle = LearningStyle.visual,
    this.learningStyleConfidence = const {},
    this.experiencePoints = 0,
    this.level = 1,
    this.streak = 0,
    DateTime? lastActiveDate,
    this.preferences = const {},
    this.engagementMetrics = const {},
    this.sessionHistory = const [],
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
    Map<String, double>? skillProficiency,
    List<String>? conceptsMastered,
    List<String>? conceptsInProgress,
    Map<String, int>? challengeAttempts,
    List<String>? completedChallenges,
    LearningStyle? preferredLearningStyle,
    Map<LearningStyle, double>? learningStyleConfidence,
    int? experiencePoints,
    int? level,
    int? streak,
    DateTime? lastActiveDate,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? engagementMetrics,
    List<Map<String, dynamic>>? sessionHistory,
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
      skillProficiency: skillProficiency ?? this.skillProficiency,
      conceptsMastered: conceptsMastered ?? this.conceptsMastered,
      conceptsInProgress: conceptsInProgress ?? this.conceptsInProgress,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      preferredLearningStyle: preferredLearningStyle ?? this.preferredLearningStyle,
      learningStyleConfidence: learningStyleConfidence ?? this.learningStyleConfidence,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      preferences: preferences ?? this.preferences,
      engagementMetrics: engagementMetrics ?? this.engagementMetrics,
      sessionHistory: sessionHistory ?? this.sessionHistory,
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
    
    // Parse skill proficiency
    final Map<String, double> proficiencyMap = {};
    if (json['skillProficiency'] != null) {
      final proficiencyJson = json['skillProficiency'] as Map<String, dynamic>;
      proficiencyJson.forEach((conceptId, proficiency) {
        proficiencyMap[conceptId] = proficiency is double 
            ? proficiency 
            : double.tryParse(proficiency.toString()) ?? 0.0;
      });
    }
    
    // Parse learning style confidence
    final Map<LearningStyle, double> styleConfidence = {};
    if (json['learningStyleConfidence'] != null) {
      final confidenceJson = json['learningStyleConfidence'] as Map<String, dynamic>;
      confidenceJson.forEach((styleStr, confidence) {
        try {
          final style = LearningStyle.values.firstWhere(
            (s) => s.toString().split('.').last == styleStr,
          );
          styleConfidence[style] = confidence is double 
              ? confidence 
              : double.tryParse(confidence.toString()) ?? 0.0;
        } catch (e) {
          // Skip invalid entries
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
    
    // Parse session history
    final List<Map<String, dynamic>> sessions = [];
    if (json['sessionHistory'] != null) {
      for (final sessionJson in (json['sessionHistory'] as List<dynamic>)) {
        sessions.add(Map<String, dynamic>.from(sessionJson));
      }
    }
    
    // Parse preferred learning style
    LearningStyle preferredStyle = LearningStyle.visual;
    if (json['preferredLearningStyle'] != null) {
      if (json['preferredLearningStyle'] is String) {
        preferredStyle = LearningStyleExtension.fromString(json['preferredLearningStyle']);
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
      skillProficiency: proficiencyMap,
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
      preferredLearningStyle: preferredStyle,
      learningStyleConfidence: styleConfidence,
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
      engagementMetrics: json['engagementMetrics'] != null 
          ? Map<String, dynamic>.from(json['engagementMetrics']) 
          : {},
      sessionHistory: sessions,
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
    
    // Convert learning style confidence to JSON-friendly format
    final Map<String, double> confidenceJson = {};
    learningStyleConfidence.forEach((style, confidence) {
      confidenceJson[style.toString().split('.').last] = confidence;
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
      'skillProficiency': skillProficiency,
      'conceptsMastered': conceptsMastered,
      'conceptsInProgress': conceptsInProgress,
      'challengeAttempts': challengeAttempts,
      'completedChallenges': completedChallenges,
      'preferredLearningStyle': preferredLearningStyle.toStringValue(),
      'learningStyleConfidence': confidenceJson,
      'experiencePoints': experiencePoints,
      'level': level,
      'streak': streak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'preferences': preferences,
      'engagementMetrics': engagementMetrics,
      'sessionHistory': sessionHistory,
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
      'preferredLearningStyle': preferredLearningStyle.toStringValue(),
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'engagementScore': calculateEngagementScore(),
    };
  }
  
  /// Calculate an engagement score based on user activity (0.0 to 1.0)
  double calculateEngagementScore() {
    // Factors that contribute to engagement:
    // 1. Streak (consecutive days of activity)
    // 2. Completed challenges
    // 3. Mastered concepts
    // 4. Session frequency (from session history)
    
    double streakScore = (streak / 7).clamp(0.0, 1.0); // Max score at 7-day streak
    double challengeScore = (completedChallengesCount / 10).clamp(0.0, 1.0); // Max score at 10 challenges
    double conceptScore = (masteredConceptsCount / 5).clamp(0.0, 1.0); // Max score at 5 mastered concepts
    
    // Session frequency score (based on session history)
    double sessionScore = 0.0;
    if (sessionHistory.isNotEmpty) {
      // More recent sessions get higher weight
      int totalSessions = sessionHistory.length;
      sessionScore = (totalSessions / 10).clamp(0.0, 1.0); // Max score at 10 sessions
    }
    
    // Weighted average of all factors
    return (streakScore * 0.3) + 
           (challengeScore * 0.3) + 
           (conceptScore * 0.2) + 
           (sessionScore * 0.2);
  }
}

