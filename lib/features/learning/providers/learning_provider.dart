import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/features/badges/services/badge_service.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/skill_type.dart';
import 'package:kente_codeweaver/features/learning/services/learning_analysis_service.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'dart:convert';

/// Provider for learning state management with improved skill tracking,
/// personalized learning paths, milestone tracking, and learning analytics
class LearningProvider with ChangeNotifier {
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final BadgeService _badgeService = BadgeService();
  final LearningAnalysisService _analysisService = LearningAnalysisService();
  final StorageService _storageService = StorageService();

  UserProgress _userProgress = UserProgress(userId: 'default', name: 'Learner');
  bool _isLoading = false;
  String? _recommendedConcept;
  List<String> _conceptsToReview = [];
  List<BadgeModel> _earnedBadges = [];

  // Enhanced tracking for learning paths
  List<Map<String, dynamic>> _learningPath = [];

  // Milestone tracking
  List<Map<String, dynamic>> _milestones = [];
  List<String> _completedMilestones = [];

  // Learning analytics
  Map<String, dynamic> _learningAnalytics = {};

  // Skill progression history
  final Map<String, List<Map<String, dynamic>>> _skillProgressionHistory = {};

  /// Getters for state
  UserProgress get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get recommendedConcept => _recommendedConcept;
  List<String> get conceptsToReview => _conceptsToReview;
  List<BadgeModel> get earnedBadges => _earnedBadges;
  List<Map<String, dynamic>> get learningPath => _learningPath;
  List<Map<String, dynamic>> get milestones => _milestones;
  List<String> get completedMilestones => _completedMilestones;
  Map<String, dynamic> get learningAnalytics => _learningAnalytics;

  /// Whether the provider has been initialized
  bool get isInitialized => _userProgress.userId != 'default';

  /// Get all available challenges
  List<Map<String, dynamic>> get challenges {
    // Return the list of challenges from storage or a default list
    return [
      {
        'id': 'challenge_1',
        'title': 'Introduction to Patterns',
        'description': 'Learn the basics of pattern creation',
        'difficulty': 1,
        'skillType': 'PATTERN_RECOGNITION',
        'conceptId': 'patterns_intro',
      },
      {
        'id': 'challenge_2',
        'title': 'Simple Loops',
        'description': 'Create patterns using simple loops',
        'difficulty': 2,
        'skillType': 'LOOPS',
        'conceptId': 'loops_basic',
      },
      {
        'id': 'challenge_3',
        'title': 'Conditional Patterns',
        'description': 'Use conditions to create dynamic patterns',
        'difficulty': 3,
        'skillType': 'CONDITIONALS',
        'conceptId': 'conditionals_basic',
      },
    ];
  }

  /// Get the count of completed challenges
  int get completedChallengesCount => _userProgress.completedChallenges.length;

  /// Check if a challenge is completed
  bool isChallengeCompleted(String challengeId) {
    return _userProgress.completedChallenges.contains(challengeId);
  }

  /// Mark a challenge as completed
  Future<void> markChallengeCompleted(String challengeId) async {
    if (isChallengeCompleted(challengeId)) {
      return; // Already completed
    }

    // Find the challenge
    final challenge = challenges.firstWhere(
      (c) => c['id'] == challengeId,
      orElse: () => <String, dynamic>{},
    );

    if (challenge.isEmpty) {
      debugPrint('Challenge not found: $challengeId');
      return;
    }

    // Update user progress
    final List<String> updatedCompletedChallenges =
        List<String>.from(_userProgress.completedChallenges);
    updatedCompletedChallenges.add(challengeId);

    // Update skill proficiency
    final conceptId = challenge['conceptId'] as String?;
    final difficulty = (challenge['difficulty'] as int?)?.toDouble() ?? 1.0;

    if (conceptId != null) {
      // Use the existing updateSkill method
      await updateSkill(conceptId, true, difficulty);
    } else {
      // Just update the completed challenges if no concept ID
      _userProgress = _userProgress.copyWith(
        completedChallenges: updatedCompletedChallenges,
      );

      // Save the updated progress
      await _learningService.saveUserProgress(_userProgress);

      // Record the action
      recordAction(
        actionType: 'challenge_completed',
        wasSuccessful: true,
        contextId: challengeId,
        metadata: {
          'userId': _userProgress.userId,
          'challengeId': challengeId,
        },
      );

      // Check for badges
      final newBadges = await _badgeService.checkForNewBadges(_userProgress.userId);
      if (newBadges.isNotEmpty) {
        _earnedBadges.addAll(newBadges.where(
          (badge) => !_earnedBadges.any((b) => b.id == badge.id)
        ));
      }

      // Notify listeners
      notifyListeners();
    }
  }

