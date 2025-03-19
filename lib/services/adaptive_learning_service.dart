import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/skill_type.dart';
import 'package:kente_codeweaver/models/skill_level.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/cultural_data_service.dart';
import 'package:kente_codeweaver/services/learning_analysis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Extension methods for UserProgress to handle adaptive learning operations
extension AdaptiveLearningExtensions on UserProgress {
  /// Add experience points to the user progress
  UserProgress addExperience(int amount) {
    final newXp = experiencePoints + amount;
    
    // Calculate new level based on XP
    int newLevel = level;
    final xpForNextLevel = level * 100;
    
    if (newXp >= xpForNextLevel) {
      newLevel = (newXp / 100).floor() + 1;
    }
    
    return copyWith(
      experiencePoints: newXp,
      level: newLevel,
    );
  }
  
  /// Update learning style confidence
  UserProgress updateLearningStyleConfidence(LearningStyle style, double confidence) {
    final newConfidence = Map<LearningStyle, double>.from(learningStyleConfidence);
    newConfidence[style] = confidence;
    
    return copyWith(
      learningStyleConfidence: newConfidence,
    );
  }
  
  /// Update skill proficiency for a concept
  UserProgress updateSkillProficiency(String conceptId, double proficiency) {
    final newProficiency = Map<String, double>.from(skillProficiency);
    newProficiency[conceptId] = proficiency;
    
    // If proficiency is high enough, consider mastering the concept
    if (proficiency >= 0.8 && !conceptsMastered.contains(conceptId)) {
      final newMastered = List<String>.from(conceptsMastered)..add(conceptId);
      final newInProgress = List<String>.from(conceptsInProgress)..remove(conceptId);
      
      return copyWith(
        skillProficiency: newProficiency,
        conceptsMastered: newMastered,
        conceptsInProgress: newInProgress,
      );
    }
    
    // If not mastered but not in progress, add to in-progress
    if (proficiency > 0.0 && 
        proficiency < 0.8 && 
        !conceptsInProgress.contains(conceptId) &&
        !conceptsMastered.contains(conceptId)) {
      final newInProgress = List<String>.from(conceptsInProgress)..add(conceptId);
      
      return copyWith(
        skillProficiency: newProficiency,
        conceptsInProgress: newInProgress,
      );
    }
    
    return copyWith(
      skillProficiency: newProficiency,
    );
  }
  
  /// Improve a skill by one level
  UserProgress improveSkill(SkillType skillType) {
    final newSkills = Map<SkillType, SkillLevel>.from(skills);
    
    // Get current level
    final currentLevel = newSkills[skillType] ?? SkillLevel.novice;
    
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
    newSkills[skillType] = nextLevel;
    
    return copyWith(
      skills: newSkills,
    );
  }
}

/// A service that adapts the learning experience based on user progress and actions
class AdaptiveLearningService {
  // Singleton implementation
  static final AdaptiveLearningService _instance = AdaptiveLearningService._internal();
  
  factory AdaptiveLearningService() {
    return _instance;
  }
  
  AdaptiveLearningService._internal();
  
  // Services
  final StorageService _storageService = StorageService();
  final CulturalDataService _culturalDataService = CulturalDataService();
  final LearningAnalysisService _analysisService = LearningAnalysisService();
  
  // Current user progress
  UserProgress? _userProgress;
  
  // Tracks consecutive successes/failures for skill assessment
  int _consecutiveSuccesses = 0;
  int _consecutiveFailures = 0;
  
  // Challenge history tracking
  List<Map<String, dynamic>> _challengeHistory = [];
  
  // Track time spent on different activities
  Map<String, int> _timeSpentOnActivities = {};
  
  // Track interaction patterns
  List<Map<String, dynamic>> _recentActions = [];
  
  // Maximum actions to track
  static const int _maxRecentActions = 50;
  
  // Skill mastery threshold
  static const double _masteryThreshold = 0.8;
  
  // Skill concept mapping - connects coding concepts to skill types
  final Map<String, SkillType> _conceptToSkillMap = {
    'loops': SkillType.loops,
    'conditionals': SkillType.conditionals,
    'sequences': SkillType.sequences,
    'patterns': SkillType.patterns,
    'variables': SkillType.variables,
    'functions': SkillType.functions,
    'debugging': SkillType.debugging,
    'structure': SkillType.structure,
    'cultural': SkillType.culturalContext,
    'storytelling': SkillType.storytelling,
  };
  
