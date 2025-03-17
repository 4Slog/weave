import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// A service that adapts the learning experience based on user progress and actions
class AdaptiveLearningService {
  // Singleton implementation
  static final AdaptiveLearningService _instance = AdaptiveLearningService._internal();
  
  factory AdaptiveLearningService() {
    return _instance;
  }
  
  AdaptiveLearningService._internal();
  
  // Current user progress
  UserProgress? _userProgress;
  
  // Tracks consecutive successes/failures for skill assessment
  int _consecutiveSuccesses = 0;
  int _consecutiveFailures = 0;
  
  // Track time spent on different activities
  Map<String, int> _timeSpentOnActivities = {};
  
  // Track usage patterns
  List<Map<String, dynamic>> _recentActions = [];
  
  // Maximum actions to track
  static const int _maxRecentActions = 50;
  
  // Skill threshold for mastery
  static const double _masteryThreshold = 0.8;
  
  /// Initialize the service with user progress
  Future<void> initialize({UserProgress? userProgress}) async {
    if (userProgress != null) {
      _userProgress = userProgress;
    } else {
      await _loadUserProgress();
    }
    
    // Initialize tracking maps
    _timeSpentOnActivities = {};
    _recentActions = [];
  }
  
  /// Load user progress from shared preferences
  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_progress');
      