  /// Initialize learning state for a user
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize the learning service if not already done
      await _learningService.initialize();

      // Load user progress
      final progress = await _learningService.getUserProgress(userId);
      if (progress != null) {
        _userProgress = progress;
      } else {
        _userProgress = UserProgress(userId: userId, name: 'Learner');
        await _learningService.saveUserProgress(_userProgress);
      }

      // Load earned badges
      _earnedBadges = await _badgeService.getUserBadges(userId);

      // Load milestones
      await _loadMilestones();

      // Generate initial learning path
      await _generateLearningPath();

      // Initialize learning analytics
      _initializeLearningAnalytics();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing LearningProviderEnhanced: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load milestones from storage or initialize defaults
  Future<void> _loadMilestones() async {
    try {
      // Try to load milestones from storage
      final milestonesData = await _storageService.getSetting('milestones');
      if (milestonesData != null) {
        _milestones = List<Map<String, dynamic>>.from(jsonDecode(milestonesData));
      } else {
        // Initialize default milestones
        _initializeDefaultMilestones();
      }

      // Load completed milestones from user progress
      if (_userProgress.preferences.containsKey('completedMilestones')) {
        _completedMilestones = List<String>.from(_userProgress.preferences['completedMilestones']);
      } else {
        _completedMilestones = [];
      }

      // Check for newly completed milestones
      _checkMilestones();
    } catch (e) {
      debugPrint('Error loading milestones: $e');
      // Initialize default milestones as fallback
      _initializeDefaultMilestones();
    }
  }

  /// Initialize default milestones
  void _initializeDefaultMilestones() {
    _milestones = [
      {
        'id': 'first_story',
        'title': 'First Story',
        'description': 'Complete your first story',
        'requirement': {'type': 'story_count', 'value': 1},
        'reward': {'xp': 50, 'badge': 'story_explorer'},
      },
      {
        'id': 'pattern_creator',
        'title': 'Pattern Creator',
        'description': 'Create your first pattern',
        'requirement': {'type': 'pattern_count', 'value': 1},
        'reward': {'xp': 50, 'badge': 'pattern_creator'},
      },
      {
        'id': 'challenge_master',
        'title': 'Challenge Master',
        'description': 'Complete 5 challenges',
        'requirement': {'type': 'challenge_count', 'value': 5},
        'reward': {'xp': 100, 'badge': 'challenge_master'},
      },
      {
        'id': 'concept_master',
        'title': 'Concept Master',
        'description': 'Master 3 coding concepts',
        'requirement': {'type': 'concept_mastery', 'value': 3},
        'reward': {'xp': 150, 'badge': 'concept_master'},
      },
      {
        'id': 'streak_keeper',
        'title': 'Streak Keeper',
        'description': 'Maintain a 3-day streak',
        'requirement': {'type': 'streak', 'value': 3},
        'reward': {'xp': 75, 'badge': 'streak_master'},
      },
      {
        'id': 'cultural_explorer',
        'title': 'Cultural Explorer',
        'description': 'Explore 5 cultural elements',
        'requirement': {'type': 'cultural_exploration', 'value': 5},
        'reward': {'xp': 100, 'badge': 'cultural_explorer'},
      },
      {
        'id': 'advanced_weaver',
        'title': 'Advanced Weaver',
        'description': 'Reach level 5',
        'requirement': {'type': 'level', 'value': 5},
        'reward': {'xp': 200, 'badge': 'advanced_weaver'},
      },
    ];
  }