  /// Initialize the service with user progress
  Future<void> initialize({UserProgress? userProgress}) async {
    if (userProgress != null) {
      _userProgress = userProgress;
    } else {
      await _loadUserProgress();
    }
    
    // Initialize the cultural data service
    await _culturalDataService.initialize();
    
    // Initialize tracking maps
    _timeSpentOnActivities = {};
    _recentActions = [];
    
    // Initialize learning style points
    if (_userProgress != null) {
      _analysisService.initializeLearningStylePoints(_userProgress!);
    }
    
    // Load challenge history
    await _loadChallengeHistory();
  }
  
  /// Load user progress from storage
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
          name: 'Learner',
        );
        await _saveUserProgress();
      }
    } catch (e) {
      debugPrint('Failed to load user progress: $e');
      // Create default user progress
      _userProgress = UserProgress(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Learner',
      );
    }
  }
  
  /// Load challenge history from storage
  Future<void> _loadChallengeHistory() async {
    try {
      final historyData = await _storageService.getSetting('challenge_history');
      if (historyData != null) {
        _challengeHistory = List<Map<String, dynamic>>.from(jsonDecode(historyData));
      }
    } catch (e) {
      debugPrint('Error loading challenge history: $e');
    }
  }
  
  /// Save user progress to storage
  Future<void> _saveUserProgress() async {
    if (_userProgress == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress', jsonEncode(_userProgress!.toJson()));
      
      // Also save challenge data
      await _saveChallengeHistory();
    } catch (e) {
      debugPrint('Failed to save user progress: $e');
    }
  }
  
  /// Save challenge history to storage
  Future<void> _saveChallengeHistory() async {
    try {
      await _storageService.saveSetting(
        'challenge_history', 
        jsonEncode(_challengeHistory),
      );
    } catch (e) {
      debugPrint('Error saving challenge history: $e');
    }
  }
  
  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    if (_userProgress != null && _userProgress!.userId == userId) {
      return _userProgress;
    }
    
    try {
      final userProgress = await _storageService.getUserProgress(userId);
      if (userProgress != null) {
        _userProgress = userProgress;
        return userProgress;
      }
    } catch (e) {
      debugPrint('Error getting user progress: $e');
    }
    
    // Return default if not found
    return UserProgress(userId: userId, name: 'Learner');
  }
  
  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    // Update cached progress if it's the same user
    if (_userProgress != null && _userProgress!.userId == progress.userId) {
      _userProgress = progress;
    }
    
    try {
      await _storageService.saveUserProgress(progress);
    } catch (e) {
      debugPrint('Error saving user progress: $e');
    }
  }
  
  /// Record a user action for skill and learning style analysis
  Future<void> recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) async {
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
      'userId': _userProgress!.userId,
    };
    
    // Add to recent actions, maintaining the maximum size
    _recentActions.add(action);
    if (_recentActions.length > _maxRecentActions) {
      _recentActions.removeAt(0);
    }
    
    // Update skills based on action
    await _updateSkillsBasedOnAction(actionType, wasSuccessful, metadata);
    
    // Update learning style points based on action
    _analysisService.updateLearningStylePoints(actionType, metadata);
    await _updateLearningStyleInUserProgress();
    
    // Consider awarding experience
    if (wasSuccessful) {
      int xpAmount = _analysisService.calculateExperienceForAction(actionType, metadata);
      if (_userProgress != null) {
        _userProgress = _userProgress!.addExperience(xpAmount);
        await saveUserProgress(_userProgress!);
      }
    }
  }
  
  /// Update learning style points in user progress
  Future<void> _updateLearningStyleInUserProgress() async {
    if (_userProgress == null) return;
    
    // Get confidence values from analysis service
    Map<LearningStyle, double> confidences = _analysisService.getLearningStyleConfidence();
    
    // Update user progress with new confidence values
    UserProgress updatedProgress = _userProgress!;
    
    // Update each learning style confidence
    for (var entry in confidences.entries) {
      updatedProgress = updatedProgress.updateLearningStyleConfidence(entry.key, entry.value);
    }
    
    // Save updated progress
    _userProgress = updatedProgress;
    await saveUserProgress(updatedProgress);
  }
  
  /// Update skills based on user actions
  Future<void> _updateSkillsBasedOnAction(String actionType, bool wasSuccessful, Map<String, dynamic>? metadata) async {
    if (_userProgress == null) return;
    
    UserProgress updatedProgress = _userProgress!;
    
    switch (actionType) {
      case 'challenge_completion':
        if (wasSuccessful) {
          // Determine which skill to update based on challenge type
          final challengeType = metadata?['challengeType'];
          final difficulty = metadata?['difficulty'] ?? 1;
          
          if (challengeType != null) {
            // Map challenge type to skill
            SkillType? skillType = _getSkillTypeFromConcept(challengeType);
            
            if (skillType != null) {
              // Update skill proficiency
              double proficiencyChange = wasSuccessful ? 0.1 * difficulty : -0.05 * difficulty;
              double currentProficiency = _getConceptProficiency(challengeType);
              double newProficiency = (currentProficiency + proficiencyChange).clamp(0.0, 1.0);
              
              // Update user progress
              updatedProgress = updatedProgress.updateSkillProficiency(challengeType, newProficiency);
              
              // Update skill level if needed
              if (wasSuccessful && _consecutiveSuccesses >= 3) {
                updatedProgress = updatedProgress.improveSkill(skillType);
              }
            }
          }
          
          // Record in challenge history
          if (metadata != null && metadata.containsKey('challengeId')) {
            _recordChallengeCompletion(
              metadata['challengeId'], 
              wasSuccessful, 
              metadata['difficulty'] ?? 1,
              metadata['concepts'] ?? [],
            );
          }
        }
        break;
        
      case 'story_progress':
        // Update storytelling skill
        double currentProficiency = _getConceptProficiency('storytelling');
        double newProficiency = (currentProficiency + 0.1).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('storytelling', newProficiency);
        updatedProgress = updatedProgress.improveSkill(SkillType.storytelling);
        break;
        
      case 'pattern_creation':
        // Update pattern skill
        double currentProficiency = _getConceptProficiency('patterns');
        double newProficiency = (currentProficiency + 0.1).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('patterns', newProficiency);
        updatedProgress = updatedProgress.improveSkill(SkillType.patterns);
        break;
        
      case 'cultural_exploration':
        // Update cultural context skill
        double currentProficiency = _getConceptProficiency('cultural');
        double newProficiency = (currentProficiency + 0.1).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('cultural', newProficiency);
        updatedProgress = updatedProgress.improveSkill(SkillType.culturalContext);
        break;
        
      case 'debug_success':
        // Update debugging skill
        double currentProficiency = _getConceptProficiency('debugging');
        double newProficiency = (currentProficiency + 0.1).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('debugging', newProficiency);
        updatedProgress = updatedProgress.improveSkill(SkillType.debugging);
        break;
        
      case 'debug_failure':
        // Slight negative adjustment to debugging skill
        double currentProficiency = _getConceptProficiency('debugging');
        double newProficiency = (currentProficiency - 0.05).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('debugging', newProficiency);
        break;
        
      case 'block_connection':
        // Minor update to structure skill
        double currentProficiency = _getConceptProficiency('structure');
        double newProficiency = (currentProficiency + 0.05).clamp(0.0, 1.0);
        updatedProgress = updatedProgress.updateSkillProficiency('structure', newProficiency);
        updatedProgress = updatedProgress.improveSkill(SkillType.structure);
        break;
    }
    
    // Save updated progress
    _userProgress = updatedProgress;
    await saveUserProgress(updatedProgress);
  }
  
  /// Get concept proficiency from user progress
  double _getConceptProficiency(String conceptId) {
    if (_userProgress == null) return 0.0;
    
    // Check if the concept exists in the skill proficiency map
    if (_userProgress!.skillProficiency.containsKey(conceptId)) {
      return _userProgress!.skillProficiency[conceptId] ?? 0.0;
    }
    
    return 0.0; // Default proficiency
  }
  
  /// Record a challenge completion in history
  void _recordChallengeCompletion(
    String challengeId, 
    bool success, 
    int difficulty,
    List<dynamic> concepts
  ) {
    // Record challenge completion
    _challengeHistory.add({
      'challengeId': challengeId,
      'timestamp': DateTime.now().toIso8601String(),
      'success': success,
      'difficulty': difficulty,
      'userId': _userProgress?.userId ?? 'unknown',
      'concepts': concepts,
    });
    
    // Ensure challenge history doesn't grow too large
    if (_challengeHistory.length > 100) {
      _challengeHistory.removeAt(0);
    }
    
    // Update user progress completed challenges
    if (success && _userProgress != null && !_userProgress!.completedChallenges.contains(challengeId)) {
      _userProgress = _userProgress!.addCompletedChallenge(challengeId);
    }
  }
  
  /// Get skill type from concept name
  SkillType? _getSkillTypeFromConcept(String concept) {
    return _conceptToSkillMap[concept.toLowerCase()];
  }
  
  /// Update skill proficiency based on challenge results
  Future<UserProgress> updateSkillProficiency(
    String userId,
    String conceptId,
    bool success,
    double difficulty,
  ) async {
    // Get the user progress
    UserProgress? progress = await getUserProgress(userId);
    if (progress == null) {
      return UserProgress(userId: userId, name: 'Learner');
    }
    
    // Calculate proficiency change
    double proficiencyChange = success ? 0.1 * difficulty : -0.05 * difficulty;
    double currentProficiency = progress.skillProficiency[conceptId] ?? 0.0;
    double newProficiency = (currentProficiency + proficiencyChange).clamp(0.0, 1.0);
    
    // Update skill proficiency
    progress = progress.updateSkillProficiency(conceptId, newProficiency);
    
    // Map to skill type
    SkillType? skillType = _getSkillTypeFromConcept(conceptId);
    if (skillType != null && success) {
      // Update UserProgress skills
      progress = progress.improveSkill(skillType);
    }
    
    // Save updated progress
    await saveUserProgress(progress);
    
    return progress;
  }
  
  /// Complete a challenge with related skills
  Future<void> completeChallenge(
    String challengeId, {
    double difficulty = 1.0,
    List<String> improvedSkills = const [],
  }) async {
    if (_userProgress == null) return;
    
    UserProgress updatedProgress = _userProgress!;
    
    // Add challenge to completed list if not already there
    if (!updatedProgress.completedChallenges.contains(challengeId)) {
      updatedProgress = updatedProgress.addCompletedChallenge(challengeId);
    }
    
    // Record in challenge history
    _recordChallengeCompletion(
      challengeId, 
      true, 
      difficulty.toInt(), 
      improvedSkills,
    );
    
    // Update skills
    for (var skill in improvedSkills) {
      // Calculate proficiency change
      double proficiencyChange = 0.1 * difficulty;
      double currentProficiency = updatedProgress.skillProficiency[skill] ?? 0.0;
      double newProficiency = (currentProficiency + proficiencyChange).clamp(0.0, 1.0);
      
      // Update skill proficiency
      updatedProgress = updatedProgress.updateSkillProficiency(skill, newProficiency);
      
      // Map to skill type and update user progress
      SkillType? skillType = _getSkillTypeFromConcept(skill);
      if (skillType != null) {
        updatedProgress = updatedProgress.improveSkill(skillType);
      }
    }
    
    // Save the updated progress
    _userProgress = updatedProgress;
    await saveUserProgress(updatedProgress);
  }
  
  /// Validate solution against challenge requirements
  Future<bool> validateSolution(
    String userId,
    String challengeId,
    List<BlockModel> blocks,
  ) async {
    // This would be a more complex validation in a real implementation
    // For now, we'll just return a simple size check
    return blocks.length >= 2;
  }
  
  /// Track learning progress
  Future<void> trackProgress(
    String userId,
    String contextId,
    bool success,
    int elementCount,
  ) async {
    // Record the action
    recordAction(
      actionType: 'challenge_completion',
      wasSuccessful: success,
      contextId: contextId,
      metadata: {
        'challengeId': contextId,
        'blockCount': elementCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Get hint priority based on hint type and user skills
  int getHintPriority(String hintType) {
    if (_userProgress == null) {
      return 5; // Default mid-priority if no user progress
    }
    
    return _analysisService.getHintPriority(hintType, _userProgress!);
  }
  
  /// Get the user's primary learning style
  LearningStyle getPrimaryLearningStyle() {
    return _analysisService.getPrimaryLearningStyle();
  }
  
  /// Get all learning styles that meet the threshold
  List<LearningStyle> getSignificantLearningStyles() {
    return _analysisService.getSignificantLearningStyles();
  }
  
  /// Detect learning style from user interactions
  LearningStyle detectLearningStyle() {
    if (_userProgress == null) {
      return LearningStyle.visual; // Default
    }
    
    return _analysisService.detectLearningStyle(_userProgress!);
  }
  
  /// Get user skill level for a specific skill type
  SkillLevel getUserSkillLevel(SkillType skillType) {
    if (_userProgress == null) {
      return SkillLevel.novice; // Default
    }
    
    return _userProgress!.skills[skillType] ?? SkillLevel.novice;
  }
}
