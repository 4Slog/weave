import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'challenge_service_refactored.dart';
import '../models/challenge_model.dart';
import '../models/validation_result.dart';

/// Wrapper for the refactored challenge service to maintain backward compatibility.
/// 
/// This wrapper provides the same API as the original ChallengeService,
/// but uses the refactored implementation internally.
class ChallengeService {
  /// The refactored challenge service
  final ChallengeServiceRefactored _refactoredService;
  
  /// Flag indicating if the service is initialized
  bool _isInitialized = false;
  
  /// Cache for challenges to reduce API calls
  final Map<String, Map<String, dynamic>> _challengeCache = {};
  
  /// Create a new ChallengeService with optional dependencies
  ChallengeService({
    ChallengeServiceRefactored? refactoredService,
  }) :
    _refactoredService = refactoredService ?? ChallengeServiceRefactored();
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize the refactored service
      await _refactoredService.initialize();
      
      _isInitialized = true;
      debugPrint('ChallengeService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ChallengeService: $e');
      throw Exception('Failed to initialize ChallengeService: $e');
    }
  }
  
  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Get a challenge based on user progress
  /// 
  /// [userProgress] is the user's current progress
  /// [challengeType] is the type of challenge to generate (e.g., 'pattern', 'sequence')
  /// [difficultyOverride] is an optional override for difficulty level
  /// [learningPathType] is an optional learning path type to consider
  /// [frustrationLevel] is an optional frustration level to consider for dynamic difficulty adjustment
  /// [targetConcept] is an optional specific concept to focus on
  /// 
  /// Returns a challenge as a map with challenge details
  Future<Map<String, dynamic>> getChallenge({
    required UserProgress userProgress,
    required String challengeType,
    int? difficultyOverride,
    LearningPathType? learningPathType,
    double? frustrationLevel,
    String? targetConcept,
  }) async {
    await _ensureInitialized();
    
    // Create a cache key for the challenge
    final cacheKey = 'challenge_${userProgress.userId}_${challengeType}_${difficultyOverride ?? 'auto'}_${learningPathType?.toString() ?? 'any'}_${targetConcept ?? 'any'}';
    
    // Check if challenge is cached and frustration level is not provided (don't use cache for dynamic difficulty adjustment)
    if (_challengeCache.containsKey(cacheKey) && frustrationLevel == null) {
      return _challengeCache[cacheKey]!;
    }
    
    // Get a challenge from the refactored service
    final challenge = await _refactoredService.getChallenge(
      userProgress: userProgress,
      challengeType: challengeType,
      difficultyOverride: difficultyOverride,
      learningPathType: learningPathType,
      frustrationLevel: frustrationLevel,
      targetConcept: targetConcept,
    );
    
    // Convert the challenge model to a map
    final challengeMap = challenge.toJson();
    
    // Cache the challenge
    _challengeCache[cacheKey] = challengeMap;
    
    return challengeMap;
  }
  
  /// Validate a user's solution to a challenge
  /// 
  /// [challenge] is the challenge to validate against
  /// [solution] is the user's solution to the challenge
  /// 
  /// Returns a validation result with success flag and feedback
  Future<Map<String, dynamic>> validateSolution({
    required Map<String, dynamic> challenge,
    required PatternModel solution,
  }) async {
    await _ensureInitialized();
    
    // Convert the challenge map to a ChallengeModel
    final challengeModel = ChallengeModel.fromJson(challenge);
    
    // Validate the solution using the refactored service
    final validationResult = await _refactoredService.validateSolution(
      challenge: challengeModel,
      solution: solution,
    );
    
    // Convert the validation result to a map for backward compatibility
    return {
      'success': validationResult.success,
      'feedback': validationResult.feedback.toJson(),
      'missingBlockTypes': validationResult.missingBlockTypes,
      'connectionCount': validationResult.connectionCount,
      'requiredConnectionCount': validationResult.requiredConnectionCount,
    };
  }
  
  /// Update user progress based on challenge completion
  /// 
  /// [userProgress] is the user's current progress
  /// [challenge] is the completed challenge
  /// [solution] is the user's solution to the challenge
  /// [validationResult] is the result of solution validation
  /// 
  /// Returns updated user progress
  Future<UserProgress> updateProgressForChallenge({
    required UserProgress userProgress,
    required Map<String, dynamic> challenge,
    required PatternModel solution,
    required Map<String, dynamic> validationResult,
  }) async {
    await _ensureInitialized();
    
    // Convert the challenge map to a ChallengeModel
    final challengeModel = ChallengeModel.fromJson(challenge);
    
    // Create a ValidationResult from the map
    final validationResultModel = ValidationResult(
      success: validationResult['success'] as bool,
      challenge: challengeModel,
      solution: solution,
      feedback: ValidationFeedback.fromJson(validationResult['feedback'] as Map<String, dynamic>),
      assessment: SolutionAssessment(
        achievementLevel: 'basic',
        pointsEarned: 1,
      ),
    );
    
    // Update progress using the refactored service
    return _refactoredService.updateProgressForChallenge(
      userProgress: userProgress,
      challenge: challengeModel,
      validationResult: validationResultModel,
    );
  }
  
  /// Check if a user has reached a milestone
  /// 
  /// [userProgress] is the user's current progress
  /// 
  /// Returns a milestone if reached, null otherwise
  Future<Map<String, dynamic>?> checkMilestone(UserProgress userProgress) async {
    await _ensureInitialized();
    
    return _refactoredService.checkMilestone(userProgress);
  }
  
  /// Load challenges from assets
  /// 
  /// This is a legacy method that returns a list of mock challenges
  /// for backward compatibility.
  Future<List<Map<String, dynamic>>> _loadChallenges() async {
    try {
      // Get challenges from the refactored service
      final challenges = await _refactoredService.getUncompletedChallenges('default');
      
      // Convert challenges to maps
      return challenges.map((challenge) => challenge.toJson()).toList();
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      
      // Return mock challenges for backward compatibility
      return [
        {
          'id': 'pattern_challenge_1',
          'type': 'pattern',
          'title': 'Create a Simple Pattern',
          'description': 'Create a pattern using move and turn blocks with at least 2 connections.',
          'difficulty': 1,
          'requiredConcepts': ['sequences', 'basic patterns'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn'],
            'minConnections': 2,
          },
          'availableBlockTypes': ['move', 'turn', 'loop'],
          'hints': [
            'Start by placing a move block.',
            'Connect blocks to create a pattern with at least 2 connections.',
            'Make sure to use both move and turn blocks.',
          ],
        },
        {
          'id': 'pattern_challenge_2',
          'type': 'pattern',
          'title': 'Create a Loop Pattern',
          'description': 'Create a pattern using move, turn, and loop blocks with at least 4 connections.',
          'difficulty': 2,
          'requiredConcepts': ['sequences', 'loops'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn', 'loop'],
            'minConnections': 4,
          },
          'availableBlockTypes': ['move', 'turn', 'loop', 'condition'],
          'hints': [
            'Start by placing a loop block.',
            'Place move and turn blocks inside the loop.',
            'Connect blocks to create a pattern with at least 4 connections.',
          ],
        },
        {
          'id': 'pattern_challenge_3',
          'type': 'pattern',
          'title': 'Create a Conditional Pattern',
          'description': 'Create a pattern using move, turn, loop, and condition blocks with at least 6 connections.',
          'difficulty': 3,
          'requiredConcepts': ['sequences', 'loops', 'conditionals'],
          'successCriteria': {
            'requiresBlockType': ['move', 'turn', 'loop', 'condition'],
            'minConnections': 6,
          },
          'availableBlockTypes': ['move', 'turn', 'loop', 'condition', 'variable'],
          'hints': [
            'Start by placing a condition block.',
            'Place move, turn, and loop blocks inside the condition branches.',
            'Connect blocks to create a pattern with at least 6 connections.',
          ],
        },
      ];
    }
  }
}