  /// Check for completed milestones
  Future<void> _checkMilestones() async {
    bool milestonesUpdated = false;

    for (final milestone in _milestones) {
      final String id = milestone['id'];

      // Skip already completed milestones
      if (_completedMilestones.contains(id)) continue;

      // Check if milestone is completed
      if (_isMilestoneCompleted(milestone)) {
        // Add to completed milestones
        _completedMilestones.add(id);

        // Award rewards
        if (milestone['reward'] != null) {
          final reward = milestone['reward'];

          // Award XP
          if (reward['xp'] != null) {
            final xp = reward['xp'] as int;
            _userProgress = _userProgress.copyWith(
              experiencePoints: (_userProgress.experiencePoints) + xp,
            );
          }

          // Award badge
          if (reward['badge'] != null) {
            final badgeId = reward['badge'] as String;
            await _awardBadge(badgeId);
          }
        }

        milestonesUpdated = true;
      }
    }

    if (milestonesUpdated) {
      // Save completed milestones to user preferences
      _userProgress = _userProgress.setPreference('completedMilestones', _completedMilestones);
      await _learningService.saveUserProgress(_userProgress);
      notifyListeners();
    }
  }

  /// Award a badge to the user
  Future<void> _awardBadge(String badgeId) async {
    await _badgeService.awardBadge(_userProgress.userId, badgeId);
    _earnedBadges = await _badgeService.getUserBadges(_userProgress.userId);
    notifyListeners();
  }

  /// Check if a milestone is completed
  bool _isMilestoneCompleted(Map<String, dynamic> milestone) {
    final requirement = milestone['requirement'];
    if (requirement == null) return false;

    final type = requirement['type'];
    final value = requirement['value'];

    switch (type) {
      case 'story_count':
        return _userProgress.completedStoriesCount >= value;

      case 'pattern_count':
        // Check if user has created patterns
        final patternCount = _userProgress.preferences['patternCount'] ?? 0;
        return patternCount >= value;

      case 'challenge_count':
        return _userProgress.completedChallengesCount >= value;

      case 'concept_mastery':
        return _userProgress.masteredConceptsCount >= value;

      case 'streak':
        return _userProgress.streak >= value;

      case 'cultural_exploration':
        // Check cultural exploration count from preferences
        final explorationCount = _userProgress.preferences['culturalExplorationCount'] ?? 0;
        return explorationCount >= value;

      case 'level':
        return _userProgress.level >= value;

      default:
        return false;
    }
  }

  /// Generate a personalized learning path based on user progress
  Future<void> _generateLearningPath() async {
    // Clear existing path
    _learningPath = [];

    // Get user's skill levels and proficiency
    final skills = _userProgress.skills;
    final proficiency = _userProgress.skillProficiency;
    final mastered = _userProgress.conceptsMastered;
    final inProgress = _userProgress.conceptsInProgress;

    // Determine next concepts to learn
    List<String> nextConcepts = [];

    // First, add concepts that are in progress but not mastered
    nextConcepts.addAll(inProgress);

    // Then, suggest new concepts based on skill progression
    if (nextConcepts.isEmpty) {
      // If user hasn't mastered sequences, suggest that first
      if (!mastered.contains('sequences')) {
        nextConcepts.add('sequences');
      }
      // If user has mastered sequences but not loops, suggest loops
      else if (mastered.contains('sequences') && !mastered.contains('loops')) {
        nextConcepts.add('loops');
      }
      // If user has mastered sequences and loops but not conditionals, suggest conditionals
      else if (mastered.contains('sequences') && mastered.contains('loops') && !mastered.contains('conditionals')) {
        nextConcepts.add('conditionals');
      }
      // If user has mastered basic concepts, suggest more advanced ones
      else if (mastered.contains('sequences') && mastered.contains('loops') && mastered.contains('conditionals')) {
        if (!mastered.contains('variables')) {
          nextConcepts.add('variables');
        }
        if (!mastered.contains('functions')) {
          nextConcepts.add('functions');
        }
      }
    }

    // If still no concepts, suggest a random one that's not mastered
    if (nextConcepts.isEmpty) {
      final allConcepts = ['sequences', 'loops', 'conditionals', 'variables', 'functions', 'debugging', 'patterns'];
      final notMastered = allConcepts.where((concept) => !mastered.contains(concept)).toList();
      if (notMastered.isNotEmpty) {
        nextConcepts.add(notMastered.first);
      }
    }

    // Set recommended concept
    if (nextConcepts.isNotEmpty) {
      _recommendedConcept = nextConcepts.first;
    }

    // Generate learning path items
    for (final concept in nextConcepts) {
      // Get appropriate difficulty level based on user's skill
      final skillType = _getSkillTypeForConcept(concept);
      final skillLevel = skillType != null ? (skills[skillType] ?? SkillLevel.novice) : SkillLevel.novice;

      // Create learning path item
      _learningPath.add({
        'concept': concept,
        'title': _getConceptTitle(concept),
        'description': _getConceptDescription(concept),
        'skillLevel': skillLevel.toString().split('.').last,
        'estimatedTimeMinutes': _getEstimatedTimeForConcept(concept, skillLevel),
        'prerequisites': _getPrerequisitesForConcept(concept),
        'resources': _getResourcesForConcept(concept, skillLevel),
        'challenges': _getChallengesForConcept(concept, skillLevel),
      });
    }

    // Add concepts to review if proficiency is low
    _conceptsToReview = [];
    proficiency.forEach((concept, value) {
      if (value < 0.6 && value > 0 && mastered.contains(concept)) {
        _conceptsToReview.add(concept);
      }
    });

    notifyListeners();
  }

