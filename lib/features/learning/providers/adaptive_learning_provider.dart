import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/learning/models/concept_mastery.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/learning_session.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';

/// Provider for adaptive learning features
///
/// This provider serves as an interface between the UI and the AdaptiveLearningService,
/// making it easier to access adaptive learning features from UI components.
class AdaptiveLearningProvider extends ChangeNotifier {
  /// The adaptive learning service
  final AdaptiveLearningService _adaptiveLearningService;

  /// The current user ID
  String? _userId;

  /// The current learning session
  LearningSession? _currentSession;

  /// The current learning path
  LearningPath? _currentPath;

  /// The current user progress
  UserProgress? _userProgress;

  /// The current learning path type
  LearningPathType _learningPathType = LearningPathType.logicBased;

  /// The current difficulty level
  int _difficultyLevel = 1;

  /// Whether the user is currently struggling
  bool _isUserStruggling = false;

  /// Whether the user is currently excelling
  bool _isUserExcelling = false;

  /// The current frustration level
  double _frustrationLevel = 0.0;

  /// Create an adaptive learning provider
  AdaptiveLearningProvider({
    AdaptiveLearningService? adaptiveLearningService,
  }) : _adaptiveLearningService = adaptiveLearningService ?? AdaptiveLearningService();

  /// Get the current user ID
  String? get userId => _userId;

  /// Get the current learning session
  LearningSession? get currentSession => _currentSession;

  /// Get the current learning path
  LearningPath? get currentPath => _currentPath;

  /// Get the current user progress
  UserProgress? get userProgress => _userProgress;

  /// Get the current learning path type
  LearningPathType get learningPathType => _learningPathType;

  /// Get the current difficulty level
  int get difficultyLevel => _difficultyLevel;

  /// Check if the user is currently struggling
  bool get isUserStruggling => _isUserStruggling;

  /// Check if the user is currently excelling
  bool get isUserExcelling => _isUserExcelling;

  /// Get the current frustration level
  double get frustrationLevel => _frustrationLevel;

  /// Initialize the provider for a specific user
  Future<void> initialize(String userId) async {
    _userId = userId;

    // Load user progress
    _userProgress = await _adaptiveLearningService.getUserProgress(userId);

    // If no user progress, create default
    if (_userProgress == null) {
      _userProgress = UserProgress(
        userId: userId,
        name: 'Learner',
      );
      await _adaptiveLearningService.saveUserProgress(_userProgress!);
    }

    // Recommend learning path type
    _learningPathType = await _adaptiveLearningService.recommendLearningPathType(
      userId: userId,
    );

    notifyListeners();
  }

  /// Start a new learning session
  Future<void> startSession({
    LearningPathType? preferredPathType,
    int initialDifficulty = 1,
  }) async {
    if (_userId == null) {
      throw Exception('Provider not initialized');
    }

    // End current session if exists
    if (_currentSession != null && _currentSession!.isActive) {
      await endSession();
    }

    // Recommend learning path type if not specified
    final pathType = preferredPathType ?? await _adaptiveLearningService.recommendLearningPathType(
      userId: _userId!,
      userPreference: preferredPathType,
    );

    // Create new session
    _currentSession = LearningSession.start(
      userId: _userId!,
      learningPathType: pathType,
      initialDifficulty: initialDifficulty,
    );

    _learningPathType = pathType;
    _difficultyLevel = initialDifficulty;
    _isUserStruggling = false;
    _isUserExcelling = false;
    _frustrationLevel = 0.0;

    // Generate learning path
    _currentPath = await _adaptiveLearningService.generateLearningPath(
      userId: _userId!,
      pathType: pathType,
    );

    notifyListeners();
  }

  /// End the current learning session
  Future<void> endSession() async {
    if (_currentSession == null || !_currentSession!.isActive) {
      return;
    }

    // End the session
    _currentSession = _currentSession!.end();

    // Update user progress
    if (_userProgress != null) {
      // Update total time spent
      final updatedProgress = _userProgress!.copyWith(
        totalTimeSpentMinutes: _userProgress!.totalTimeSpentMinutes + _currentSession!.timeSpentMinutes,
      );

      await _adaptiveLearningService.saveUserProgress(updatedProgress);
      _userProgress = updatedProgress;
    }

    notifyListeners();
  }

