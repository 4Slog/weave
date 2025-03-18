import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/badge_model.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/cultural_data_service.dart';
import 'dart:math';
import 'dart:convert';

/// Learning style preferences that can be detected and adapted to
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

/// Skill proficiency levels for tracking progress
enum ProficiencyLevel {
  /// No exposure to the concept yet
  notIntroduced,
  
  /// Concept has been introduced but not practiced
  introduced,
  
  /// Beginning to practice the concept with guidance
  practicing,
  
  /// Can apply the concept with occasional help
  developing,
  
  /// Can reliably apply the concept independently
  proficient,
  
  /// Can teach or extend the concept to new contexts
  mastered,
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
  
  // Current user progress
  UserProgress? _userProgress;
  
  // Tracks consecutive successes/failures for skill assessment
  int _consecutiveSuccesses = 0;
  int _consecutiveFailures = 0;
  
  // Learning style detection
  Map<LearningStyle, int> _learningStylePoints = {
    LearningStyle.visual: 0,
    LearningStyle.logical: 0,
    LearningStyle.practical: 0,
    LearningStyle.verbal: 0,
    LearningStyle.social: 0,
    LearningStyle.reflective: 0,
  };
  
  // Skill tracking - maps concepts to proficiency levels
  Map<String, ProficiencyLevel> _skillProficiencies = {};
  
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
  
  // Thresholds for learning style detection
  static const int _learningStyleThreshold = 10;
  
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
    
    // Initialize skill proficiencies from user progress
    _initializeSkillProficiencies();
    
    // Load learning style data
    await _loadLearningStyleData();
    