  /// Get skill type for a concept
  SkillType? _getSkillTypeForConcept(String concept) {
    final conceptToSkill = {
      'sequences': SkillType.sequences,
      'loops': SkillType.loops,
      'conditionals': SkillType.conditionals,
      'variables': SkillType.variables,
      'functions': SkillType.functions,
      'debugging': SkillType.debugging,
      'patterns': SkillType.patterns,
      'structure': SkillType.structure,
      'cultural': SkillType.culturalContext,
      'storytelling': SkillType.storytelling,
    };

    return conceptToSkill[concept];
  }

  /// Get concept title
  String _getConceptTitle(String concept) {
    final titles = {
      'sequences': 'Sequential Instructions',
      'loops': 'Repeating Patterns with Loops',
      'conditionals': 'Making Decisions with Conditionals',
      'variables': 'Storing Information with Variables',
      'functions': 'Creating Reusable Code with Functions',
      'debugging': 'Finding and Fixing Errors',
      'patterns': 'Creating Visual Patterns',
      'structure': 'Organizing Code Structure',
      'cultural': 'Exploring Cultural Context',
      'storytelling': 'Narrative and Storytelling',
    };

    return titles[concept] ?? concept.substring(0, 1).toUpperCase() + concept.substring(1);
  }

  /// Get concept description
  String _getConceptDescription(String concept) {
    final descriptions = {
      'sequences': 'Learn how to create step-by-step instructions to solve problems.',
      'loops': 'Discover how to repeat actions efficiently using loops.',
      'conditionals': 'Learn how to make decisions in your code based on conditions.',
      'variables': 'Understand how to store and use information in your programs.',
      'functions': 'Create reusable blocks of code to organize your programs.',
      'debugging': 'Develop skills to find and fix errors in your code.',
      'patterns': 'Create visual patterns using code and understand pattern recognition.',
      'structure': 'Learn how to organize your code for better readability and efficiency.',
      'cultural': 'Explore the cultural context of Kente weaving and its connection to coding.',
      'storytelling': 'Develop narrative skills and connect storytelling to coding concepts.',
    };

    return descriptions[concept] ?? 'Learn about $concept and how to apply it in coding.';
  }

  /// Get estimated time for learning a concept based on skill level
  int _getEstimatedTimeForConcept(String concept, SkillLevel skillLevel) {
    // Base time in minutes
    int baseTime = 30;

    // Adjust based on concept complexity
    final complexityConcepts = ['conditionals', 'functions', 'debugging'];
    if (complexityConcepts.contains(concept)) {
      baseTime += 15;
    }

    // Adjust based on skill level
    switch (skillLevel) {
      case SkillLevel.novice:
        return baseTime;
      case SkillLevel.beginner:
        return (baseTime * 0.8).round();
      case SkillLevel.intermediate:
        return (baseTime * 0.6).round();
      case SkillLevel.advanced:
        return (baseTime * 0.5).round();
    }
  }