      if (userJson != null) {
        _userProgress = UserProgress.fromJson(jsonDecode(userJson));
      } else {
        // Create default user progress
        _userProgress = UserProgress(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Learner',
        );
        await _saveUserProgress();
      }
    } catch (e) {
      debugPrint('Failed to load user progress: $e');
      // Create default user progress
      _userProgress = UserProgress(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Learner',
      );
    }
  }
  
  /// Save user progress to shared preferences
  Future<void> _saveUserProgress() async {
    if (_userProgress == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress', jsonEncode(_userProgress!.toJson()));
    } catch (e) {
      debugPrint('Failed to save user progress: $e');
    }
  }
  
  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    if (_userProgress != null && _userProgress!.userId == userId) {
      return _userProgress;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_progress_$userId');
    
    if (userJson != null) {
      try {
        return UserProgress.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error parsing user progress: $e');
      }
    }
    
    // Return default if not found
    return UserProgress(userId: userId, displayName: 'Learner');
  }
  
  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    // Update cached progress if it's the same user
    if (_userProgress != null && _userProgress!.userId == progress.userId) {
      _userProgress = progress;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress_${progress.userId}', jsonEncode(progress.toJson()));
    } catch (e) {
      debugPrint('Error saving user progress: $e');
    }
  }
  
  /// Record a user action
  void recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) {
    if (_userProgress == null) return;
    
    // Record action timestamp
    final timestamp = DateTime.now();
    
    // Update consecutive counters
    if (wasSuccessful) {
      _consecutiveSuccesses++;
      _consecutiveFailures = 0;
    } else {
      _consecutiveFailures++;
      _consecutiveSuccesses = 0;
    }
    
    // Store action data
    final action = {
      'actionType': actionType,
      'wasSuccessful': wasSuccessful,
      'timestamp': timestamp.toIso8601String(),
      'contextId': contextId,
      'metadata': metadata ?? {},
    };
    
    // Add to recent actions, maintaining the maximum size
    _recentActions.add(action);
    if (_recentActions.length > _maxRecentActions) {
      _recentActions.removeAt(0);
    }
    
    // Update skills based on action
    _updateSkillsBasedOnAction(actionType, wasSuccessful, metadata);
    
    // Consider awarding experience
    if (wasSuccessful) {
      int xpAmount = _calculateExperienceForAction(actionType, metadata);
      if (_userProgress != null) {
        _userProgress!.addExperience(xpAmount);
      }
    }
    
    // Save the updated progress
    _saveUserProgress();
  }
  
  /// Calculate experience points for an action
  int _calculateExperienceForAction(String actionType, Map<String, dynamic>? metadata) {
    // Base XP values for different action types
    switch (actionType) {
      case 'challenge_completion':
        int difficulty = metadata?['difficulty'] ?? 1;
        return 10 * difficulty;
      
      case 'pattern_creation':
        int blockCount = metadata?['blockCount'] ?? 1;
        return 5 + (blockCount * 2);
      
      case 'story_progress':
        return 15;
      
      case 'cultural_exploration':
        return 8;
      
      case 'block_connection':
        return 1; // Small reward for basic interaction
        
      default:
        return 5; // Default XP amount
    }
  }
  
  /// Update skills based on user actions
  void _updateSkillsBasedOnAction(String actionType, bool wasSuccessful, Map<String, dynamic>? metadata) {
    if (_userProgress == null) return;
    
    switch (actionType) {
      case 'challenge_completion':
        if (wasSuccessful) {
          // Determine which skill to update based on challenge type
          final challengeType = metadata?['challengeType'];
          if (challengeType != null) {
            SkillType? skillType;
            
            if (challengeType == 'loops') {
              skillType = SkillType.loops;
            } else if (challengeType == 'conditionals') {
              skillType = SkillType.conditionals;
            } else if (challengeType == 'patterns') {
              skillType = SkillType.patterns;
            } else if (challengeType == 'cultural') {
              skillType = SkillType.culturalContext;
            }
            
            if (skillType != null) {
              _updateSkill(skillType, true);
            }
          }
        }
        break;
        
      case 'story_progress':
        _updateSkill(SkillType.storytelling, true);
        break;
        
      case 'pattern_creation':
        _updateSkill(SkillType.patterns, true);
        break;
        
      case 'cultural_exploration':
        _updateSkill(SkillType.culturalContext, true);
        break;
        
      case 'debug_success':
        _updateSkill(SkillType.debugging, true);
        break;
        
      case 'debug_failure':
        _updateSkill(SkillType.debugging, false);
        break;
    }
  }
  
  /// Update skill level
  void _updateSkill(SkillType skillType, bool success) {
    if (_userProgress == null) return;
    
    SkillLevel currentLevel = _userProgress!.skills[skillType] ?? SkillLevel.novice;
    
    // Apply skill update based on success/failure
    if (success) {
      if (_consecutiveSuccesses >= 3) {
        // Consider promoting skill level on consistent success
        _userProgress!.improveSkill(skillType);
      }
    } else if (_consecutiveFailures >= 5) {
      // Consider demoting skill level on consistent failure (harder to demote)
      // This would require an additional method in UserProgress
    }
  }
  
  /// Update skill proficiency based on challenge results
  Future<UserProgress> updateSkillProficiency(
    String userId,
    String conceptId,
    bool success,
    double difficulty,
  ) async {
    final progress = await getUserProgress(userId);
    if (progress == null) {
      return UserProgress(userId: userId);
    }
    
    // Here we would update the skill proficiency based on the concept and result
    // As we're just updating the cached values, we'll return the progress as-is
    
    // In a fully implemented version, we would:
    // 1. Get current proficiency for the concept
    // 2. Update based on success/failure and difficulty
    // 3. Update mastered/in-progress lists
    // 4. Save updated progress
    
    return progress;
  }
  
  /// Get hint priority based on hint type and user skills
  int getHintPriority(String hintType) {
    if (_userProgress == null) {
      return 5; // Default mid-priority if no user progress
    }
    
    int priority = 5; // Default priority
    
    switch (hintType) {
      case 'loop':
        // Higher priority if struggling with loops
        final loopSkill = _userProgress!.getSkillLevel(SkillType.loops);
        if (loopSkill < 2) {
          priority += 3;
        }
        break;
        
      case 'conditional':
        // Higher priority if struggling with conditionals
        final conditionalSkill = _userProgress!.getSkillLevel(SkillType.conditionals);
        if (conditionalSkill < 2) {
          priority += 3;
        }
        break;
        
      case 'pattern':
        // Higher priority if good with patterns
        final patternSkill = _userProgress!.getSkillLevel(SkillType.patterns);
        if (patternSkill >= 1) {
          priority += 2;
        }
        break;
        
      case 'cultural':
        // Higher priority for cultural hints if the user shows interest
        final culturalSkill = _userProgress!.getSkillLevel(SkillType.culturalContext);
        priority += culturalSkill;
        
        // Boost if user has shown interest in cultural aspects
        if (_userProgress!.preferences.containsKey('interestedInCulture') && 
            _userProgress!.preferences['interestedInCulture'] == true) {
          priority += 2;
        }
        break;
        
      case 'debug':
        // Higher priority if user is actively debugging
        if (_consecutiveFailures >= 3) {
          priority += 4;
        }
        break;
    }
    
    // Ensure priority is within bounds
    return min(10, max(0, priority));
  }
  
  /// Get the user progress
  UserProgress? get userProgress => _userProgress;
  
  /// Get time spent on activities
  Map<String, int> get timeSpentOnActivities => Map.from(_timeSpentOnActivities);
  
  /// Get recent user actions
  List<Map<String, dynamic>> get recentActions => List.from(_recentActions);
}