    // Load challenge history
    await _loadChallengeHistory();
  }
  
  /// Initialize skill proficiencies from user progress
  void _initializeSkillProficiencies() {
    if (_userProgress == null) return;
    
    // Convert skill levels from UserProgress to our proficiency format
    _userProgress!.skills.forEach((skillType, level) {
      final skillName = skillType.toString().split('.').last.toLowerCase();
      
      ProficiencyLevel proficiencyLevel;
      switch (level) {
        case SkillLevel.novice:
          proficiencyLevel = ProficiencyLevel.introduced;
          break;
        case SkillLevel.beginner:
          proficiencyLevel = ProficiencyLevel.practicing;
          break;
        case SkillLevel.intermediate:
          proficiencyLevel = ProficiencyLevel.developing;
          break;
        case SkillLevel.advanced:
          proficiencyLevel = ProficiencyLevel.proficient;
          break;
        default:
          proficiencyLevel = ProficiencyLevel.notIntroduced;
      }
      
      _skillProficiencies[skillName] = proficiencyLevel;
    });
    
    // Check for completed challenges to ensure consistent skill tracking
    for (var challengeId in _userProgress!.completedChallenges) {
      // Update relevant skills based on challenge tags
      // We'll get this data from challenge history in a full implementation
    }
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
  
  /// Load learning style data from storage
  Future<void> _loadLearningStyleData() async {
    try {
      final learningStyleData = await _storageService.getSetting('learning_style_points');
      if (learningStyleData != null) {
        final Map<String, dynamic> data = jsonDecode(learningStyleData);
        
        data.forEach((key, value) {
          try {
            final style = LearningStyle.values.firstWhere(
              (e) => e.toString().split('.').last == key,
              orElse: () => throw Exception('Invalid learning style'),
            );
            _learningStylePoints[style] = value;
          } catch (e) {
            debugPrint('Error parsing learning style: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading learning style data: $e');
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
      
      // Also save learning style and challenge data
      await _saveLearningStyleData();
      await _saveChallengeHistory();
    } catch (e) {
      debugPrint('Failed to save user progress: $e');
    }
  }
  
  /// Save learning style data to storage
  Future<void> _saveLearningStyleData() async {
    try {
      final Map<String, int> data = {};
      _learningStylePoints.forEach((key, value) {
        data[key.toString().split('.').last] = value;
      });
      
      await _storageService.saveSetting(
        'learning_style_points', 
        jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error saving learning style data: $e');
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
      'userId': _userProgress!.userId,
    };
    
    // Add to recent actions, maintaining the maximum size
    _recentActions.add(action);
    if (_recentActions.length > _maxRecentActions) {
      _recentActions.removeAt(0);
    }
    
    // Update skills based on action
    _updateSkillsBasedOnAction(actionType, wasSuccessful, metadata);
    
    // Update learning style points based on action
    _updateLearningStylePoints(actionType, metadata);
    
    // Consider awarding experience
    if (wasSuccessful) {
      int xpAmount = _calculateExperienceForAction(actionType, metadata);
      if (_userProgress != null) {
        _userProgress = _userProgress!.addExperience(xpAmount);
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
          final difficulty = metadata?['difficulty'] ?? 1;
          
          if (challengeType != null) {
            // Map challenge type to skill
            SkillType? skillType = _getSkillTypeFromConcept(challengeType);
            
            if (skillType != null) {
              // Major skill update for challenge completion
              _updateSkillProficiency(challengeType, wasSuccessful, difficulty);
              
              // Update UserProgress skills
              _updateUserProgressSkill(skillType, true);
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
        _updateSkillProficiency('storytelling', true, 1);
        _updateUserProgressSkill(SkillType.storytelling, true);
        break;
        
      case 'pattern_creation':
        // Update pattern skill
        _updateSkillProficiency('patterns', true, 1);
        _updateUserProgressSkill(SkillType.patterns, true);
        break;
        
      case 'cultural_exploration':
        // Update cultural context skill
        _updateSkillProficiency('cultural', true, 1);
        _updateUserProgressSkill(SkillType.culturalContext, true);
        break;
        
      case 'debug_success':
        // Update debugging skill
        _updateSkillProficiency('debugging', true, 1);
        _updateUserProgressSkill(SkillType.debugging, true);
        break;
        
      case 'debug_failure':
        // Slight negative adjustment to debugging skill
        _updateSkillProficiency('debugging', false, 1);
        _updateUserProgressSkill(SkillType.debugging, false);
        break;
        
      case 'block_connection':
        // Minor update to structure skill
        _updateSkillProficiency('structure', true, 0.5);
        _updateUserProgressSkill(SkillType.structure, true);
        break;
    }
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
  
  /// Update user progress skill level
  void _updateUserProgressSkill(SkillType skillType, bool success) {
    if (_userProgress == null) return;
    
    // Get current skill level
    SkillLevel currentLevel = _userProgress!.skills[skillType] ?? SkillLevel.novice;
    
    // Apply skill update based on success/failure
    if (success) {
      if (_consecutiveSuccesses >= 3) {
        // Consider promoting skill level on consistent success
        _userProgress = _userProgress!.improveSkill(skillType);
      }
    } else if (_consecutiveFailures >= 5) {
      // Consider demoting skill level on consistent failure (harder to demote)
      // In a full implementation, we would have a method to reduce skill level
    }
  }
  
  /// Update skill proficiency for a specific concept
  void _updateSkillProficiency(String concept, bool success, double difficultyFactor) {
    // Get current proficiency
    ProficiencyLevel currentProficiency = _skillProficiencies[concept] ?? ProficiencyLevel.notIntroduced;
    
    // Calculate adjustment factor
    double adjustmentFactor = success ? 0.05 * difficultyFactor : -0.025 * difficultyFactor;
    
    // Apply progressive adjustment based on current level
    switch (currentProficiency) {
      case ProficiencyLevel.notIntroduced:
        if (success) {
          _skillProficiencies[concept] = ProficiencyLevel.introduced;
        }
        break;
        
      case ProficiencyLevel.introduced:
        if (success && _consecutiveSuccesses >= 2) {
          _skillProficiencies[concept] = ProficiencyLevel.practicing;
        }
        break;
        
      case ProficiencyLevel.practicing:
        if (success && _consecutiveSuccesses >= 3) {
          _skillProficiencies[concept] = ProficiencyLevel.developing;
        } else if (!success && _consecutiveFailures >= 5) {
          _skillProficiencies[concept] = ProficiencyLevel.introduced;
        }
        break;
        
      case ProficiencyLevel.developing:
        if (success && _consecutiveSuccesses >= 5) {
          _skillProficiencies[concept] = ProficiencyLevel.proficient;
        } else if (!success && _consecutiveFailures >= 3) {
          _skillProficiencies[concept] = ProficiencyLevel.practicing;
        }
        break;
        
      case ProficiencyLevel.proficient:
        if (success && _consecutiveSuccesses >= 7) {
          _skillProficiencies[concept] = ProficiencyLevel.mastered;
        } else if (!success && _consecutiveFailures >= 3) {
          _skillProficiencies[concept] = ProficiencyLevel.developing;
        }
        break;
        
      case ProficiencyLevel.mastered:
        if (!success && _consecutiveFailures >= 5) {
          _skillProficiencies[concept] = ProficiencyLevel.proficient;
        }
        break;
    }
  }
  
  /// Update learning style points based on action
  void _updateLearningStylePoints(String actionType, Map<String, dynamic>? metadata) {
    switch (actionType) {
      case 'pattern_creation':
        // Visual and practical learners enjoy pattern creation
        _increaseStylePoints(LearningStyle.visual, 2);
        _increaseStylePoints(LearningStyle.practical, 1);
        break;
        
      case 'cultural_exploration':
        // Reflective and verbal learners enjoy cultural context
        _increaseStylePoints(LearningStyle.reflective, 2);
        _increaseStylePoints(LearningStyle.verbal, 1);
        break;
        
      case 'debug_success':
      case 'debug_failure':
        // Logical and reflective learners engage with debugging
        _increaseStylePoints(LearningStyle.logical, 2);
        _increaseStylePoints(LearningStyle.reflective, 1);
        break;
        
      case 'story_progress':
        // Verbal and reflective learners enjoy storytelling
        _increaseStylePoints(LearningStyle.verbal, 2);
        _increaseStylePoints(LearningStyle.reflective, 1);
        break;
        
      case 'block_connection':
        // Visual and logical learners engage with block connections
        _increaseStylePoints(LearningStyle.visual, 1);
        _increaseStylePoints(LearningStyle.logical, 1);
        break;
        
      case 'challenge_completion':
        // Check for interaction patterns that indicate learning style
        if (metadata != null) {
          final completionTime = metadata['completionTimeSeconds'] ?? 0;
          final attempts = metadata['attempts'] ?? 1;
          final blockCount = metadata['blockCount'] ?? 0;
          
          if (completionTime < 60 && attempts <= 1) {
            // Quick, successful completion indicates practical learner
            _increaseStylePoints(LearningStyle.practical, 2);
          } else if (completionTime > 180 && attempts > 2) {
            // Long completion time with multiple attempts suggests reflective
            _increaseStylePoints(LearningStyle.reflective, 2);
          }
          
          if (blockCount > 10) {
            // Complex solutions suggest logical learner
            _increaseStylePoints(LearningStyle.logical, 1);
          } else if (blockCount <= 5) {
            // Simple, elegant solutions suggest practical learner
            _increaseStylePoints(LearningStyle.practical, 1);
          }
        }
        break;
    }
    
    // If user shared their creation, that's a social learning indicator
    if (metadata != null && metadata.containsKey('shared') && metadata['shared'] == true) {
      _increaseStylePoints(LearningStyle.social, 2);
    }
    
    // If user viewed a hint, that could indicate learning style
    if (metadata != null && metadata.containsKey('viewedHint') && metadata['viewedHint'] == true) {
      if (metadata.containsKey('hintType')) {
        final hintType = metadata['hintType'];
        
        if (hintType == 'visual') {
          _increaseStylePoints(LearningStyle.visual, 1);
        } else if (hintType == 'verbal') {
          _increaseStylePoints(LearningStyle.verbal, 1);
        } else if (hintType == 'logical') {
          _increaseStylePoints(LearningStyle.logical, 1);
        }
      }
    }
  }
  
  /// Increase points for a specific learning style
  void _increaseStylePoints(LearningStyle style, int points) {
    _learningStylePoints[style] = (_learningStylePoints[style] ?? 0) + points;
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
      return UserProgress(userId: userId);
    }
    
    // Update skill proficiency
    _updateSkillProficiency(conceptId, success, difficulty);
    
    // Map to skill type
    SkillType? skillType = _getSkillTypeFromConcept(conceptId);
    if (skillType != null) {
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
    
    // Add challenge to completed list if not already there
    if (!_userProgress!.completedChallenges.contains(challengeId)) {
      _userProgress = _userProgress!.addCompletedChallenge(challengeId);
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
      _updateSkillProficiency(skill, true, difficulty);
      
      // Map to skill type and update user progress
      SkillType? skillType = _getSkillTypeFromConcept(skill);
      if (skillType != null) {
        _updateUserProgressSkill(skillType, true);
      }
    }
    
    // Save the updated progress
    await _saveUserProgress();
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
    
    int priority = 5; // Default priority
    
    switch (hintType) {
      case 'loop':
        // Higher priority if struggling with loops
        if (_skillProficiencies['loops'] == ProficiencyLevel.introduced || 
            _skillProficiencies['loops'] == ProficiencyLevel.practicing) {
          priority += 3;
        }
        break;
        
      case 'conditional':
        // Higher priority if struggling with conditionals
        if (_skillProficiencies['conditionals'] == ProficiencyLevel.introduced || 
            _skillProficiencies['conditionals'] == ProficiencyLevel.practicing) {
          priority += 3;
        }
        break;
        
      case 'pattern':
        // Higher priority if good with patterns
        if (_skillProficiencies['patterns'] == ProficiencyLevel.developing || 
            _skillProficiencies['patterns'] == ProficiencyLevel.proficient) {
          priority += 2;
        }
        break;
        
      case 'cultural':
        // Higher priority for cultural hints if the user shows interest
        if (_skillProficiencies['cultural'] == ProficiencyLevel.developing || 
            _skillProficiencies['cultural'] == ProficiencyLevel.proficient) {
          priority += 2;
        }
        
        // Boost if user has shown interest in cultural aspects
        if (_userProgress!.preferences.containsKey('interestedInCulture') && 
            _userProgress!.preferences['interestedInCulture'] == true) {
          priority += 2;
        }
        
        // Also consider learning style - verbal and reflective learners prefer cultural context
        if (getPrimaryLearningStyle() == LearningStyle.verbal || 
            getPrimaryLearningStyle() == LearningStyle.reflective) {
          priority += 1;
        }
        break;
        
      case 'debug':
        // Higher priority if user is actively debugging
        if (_consecutiveFailures >= 3) {
          priority += 4;
        }
        break;
    }
    
    // Adjust priority based on learning style preferences
    priority = _adjustPriorityForLearningStyle(hintType, priority);
    
    // Ensure priority is within bounds
    return min(10, max(0, priority));
  }
  
  /// Adjust hint priority based on learning style
  int _adjustPriorityForLearningStyle(String hintType, int basePriority) {
    final learningStyle = getPrimaryLearningStyle();
    
    // Visual learners prefer image-based hints
    if (learningStyle == LearningStyle.visual && hintType.contains('image')) {
      return basePriority + 2;
    }
    
    // Verbal learners prefer text-based hints
    if (learningStyle == LearningStyle.verbal && hintType.contains('text')) {
      return basePriority + 2;
    }
    
    // Logical learners prefer structured hints
    if (learningStyle == LearningStyle.logical && hintType.contains('logic')) {
      return basePriority + 2;
    }
    
    // Practical learners prefer example-based hints
    if (learningStyle == LearningStyle.practical && hintType.contains('example')) {
      return basePriority + 2;
    }
    
    return basePriority;
  }
  
  /// Get the user's primary learning style based on accumulated points
  LearningStyle getPrimaryLearningStyle() {
    LearningStyle primaryStyle = LearningStyle.visual; // Default
    int maxPoints = 0;
    
    _learningStylePoints.forEach((style, points) {
      if (points > maxPoints) {
        maxPoints = points;
        primaryStyle = style;
      }
    });
    
    return primaryStyle;
  }
  
  /// Get all learning styles that meet the threshold for consideration
  List<LearningStyle> getSignificantLearningStyles() {
    List<LearningStyle> significantStyles = [];
    
    _learningStylePoints.forEach((style, points) {
      if (points >= _learningStyleThreshold) {
        significantStyles.add(style);
      }
    });
    
    // If no styles meet threshold, return primary
    if (significantStyles.isEmpty) {
      significantStyles.add(getPrimaryLearningStyle());
    }
    
    return significantStyles;
    }
  
  /// Get learning style confidence scores (0-1 range)
  Map<LearningStyle, double> getLearningStyleConfidences() {
    Map<LearningStyle, double> confidences = {};
    
    // Get total points
    int totalPoints = 0;
    _learningStylePoints.values.forEach((points) {
      totalPoints += points;
    });
    
    // Calculate confidence for each style (minimum 0.1 baseline)
    if (totalPoints > 0) {
      _learningStylePoints.forEach((style, points) {
        confidences[style] = 0.1 + (0.9 * points / totalPoints);
      });
    } else {
      // If no data yet, assign equal confidence
      _learningStylePoints.keys.forEach((style) {
        confidences[style] = 0.1;
      });
    }
    
    return confidences;
  }
  
  /// Get preferred content format based on learning style
  String getPreferredContentFormat() {
    final learningStyle = getPrimaryLearningStyle();
    
    switch (learningStyle) {
      case LearningStyle.visual:
        return 'visual';
      case LearningStyle.verbal:
        return 'text';
      case LearningStyle.logical:
        return 'structured';
      case LearningStyle.practical:
        return 'example';
      case LearningStyle.reflective:
        return 'detailed';
      case LearningStyle.social:
        return 'interactive';
      default:
        return 'balanced';
    }
  }
  
  /// Get recommended challenge difficulty based on skill proficiency
  int getRecommendedDifficulty(String conceptId) {
    // Get the current proficiency level
    final proficiency = _skillProficiencies[conceptId] ?? ProficiencyLevel.notIntroduced;
    
    // Map proficiency to difficulty
    switch (proficiency) {
      case ProficiencyLevel.notIntroduced:
      case ProficiencyLevel.introduced:
        return 1; // Easiest
      case ProficiencyLevel.practicing:
        return 2; // Easy
      case ProficiencyLevel.developing:
        return 3; // Medium
      case ProficiencyLevel.proficient:
        return 4; // Hard
      case ProficiencyLevel.mastered:
        return 5; // Very hard
    }
  }
  
  /// Get user's skill level in a specific concept
  ProficiencyLevel getSkillProficiency(String conceptId) {
    return _skillProficiencies[conceptId] ?? ProficiencyLevel.notIntroduced;
  }
  
  /// Get all skill proficiencies
  Map<String, ProficiencyLevel> getAllSkillProficiencies() {
    return Map.unmodifiable(_skillProficiencies);
  }
  
  /// Get mastered concepts
  List<String> getMasteredConcepts() {
    List<String> masteredConcepts = [];
    
    _skillProficiencies.forEach((concept, level) {
      if (level == ProficiencyLevel.mastered) {
        masteredConcepts.add(concept);
      }
    });
    
    return masteredConcepts;
  }
  
  /// Get concepts that need improvement
  List<String> getConceptsNeedingImprovement() {
    List<String> needsImprovement = [];
    
    _skillProficiencies.forEach((concept, level) {
      if (level == ProficiencyLevel.introduced || level == ProficiencyLevel.practicing) {
        needsImprovement.add(concept);
      }
    });
    
    return needsImprovement;
  }
  
  /// Get concepts that are ready for advancement
  List<String> getConceptsReadyForAdvancement() {
    List<String> readyForAdvancement = [];
    
    _skillProficiencies.forEach((concept, level) {
      if (level == ProficiencyLevel.developing || level == ProficiencyLevel.proficient) {
        readyForAdvancement.add(concept);
      }
    });
    
    return readyForAdvancement;
  }
  
  /// Get user's skill level converted to standard form
  int getUserSkillLevel(String userId) {
    if (_userProgress == null) return 1;
    
    // Calculate average skill level
    int totalLevel = 0;
    int skillCount = 0;
    
    _userProgress!.skills.forEach((skillType, level) {
      totalLevel += level.index;
      skillCount++;
    });
    
    if (skillCount == 0) return 1;
    
    return (totalLevel / skillCount).round() + 1; // +1 to avoid returning 0
  }
  
  /// Detect learning style preferences from interaction history
  Future<LearningStyle> detectLearningStyle() async {
    // If we already have enough data, return the primary style
    LearningStyle primaryStyle = getPrimaryLearningStyle();
    int maxPoints = _learningStylePoints[primaryStyle] ?? 0;
    
    if (maxPoints >= _learningStyleThreshold) {
      return primaryStyle;
    }
    
    // Otherwise, analyze recent actions to make a determination
    await _analyzeInteractionPatterns();
    
    // Return the updated primary style
    return getPrimaryLearningStyle();
  }
  
  /// Analyze user interaction patterns to detect learning style
  Future<void> _analyzeInteractionPatterns() async {
    if (_recentActions.isEmpty) return;
    
    // Analyze time spent on different activities
    final activityDurations = _calculateActivityDurations();
    
    // Users who spend more time on storytelling may be verbal learners
    if (activityDurations['story_reading'] != null && 
        activityDurations['story_reading']! > 120) { // More than 2 minutes
      _increaseStylePoints(LearningStyle.verbal, 1);
    }
    
    // Users who spend more time on pattern creation may be visual learners
    if (activityDurations['pattern_creation'] != null && 
        activityDurations['pattern_creation']! > 180) { // More than 3 minutes
      _increaseStylePoints(LearningStyle.visual, 1);
    }
    
    // Users who spend more time on cultural content may be reflective learners
    if (activityDurations['cultural_exploration'] != null && 
        activityDurations['cultural_exploration']! > 90) { // More than 1.5 minutes
      _increaseStylePoints(LearningStyle.reflective, 1);
    }
    
    // Calculate preferred hint types from hint usage
    final hintUsage = _analyzeHintUsage();
    String? mostUsedHintType;
    int maxUsage = 0;
    
    hintUsage.forEach((type, count) {
      if (count > maxUsage) {
        maxUsage = count;
        mostUsedHintType = type;
      }
    });
    
    // Adjust learning style based on hint preference
    if (mostUsedHintType != null && maxUsage > 3) {
      switch (mostUsedHintType) {
        case 'visual':
          _increaseStylePoints(LearningStyle.visual, 2);
          break;
        case 'text':
          _increaseStylePoints(LearningStyle.verbal, 2);
          break;
        case 'logic':
          _increaseStylePoints(LearningStyle.logical, 2);
          break;
        case 'example':
          _increaseStylePoints(LearningStyle.practical, 2);
          break;
      }
    }
    
    // Analyze challenge solution patterns
    _analyzeChallengeSolutions();
    
    // Save the updated learning style data
    await _saveLearningStyleData();
  }
  
  /// Calculate time spent on different activities
  Map<String, int> _calculateActivityDurations() {
    Map<String, int> durations = {};
    
    // Group actions by activity type
    Map<String, List<Map<String, dynamic>>> actionsByType = {};
    
    for (var action in _recentActions) {
      final type = action['actionType'];
      if (!actionsByType.containsKey(type)) {
        actionsByType[type] = [];
      }
      actionsByType[type]!.add(action);
    }
    
    // Calculate durations where possible
    actionsByType.forEach((type, actions) {
      if (actions.length < 2) return;
      
      // Sort by timestamp
      actions.sort((a, b) => 
        DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp']))
      );
      
      // Calculate total duration
      int totalDuration = 0;
      for (int i = 1; i < actions.length; i++) {
        final current = DateTime.parse(actions[i]['timestamp']);
        final previous = DateTime.parse(actions[i-1]['timestamp']);
        
        final difference = current.difference(previous).inSeconds;
        
        // Only count if reasonable (less than 10 minutes)
        if (difference > 0 && difference < 600) {
          totalDuration += difference;
        }
      }
      
      durations[type] = totalDuration;
    });
    
    return durations;
  }
  
  /// Analyze hint usage patterns
  Map<String, int> _analyzeHintUsage() {
    Map<String, int> hintCounts = {};
    
    for (var action in _recentActions) {
      if (action['actionType'] == 'hint_viewed' && 
          action['metadata'] != null &&
          action['metadata']['hintType'] != null) {
        
        final hintType = action['metadata']['hintType'];
        hintCounts[hintType] = (hintCounts[hintType] ?? 0) + 1;
      }
    }
    
    return hintCounts;
  }
  
  /// Analyze challenge solution patterns
  void _analyzeChallengeSolutions() {
    // Filter for challenge completions
    final completions = _challengeHistory.where((ch) => ch['success'] == true).toList();
    if (completions.isEmpty) return;
    
    // Look for patterns in solutions
    int quickSolutions = 0;
    int complexSolutions = 0;
    int simpleSolutions = 0;
    
    for (var completion in completions) {
      // Quick solutions (under 2 minutes)
      if (completion.containsKey('durationSeconds') && 
          completion['durationSeconds'] < 120) {
        quickSolutions++;
      }
      
      // Complex solutions (many blocks)
      if (completion.containsKey('blockCount') && 
          completion['blockCount'] > 10) {
        complexSolutions++;
      }
      
      // Simple, elegant solutions (few blocks)
      if (completion.containsKey('blockCount') && 
          completion['blockCount'] < 6) {
        simpleSolutions++;
      }
    }
    
    // Update learning style points based on solution patterns
    if (quickSolutions >= 3) {
      _increaseStylePoints(LearningStyle.practical, 2);
    }
    
    if (complexSolutions >= 3) {
      _increaseStylePoints(LearningStyle.logical, 2);
    }
    
    if (simpleSolutions >= 3) {
      _increaseStylePoints(LearningStyle.practical, 1);
      _increaseStylePoints(LearningStyle.visual, 1);
    }
  }
  
  /// Recommend content format based on learning style
  Map<String, dynamic> getContentRecommendations() {
    final style = getPrimaryLearningStyle();
    final recommendations = <String, dynamic>{};
    
    switch (style) {
      case LearningStyle.visual:
        recommendations['hintStyle'] = 'visual';
        recommendations['instructionStyle'] = 'diagram';
        recommendations['feedbackStyle'] = 'visual';
        recommendations['culturalContentFocus'] = 'patterns';
        recommendations['challengeStyle'] = 'pattern-focused';
        break;
        
      case LearningStyle.logical:
        recommendations['hintStyle'] = 'structured';
        recommendations['instructionStyle'] = 'step-by-step';
        recommendations['feedbackStyle'] = 'analytical';
        recommendations['culturalContentFocus'] = 'symbolism';
        recommendations['challengeStyle'] = 'logic-focused';
        break;
        
      case LearningStyle.practical:
        recommendations['hintStyle'] = 'example';
        recommendations['instructionStyle'] = 'hands-on';
        recommendations['feedbackStyle'] = 'direct';
        recommendations['culturalContentFocus'] = 'applications';
        recommendations['challengeStyle'] = 'practical-focused';
        break;
        
      case LearningStyle.verbal:
        recommendations['hintStyle'] = 'text';
        recommendations['instructionStyle'] = 'narrative';
        recommendations['feedbackStyle'] = 'descriptive';
        recommendations['culturalContentFocus'] = 'stories';
        recommendations['challengeStyle'] = 'story-focused';
        break;
        
      case LearningStyle.reflective:
        recommendations['hintStyle'] = 'question';
        recommendations['instructionStyle'] = 'conceptual';
        recommendations['feedbackStyle'] = 'detailed';
        recommendations['culturalContentFocus'] = 'meanings';
        recommendations['challengeStyle'] = 'open-ended';
        break;
        
      case LearningStyle.social:
        recommendations['hintStyle'] = 'collaborative';
        recommendations['instructionStyle'] = 'discussion';
        recommendations['feedbackStyle'] = 'encouraging';
        recommendations['culturalContentFocus'] = 'community';
        recommendations['challengeStyle'] = 'sharing-focused';
        break;
    }
    
    return recommendations;
  }
  
  /// Get next concepts to focus on based on current proficiency
  List<String> getRecommendedNextConcepts() {
    // Get concepts by proficiency level
    Map<ProficiencyLevel, List<String>> conceptsByProficiency = {};
    
    _skillProficiencies.forEach((concept, level) {
      if (!conceptsByProficiency.containsKey(level)) {
        conceptsByProficiency[level] = [];
      }
      conceptsByProficiency[level]!.add(concept);
    });
    
    // Prioritize:
    // 1. Concepts at 'developing' level (ready to advance)
    // 2. Concepts at 'introduced' level (need practice)
    // 3. Concepts not yet introduced
    
    List<String> recommendations = [];
    
    // Add developing concepts first (ready to level up)
    if (conceptsByProficiency.containsKey(ProficiencyLevel.developing)) {
      recommendations.addAll(conceptsByProficiency[ProficiencyLevel.developing]!);
    }
    
    // Add practicing concepts next (need more practice)
    if (conceptsByProficiency.containsKey(ProficiencyLevel.practicing)) {
      recommendations.addAll(conceptsByProficiency[ProficiencyLevel.practicing]!);
    }
    
    // Add introduced concepts next (just starting)
    if (conceptsByProficiency.containsKey(ProficiencyLevel.introduced)) {
      recommendations.addAll(conceptsByProficiency[ProficiencyLevel.introduced]!);
    }
    
    // Add not introduced concepts last (completely new)
    if (conceptsByProficiency.containsKey(ProficiencyLevel.notIntroduced)) {
      recommendations.addAll(conceptsByProficiency[ProficiencyLevel.notIntroduced]!);
    }
    
    // Limit to 5 recommendations
    if (recommendations.length > 5) {
      recommendations = recommendations.sublist(0, 5);
    }
    
    return recommendations;
  }
  
  /// Detect needed interventions based on skill gaps
  List<Map<String, dynamic>> detectNeededInterventions() {
    List<Map<String, dynamic>> interventions = [];
    
    // Check for persistent failures in specific concepts
    _skillProficiencies.forEach((concept, level) {
      if (level == ProficiencyLevel.introduced || level == ProficiencyLevel.practicing) {
        // Check challenge history for multiple failures
        int failedAttempts = 0;
        for (var challenge in _challengeHistory) {
          if (challenge['success'] == false && 
              challenge['concepts'] != null &&
              challenge['concepts'].contains(concept)) {
            failedAttempts++;
          }
        }
        
        if (failedAttempts >= 3) {
          interventions.add({
            'type': 'tutorial',
            'concept': concept,
            'reason': 'Multiple failed attempts indicate a need for additional instruction',
            'priority': 'high',
          });
        }
      }
    });
    
    // Check for skill plateaus (no improvement over time)
    final conceptProgress = _trackConceptProgressOverTime();
    conceptProgress.forEach((concept, timestamps) {
      if (timestamps.length >= 3) {
        // Check if last 3 attempts show no improvement
        bool noImprovement = true;
        for (int i = timestamps.length - 1; i >= max(0, timestamps.length - 3); i--) {
          if (timestamps[i]['levelChange'] == 'improved') {
            noImprovement = false;
            break;
          }
        }
        
        if (noImprovement) {
          interventions.add({
            'type': 'alternative_approach',
            'concept': concept,
            'reason': 'Skills plateau detected - may need different instruction approach',
            'priority': 'medium',
          });
        }
      }
    });
    
    // Check for learning style mismatches
    final learningStyle = getPrimaryLearningStyle();
    final hintUsage = _analyzeHintUsage();
    
    bool potentialMismatch = false;
    
    if (learningStyle == LearningStyle.visual && 
        (hintUsage['visual'] ?? 0) < (hintUsage['text'] ?? 0)) {
      potentialMismatch = true;
    } else if (learningStyle == LearningStyle.verbal && 
        (hintUsage['text'] ?? 0) < (hintUsage['visual'] ?? 0)) {
      potentialMismatch = true;
    }
    
    if (potentialMismatch) {
      interventions.add({
        'type': 'learning_style_assessment',
        'reason': 'Hint usage patterns suggest potential learning style mismatch',
        'priority': 'low',
      });
    }
    
    return interventions;
  }
  
  /// Track concept progress over time
  Map<String, List<Map<String, dynamic>>> _trackConceptProgressOverTime() {
    Map<String, List<Map<String, dynamic>>> progress = {};
    
    // Sort challenge history by timestamp
    _challengeHistory.sort((a, b) => 
      DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp']))
    );
    
    // Track proficiency changes over time
    Map<String, ProficiencyLevel> previousLevels = {};
    
    for (var challenge in _challengeHistory) {
      if (challenge['concepts'] == null) continue;
      
      for (var concept in challenge['concepts']) {
        if (!progress.containsKey(concept)) {
          progress[concept] = [];
        }
        
        // Get proficiency level at this timestamp
        final timestamp = challenge['timestamp'];
        final success = challenge['success'] ?? false;
        
        // Determine if level improved
        final currentLevel = _skillProficiencies[concept] ?? ProficiencyLevel.notIntroduced;
        final previousLevel = previousLevels[concept] ?? ProficiencyLevel.notIntroduced;
        
        String levelChange = 'same';
        if (currentLevel.index > previousLevel.index) {
          levelChange = 'improved';
        } else if (currentLevel.index < previousLevel.index) {
          levelChange = 'decreased';
        }
        
        // Record progress point
        progress[concept]!.add({
          'timestamp': timestamp,
          'success': success,
          'level': currentLevel.toString().split('.').last,
          'levelChange': levelChange,
        });
        
        // Update previous level for next time
        previousLevels[concept] = currentLevel;
      }
    }
    
    return progress;
  }
  
  /// Generate a learning progress report
  Map<String, dynamic> generateProgressReport() {
    if (_userProgress == null) {
      return {'error': 'No user progress available'};
    }
    
    // Calculate mastery percentages
    Map<String, double> conceptMastery = {};
    _skillProficiencies.forEach((concept, level) {
      // Convert proficiency level to percentage
      double percentage = 0;
      switch (level) {
        case ProficiencyLevel.notIntroduced:
          percentage = 0;
          break;
        case ProficiencyLevel.introduced:
          percentage = 0.2;
          break;
        case ProficiencyLevel.practicing:
          percentage = 0.4;
          break;
        case ProficiencyLevel.developing:
          percentage = 0.6;
          break;
        case ProficiencyLevel.proficient:
          percentage = 0.8;
          break;
        case ProficiencyLevel.mastered:
          percentage = 1.0;
          break;
      }
      
      conceptMastery[concept] = percentage;
    });
    
    // Calculate overall progress
    double overallProgress = 0;
    if (conceptMastery.isNotEmpty) {
      double total = 0;
      conceptMastery.values.forEach((value) {
        total += value;
      });
      overallProgress = total / conceptMastery.length;
    }
    
    // Generate strengths and areas for improvement
    List<String> strengths = [];
    List<String> areasForImprovement = [];
    
    conceptMastery.forEach((concept, mastery) {
      if (mastery >= 0.8) {
        strengths.add(concept);
      } else if (mastery <= 0.4) {
        areasForImprovement.add(concept);
      }
    });
    
    // Get learning style insights
    final learningStyle = getPrimaryLearningStyle();
    final learningStyleConfidences = getLearningStyleConfidences();
    
    return {
      'userId': _userProgress!.userId,
      'overallProgress': overallProgress,
      'conceptMastery': conceptMastery,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
      'challengesCompleted': _userProgress!.completedChallenges.length,
      'storiesExplored': _userProgress!.completedStories.length,
      'xpLevel': _userProgress!.level,
      'learningStyle': learningStyle.toString().split('.').last,
      'learningStyleConfidence': learningStyleConfidences[learningStyle],
      'recommendations': getRecommendedNextConcepts(),
      'contentPreferences': getContentRecommendations(),
    };
  }
  
  /// Get the user progress
  UserProgress? get userProgress => _userProgress;
  
  /// Get time spent on activities
  Map<String, int> get timeSpentOnActivities => Map.from(_timeSpentOnActivities);
  
  /// Get recent user actions
  List<Map<String, dynamic>> get recentActions => List.from(_recentActions);
}