  /// Get prerequisites for a concept
  List<String> _getPrerequisitesForConcept(String concept) {
    final prerequisites = {
      'loops': ['sequences'],
      'conditionals': ['sequences'],
      'variables': ['sequences'],
      'functions': ['sequences', 'variables'],
      'debugging': ['sequences'],
      'patterns': ['sequences', 'loops'],
      'structure': ['sequences', 'functions'],
    };

    return prerequisites[concept] ?? [];
  }

  /// Get resources for learning a concept
  List<Map<String, dynamic>> _getResourcesForConcept(String concept, SkillLevel skillLevel) {
    // This would typically come from a database or API
    // For now, we'll return placeholder data
    return [
      {
        'type': 'story',
        'title': 'Learning ${_getConceptTitle(concept)}',
        'description': 'An interactive story to learn about $concept',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'challenge',
        'title': '$concept Challenge',
        'description': 'Practice your $concept skills with this challenge',
        'difficulty': skillLevel.toString().split('.').last,
      },
      {
        'type': 'tutorial',
        'title': '$concept Tutorial',
        'description': 'Step-by-step tutorial on $concept',
        'difficulty': skillLevel.toString().split('.').last,
      },
    ];
  }

  /// Get challenges for a concept
  List<Map<String, dynamic>> _getChallengesForConcept(String concept, SkillLevel skillLevel) {
    // This would typically come from a database or API
    // For now, we'll return placeholder data
    return [
      {
        'id': '${concept}_basic',
        'title': 'Basic $concept Challenge',
        'description': 'A simple challenge to practice $concept',
        'difficulty': 1,
      },
      {
        'id': '${concept}_intermediate',
        'title': 'Intermediate $concept Challenge',
        'description': 'A more complex challenge to deepen your understanding of $concept',
        'difficulty': 2,
      },
      {
        'id': '${concept}_advanced',
        'title': 'Advanced $concept Challenge',
        'description': 'A challenging exercise to master $concept',
        'difficulty': 3,
      },
    ];
  }

  /// Initialize learning analytics
  void _initializeLearningAnalytics() {
    _learningAnalytics = {
      'skillProgress': _calculateSkillProgress(),
      'conceptMastery': _calculateConceptMastery(),
      'learningRate': _calculateLearningRate(),
      'engagementScore': _userProgress.calculateEngagementScore(),
      'challengeCompletion': _calculateChallengeCompletion(),
      'timeSpent': _userProgress.preferences['totalTimeSpentMinutes'] ?? 0,
      'strengths': _identifyStrengths(),
      'areasForImprovement': _identifyAreasForImprovement(),
      'learningStyle': _analysisService.getPrimaryLearningStyle().toStringValue(),
      'recommendedActivities': _generateRecommendedActivities(),
    };
  }

  /// Calculate skill progress percentages
  Map<String, double> _calculateSkillProgress() {
    final Map<String, double> progress = {};

    // Calculate progress for each skill type
    for (final skillType in SkillType.values) {
      final skillLevel = _userProgress.skills[skillType] ?? SkillLevel.novice;

      // Convert skill level to progress percentage
      double percentage = 0.0;
      switch (skillLevel) {
        case SkillLevel.novice:
          percentage = 0.25;
          break;
        case SkillLevel.beginner:
          percentage = 0.5;
          break;
        case SkillLevel.intermediate:
          percentage = 0.75;
          break;
        case SkillLevel.advanced:
          percentage = 1.0;
          break;
      }

      progress[skillType.toString().split('.').last] = percentage;
    }

    return progress;
  }

  /// Calculate concept mastery percentages
  Map<String, double> _calculateConceptMastery() {
    final Map<String, double> mastery = {};

    // Get proficiency for each concept
    _userProgress.skillProficiency.forEach((concept, proficiency) {
      mastery[concept] = proficiency;
    });

    return mastery;
  }

  /// Calculate learning rate (concepts mastered per day)
  double _calculateLearningRate() {
    final int conceptsMastered = _userProgress.conceptsMastered.length;
    final int daysActive = _userProgress.preferences['daysActive'] ?? 1;

    return conceptsMastered / daysActive;
  }

  /// Calculate challenge completion rate
  double _calculateChallengeCompletion() {
    final int completedChallenges = _userProgress.completedChallenges.length;
    final int totalChallenges = _userProgress.challengeAttempts.length;

    if (totalChallenges == 0) return 0.0;
    return completedChallenges / totalChallenges;
  }