  /// Record a challenge attempt
  Future<void> recordChallengeAttempt({
    required String challengeId,
    required bool successful,
    required String conceptId,
    int? timeSpentSeconds,
    int? errorsCount,
    int? hintsUsed,
    double? solutionQuality,
  }) async {
    if (_userId == null || _currentSession == null) {
      throw Exception('Session not started');
    }

    // Update session with challenge attempt
    _currentSession = _currentSession!.recordChallengeAttempt(
      successful: successful,
      difficultyLevel: _difficultyLevel,
      timeSpentSeconds: timeSpentSeconds,
      errorsCount: errorsCount,
      hintsUsed: hintsUsed,
    );

    // Update user state
    _isUserStruggling = _currentSession!.isUserStruggling;
    _isUserExcelling = _currentSession!.isUserExcelling;
    _frustrationLevel = _currentSession!.frustrationLevel;

    // Assess concept mastery
    await _adaptiveLearningService.assessConceptMastery(
      userId: _userId!,
      conceptId: conceptId,
      challengeId: challengeId,
      successful: successful,
      timeSpentSeconds: timeSpentSeconds ?? 0,
      errorsCount: errorsCount ?? 0,
      hintsUsed: hintsUsed ?? 0,
      solutionQuality: solutionQuality,
    );

    // Adjust difficulty level
    _difficultyLevel = await _adaptiveLearningService.adjustChallengeDifficulty(
      userId: _userId!,
      session: _currentSession!,
      currentDifficulty: _difficultyLevel,
      timeSpentSeconds: timeSpentSeconds ?? 0,
      errorsCount: errorsCount ?? 0,
      hintsUsed: hintsUsed ?? 0,
      conceptId: conceptId,
    );

    // Reload user progress
    _userProgress = await _adaptiveLearningService.getUserProgress(_userId!);

    notifyListeners();
  }

  /// Record a hint request
  Future<void> recordHintRequest() async {
    if (_currentSession == null) {
      throw Exception('Session not started');
    }

    // Update session with hint request
    _currentSession = _currentSession!.recordHintRequest();

    // Update frustration level
    _frustrationLevel = await _adaptiveLearningService.detectFrustration(
      session: _currentSession!,
      hintsRequested: 1,
    );

    notifyListeners();
  }

  /// Record an error
  Future<void> recordError() async {
    if (_currentSession == null) {
      throw Exception('Session not started');
    }

    // Update session with error
    _currentSession = _currentSession!.recordError();

    // Update frustration level
    _frustrationLevel = await _adaptiveLearningService.detectFrustration(
      session: _currentSession!,
      recentErrors: 1,
    );

    notifyListeners();
  }

  /// Get the next recommended challenge
  Future<Map<String, dynamic>> getNextChallenge({
    required String challengeType,
    String? targetConcept,
  }) async {
    if (_userId == null) {
      throw Exception('Provider not initialized');
    }

    // Get user progress
    final userProgress = _userProgress ?? await _adaptiveLearningService.getUserProgress(_userId!);
    if (userProgress == null) {
      throw Exception('User progress not found');
    }

    // Get challenge
    return await _adaptiveLearningService.getChallenge(
      userProgress: userProgress,
      challengeType: challengeType,
      difficultyOverride: _difficultyLevel,
      learningPathType: _learningPathType,
      frustrationLevel: _frustrationLevel,
      targetConcept: targetConcept,
    );
  }

  /// Change the learning path type
  Future<void> changeLearningPathType(LearningPathType newPathType) async {
    if (_userId == null) {
      throw Exception('Provider not initialized');
    }

    _learningPathType = newPathType;

    // Generate new learning path
    _currentPath = await _adaptiveLearningService.generateLearningPath(
      userId: _userId!,
      pathType: newPathType,
    );

    // Update session if active
    if (_currentSession != null && _currentSession!.isActive) {
      // Create a new session with the new path type
      final newSession = LearningSession.start(
        userId: _userId!,
        learningPathType: newPathType,
        initialDifficulty: _difficultyLevel,
      );

      // Copy over relevant metrics from the old session
      _currentSession = newSession.copyWith(
        challengesAttempted: _currentSession!.challengesAttempted,
        challengesCompleted: _currentSession!.challengesCompleted,
        hintsRequested: _currentSession!.hintsRequested,
        errorsMade: _currentSession!.errorsMade,
        engagementScore: _currentSession!.engagementScore,
        frustrationLevel: _currentSession!.frustrationLevel,
        masteryLevel: _currentSession!.masteryLevel,
      );
    }

    notifyListeners();
  }

  /// Get hint priority based on user's learning style
  int getHintPriority(String hintType) {
    return _adaptiveLearningService.getHintPriority(hintType);
  }

  /// Get concept mastery for a specific concept
  Future<ConceptMastery?> getConceptMastery(String conceptId) async {
    if (_userId == null) {
      throw Exception('Provider not initialized');
    }

    return await _adaptiveLearningService.assessConceptMastery(
      userId: _userId!,
      conceptId: conceptId,
      challengeId: 'mastery_check',
      successful: true,
    );
  }

  /// Recommend next concepts to learn
  Future<List<String>> recommendNextConcepts({int count = 3}) async {
    if (_userId == null || _userProgress == null) {
      throw Exception('Provider not initialized');
    }

    return await _adaptiveLearningService.recommendNextConcepts(
      userProgress: _userProgress!,
      count: count,
    );
  }
}
