import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/services/badge_service.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

/// Provider for learning state management
class LearningProvider with ChangeNotifier {
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final BadgeService _badgeService = BadgeService();
  
  UserProgress _userProgress = UserProgress(userId: 'default');
  bool _isLoading = false;
  String? _recommendedConcept;
  List<String> _conceptsToReview = [];
  List<BadgeModel> _earnedBadges = [];
  
  /// Getters for state
  UserProgress get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get recommendedConcept => _recommendedConcept;
  List<String> get conceptsToReview => _conceptsToReview;
  List<BadgeModel> get earnedBadges => _earnedBadges;
  
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
        _userProgress = UserProgress(userId: userId);
        await _learningService.saveUserProgress(_userProgress);
      }
      
      // Load earned badges
      _earnedBadges = await _badgeService.getUserBadges(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing LearningProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
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
      
      // Check for newly earned badges
      final newBadges = await _badgeService.checkForNewBadges(_userProgress.userId);
      if (newBadges.isNotEmpty) {
        _earnedBadges.addAll(newBadges);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating skill: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Record a learning action
  void recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) {
    _learningService.recordAction(
      actionType: actionType,
      wasSuccessful: wasSuccessful,
      contextId: contextId,
      metadata: metadata,
    );
    
    // We don't need to notify listeners here as this doesn't directly affect UI
  }
  
  /// Mark a story as completed
  Future<void> markStoryCompleted(String storyId) async {
    if (_userProgress.completedStoryBranches.contains(storyId)) {
      return; // Already completed
    }
    
    _userProgress.completedStoryBranches.add(storyId);
    await _learningService.saveUserProgress(_userProgress);
    
    // Record action for adaptive learning
    recordAction(
      actionType: 'story_progress',
      wasSuccessful: true,
      contextId: storyId,
    );
    
    notifyListeners();
  }
  
  /// Save a user preference
  Future<void> savePreference(String key, dynamic value) async {
    _userProgress.setPreference(key, value);
    await _learningService.saveUserProgress(_userProgress);
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