  /// Identify user's strengths
  List<String> _identifyStrengths() {
    final List<String> strengths = [];

    // Check skill proficiency
    _userProgress.skillProficiency.forEach((concept, proficiency) {
      if (proficiency >= 0.8) {
        strengths.add(concept);
      }
    });

    // Check skill levels
    _userProgress.skills.forEach((skillType, skillLevel) {
      if (skillLevel == SkillLevel.advanced) {
        strengths.add(skillType.toString().split('.').last);
      }
    });

    return strengths;
  }

  /// Identify areas for improvement
  List<String> _identifyAreasForImprovement() {
    final List<String> areasForImprovement = [];

    // Check skill proficiency
    _userProgress.skillProficiency.forEach((concept, proficiency) {
      if (proficiency < 0.4 && proficiency > 0) {
        areasForImprovement.add(concept);
      }
    });

    // Check skill levels
    _userProgress.skills.forEach((skillType, skillLevel) {
      if (skillLevel == SkillLevel.novice) {
        areasForImprovement.add(skillType.toString().split('.').last);
      }
    });

    return areasForImprovement;
  }

  /// Generate recommended activities based on user progress
  List<Map<String, dynamic>> _generateRecommendedActivities() {
    final List<Map<String, dynamic>> activities = [];

    // Add activities based on learning style
    final learningStyle = _analysisService.getPrimaryLearningStyle();

    switch (learningStyle) {
      case LearningStyle.visual:
        activities.add({
          'type': 'pattern_creation',
          'title': 'Create a Visual Pattern',
          'description': 'Create a visual pattern using blocks',
        });
        break;
      case LearningStyle.logical:
        activities.add({
          'type': 'challenge',
          'title': 'Logic Challenge',
          'description': 'Solve a logical challenge',
        });
        break;
      case LearningStyle.practical:
        activities.add({
          'type': 'project',
          'title': 'Hands-on Project',
          'description': 'Build a practical project',
        });
        break;
      case LearningStyle.verbal:
        activities.add({
          'type': 'story',
          'title': 'Interactive Story',
          'description': 'Explore an interactive story',
        });
        break;
      case LearningStyle.social:
        activities.add({
          'type': 'sharing',
          'title': 'Share Your Creation',
          'description': 'Share your creation with others',
        });
        break;
      case LearningStyle.reflective:
        activities.add({
          'type': 'reflection',
          'title': 'Reflect on Your Learning',
          'description': 'Reflect on what you\'ve learned',
        });
        break;
    }

    // Add activities based on areas for improvement
    final areasForImprovement = _identifyAreasForImprovement();
    if (areasForImprovement.isNotEmpty) {
      final area = areasForImprovement.first;
      activities.add({
        'type': 'practice',
        'title': 'Practice $area',
        'description': 'Improve your $area skills',
      });
    }

    // Add activities based on incomplete milestones
    for (final milestone in _milestones) {
      if (!_completedMilestones.contains(milestone['id'])) {
        activities.add({
          'type': 'milestone',
          'title': milestone['title'],
          'description': milestone['description'],
        });
        break; // Just add one milestone activity
      }
    }

    return activities;
  }

  /// Update skill based on challenge result
  Future<void> updateSkill(String conceptId, bool success, double difficulty) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProgress = await _learningService.updateSkillProficiency(
        _userProgress.userId,
        conceptId,
        success,
        difficulty,
      );

      _userProgress = updatedProgress;

      // Track skill progression history
      _trackSkillProgression(conceptId, _userProgress.skillProficiency[conceptId] ?? 0.0);

      // Check for newly earned badges
      final newBadges = await _badgeService.checkForNewBadges(_userProgress.userId);
      if (newBadges.isNotEmpty) {
        _earnedBadges.addAll(newBadges);
      }

      // Check for completed milestones
      await _checkMilestones();

      // Update learning path
      await _generateLearningPath();

      // Update learning analytics
      _updateLearningAnalytics();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating skill: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Track skill progression history
  void _trackSkillProgression(String conceptId, double proficiency) {
    if (!_skillProgressionHistory.containsKey(conceptId)) {
      _skillProgressionHistory[conceptId] = [];
    }

    _skillProgressionHistory[conceptId]!.add({
      'timestamp': DateTime.now().toIso8601String(),
      'proficiency': proficiency,
    });

    // Limit history size
    if (_skillProgressionHistory[conceptId]!.length > 20) {
      _skillProgressionHistory[conceptId]!.removeAt(0);
    }
  }

  /// Update learning analytics
  void _updateLearningAnalytics() {
    _learningAnalytics = {
      'skillProgress': _calculateSkillProgress(),
      'conceptMastery': _calculateConceptMastery(),
      'learningRate': _calculateLearningRate(),
      'engagementScore': _userProgress.calculateEngagementScore(),
      'challengeCompletion': _calculateChallengeCompletion(),
      'timeSpent': _userProgress.preferences['totalTimeSpentMinutes'] ?? 0,
      'strengths': _identifyStrengths(),
      'areasForImprovement': _identifyAreasForImprovement(),
      'learningStyle': _analysisService.getPrimaryLearningStyle().toStringValue(),
      'recommendedActivities': _generateRecommendedActivities(),
      'skillProgressionHistory': _skillProgressionHistory,
    };
  }

  /// Record a learning action
  Future<void> recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) async {
    await _learningService.recordAction(
      actionType: actionType,
      wasSuccessful: wasSuccessful,
      contextId: contextId,
      metadata: metadata,
    );

    // Update time spent if provided
    if (metadata != null && metadata.containsKey('timeSpentMinutes')) {
      final timeSpent = metadata['timeSpentMinutes'] as int;
      final totalTimeSpent = (_userProgress.preferences['totalTimeSpentMinutes'] ?? 0) + timeSpent;
      _userProgress = _userProgress.setPreference('totalTimeSpentMinutes', totalTimeSpent);
      await _learningService.saveUserProgress(_userProgress);
    }

    // Update cultural exploration count if applicable
    if (actionType == 'cultural_exploration') {
      final explorationCount = (_userProgress.preferences['culturalExplorationCount'] ?? 0) + 1;
      _userProgress = _userProgress.setPreference('culturalExplorationCount', explorationCount);
      await _learningService.saveUserProgress(_userProgress);

      // Check for completed milestones
      await _checkMilestones();
    }

    // Update pattern count if applicable
    if (actionType == 'pattern_creation') {
      final patternCount = (_userProgress.preferences['patternCount'] ?? 0) + 1;
      _userProgress = _userProgress.setPreference('patternCount', patternCount);
      await _learningService.saveUserProgress(_userProgress);

      // Check for completed milestones
      await _checkMilestones();
    }

    // Update learning analytics
    _updateLearningAnalytics();

    notifyListeners();
  }

  /// Mark a story as completed
  Future<void> markStoryCompleted(String storyId) async {
    if (_userProgress.completedStoryBranches.contains(storyId)) {
      return; // Already completed
    }

    _userProgress = _userProgress.addCompletedStoryBranch(storyId);
    await _learningService.saveUserProgress(_userProgress);

    // Record action for adaptive learning
    await recordAction(
      actionType: 'story_progress',
      wasSuccessful: true,
      contextId: storyId,
    );

    // Check for completed milestones
    await _checkMilestones();

    // Update learning path
    await _generateLearningPath();

    notifyListeners();
  }

  /// Save a user preference
  Future<void> savePreference(String key, dynamic value) async {
    _userProgress = _userProgress.setPreference(key, value);
    await _learningService.saveUserProgress(_userProgress);

    // Check for completed milestones if relevant
    if (key == 'culturalExplorationCount' || key == 'patternCount') {
      await _checkMilestones();
    }

    notifyListeners();
  }

  /// Get a hint priority based on user progress
  int getHintPriority(String hintType) {
    return _learningService.getHintPriority(hintType);
  }

  /// Check if user has a specific badge
  bool hasBadge(String badgeId) {
    return _earnedBadges.any((badge) => badge.id == badgeId);
  }

  /// Award a badge (for testing/admin purposes)
  Future<void> awardBadge(String badgeId) async {
    await _badgeService.awardBadge(_userProgress.userId, badgeId);
    _earnedBadges = await _badgeService.getUserBadges(_userProgress.userId);
    notifyListeners();
  }
}

