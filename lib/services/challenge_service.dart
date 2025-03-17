import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Model for challenges
class ChallengeModel {
  /// Unique identifier for this challenge
  final String id;
  
  /// Challenge title
  final String title;
  
  /// Challenge description
  final String description;
  
  /// Difficulty level (1-5)
  final int difficultyLevel;
  
  /// Skills this challenge helps develop
  final List<String> targetSkills;
  
  /// Related story ID
  final String? storyId;
  
  /// Coding concept this challenge teaches
  final String codingConcept;
  
  /// Cultural context for this challenge
  final Map<String, dynamic> culturalContext;
  
  /// Initial blocks to provide to the user (optional)
  final List<Map<String, dynamic>>? initialBlocks;
  
  /// Block types available to the user for this challenge
  final List<String> availableBlockTypes;
  
  /// Challenge validation rules
  final Map<String, dynamic> validation;
  
  /// List of hints for this challenge
  final List<Map<String, dynamic>> hints;
  
  /// Achievements that can be earned by completing this challenge
  final List<Map<String, dynamic>> achievements;
  
  /// Order of this challenge in a sequence
  final int? sequenceOrder;
  
  /// Constructor
  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.targetSkills,
    this.storyId,
    required this.codingConcept,
    this.culturalContext = const {},
    this.initialBlocks,
    required this.availableBlockTypes,
    required this.validation,
    this.hints = const [],
    this.achievements = const [],
    this.sequenceOrder,
  });
  
  /// Create from JSON
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficultyLevel: json['difficultyLevel'] ?? 1,
      targetSkills: List<String>.from(json['targetSkills'] ?? []),
      storyId: json['storyId'],
      codingConcept: json['codingConcept'] ?? 'patterns',
      culturalContext: json['culturalContext'] ?? {},
      initialBlocks: json['initialBlocks'] != null 
          ? List<Map<String, dynamic>>.from(json['initialBlocks']) 
          : null,
      availableBlockTypes: List<String>.from(json['availableBlockTypes'] ?? []),
      validation: json['validation'] ?? {},
      hints: json['hints'] != null 
          ? List<Map<String, dynamic>>.from(json['hints']) 
          : [],
      achievements: json['achievements'] != null 
          ? List<Map<String, dynamic>>.from(json['achievements']) 
          : [],
      sequenceOrder: json['sequenceOrder'],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficultyLevel': difficultyLevel,
      'targetSkills': targetSkills,
      'storyId': storyId,
      'codingConcept': codingConcept,
      'culturalContext': culturalContext,
      'initialBlocks': initialBlocks,
      'availableBlockTypes': availableBlockTypes,
      'validation': validation,
      'hints': hints,
      'achievements': achievements,
      'sequenceOrder': sequenceOrder,
    };
  }
  
  /// Convert the challenge to a context map for StoryMentorService
  Map<String, dynamic> toMentorContext() {
    return {
      'id': id,
      'codingConcept': codingConcept,
      'difficultyLevel': difficultyLevel,
      'initialBlocks': initialBlocks,
      'availableBlockTypes': availableBlockTypes,
      'validation': validation,
      'hints': hints,
      'culturalContext': culturalContext,
      'achievements': achievements,
    };
  }
}

/// Service for managing challenges
class ChallengeService {
  // Singleton implementation
  static final ChallengeService _instance = ChallengeService._internal();
  
  factory ChallengeService() {
    return _instance;
  }
  
  ChallengeService._internal();
  
  // Storage service
  final StorageService _storageService = StorageService();
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final Uuid _uuid = Uuid();
  
  // Challenge cache
  List<ChallengeModel> _challenges = [];
  bool _isLoaded = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      await _storageService.initialize();
      await _loadChallenges();
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error initializing ChallengeService: $e');
    }
  }
  
  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isLoaded) {
      await initialize();
    }
  }
  
  /// Load challenges from assets and storage
  Future<void> _loadChallenges() async {
    try {
      // First, try to load from assets
      await _loadChallengesFromAssets();
      
      // Then merge with any user-created challenges
      await _loadUserCreatedChallenges();
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }
  }
  
  /// Load predefined challenges from assets
  Future<void> _loadChallengesFromAssets() async {
    try {
      // Load challenges.json from assets
      final jsonString = await rootBundle.loadString('assets/data/challenges.json');
      final jsonData = jsonDecode(jsonString);
      
      if (jsonData['challenges'] != null) {
        final challengesJson = jsonData['challenges'] as List<dynamic>;
        
        // Parse each challenge
        for (final challengeJson in challengesJson) {
          final challenge = ChallengeModel.fromJson(challengeJson);
          _challenges.add(challenge);
        }
      }
      
      debugPrint('Loaded ${_challenges.length} challenges from assets');
    } catch (e) {
      debugPrint('Error loading challenges from assets: $e');
      
      // If no challenge assets found, add a default challenge
      _addDefaultChallenge();
    }
  }
  
  /// Add a default challenge if none are found
  void _addDefaultChallenge() {
    _challenges.add(
      ChallengeModel(
        id: 'default_challenge',
        title: 'Create Your First Pattern',
        description: 'Create a simple pattern using blocks. Connect at least two blocks to create something meaningful.',
        difficultyLevel: 1,
        targetSkills: ['patterns', 'connections'],
        codingConcept: 'patterns',
        availableBlockTypes: ['pattern', 'color', 'structure'],
        validation: {
          'minBlocks': 2,
          'requiredBlockTypes': ['pattern', 'color'],
        },
        hints: [
          {
            'condition': 'blockCount',
            'value': 0,
            'text': 'Start by dragging a block from the palette to the workspace.',
            'tone': 'excited',
          },
          {
            'condition': 'blockCount',
            'value': 1,
            'text': 'Great! Now add another block and connect them.',
            'tone': 'happy',
          },
          {
            'condition': 'hasBlockType',
            'blockType': 'pattern',
            'text': 'You\'ve added a pattern block. These help define the structure of your design.',
            'tone': 'educational',
            'imagePath': 'assets/images/tutorial/pattern_block_explanation.png',
          },
        ],
      ),
    );
  }
  
  /// Load user-created challenges from storage
  Future<void> _loadUserCreatedChallenges() async {
    try {
      // This would load user-created challenges from storage
      // For now, we'll just log that it's not implemented
      debugPrint('Loading user-created challenges not implemented yet');
    } catch (e) {
      debugPrint('Error loading user-created challenges: $e');
    }
  }
  
  /// Get all available challenges
  Future<List<ChallengeModel>> getAllChallenges() async {
    await _ensureInitialized();
    return _challenges;
  }
  
  /// Get a challenge by ID
  Future<ChallengeModel?> getChallengeById(String id) async {
    await _ensureInitialized();
    
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get challenges by difficulty level
  Future<List<ChallengeModel>> getChallengesByDifficulty(int level) async {
    await _ensureInitialized();
    return _challenges.where((c) => c.difficultyLevel == level).toList();
  }
  
  /// Get challenges related to a specific story
  Future<List<ChallengeModel>> getChallengesByStory(String storyId) async {
    await _ensureInitialized();
    return _challenges.where((c) => c.storyId == storyId).toList();
  }
  
  /// Get challenges for a specific coding concept
  Future<List<ChallengeModel>> getChallengesByConcept(String concept) async {
    await _ensureInitialized();
    return _challenges.where((c) => c.codingConcept == concept).toList();
  }
  
  /// Get recommended challenges for a user
  Future<List<ChallengeModel>> getRecommendedChallenges(String userId) async {
    await _ensureInitialized();
    
    final userProgress = await _learningService.getUserProgress(userId);
    if (userProgress == null) {
      // If no user progress, return basic challenges
      return _challenges.where((c) => c.difficultyLevel <= 2).toList();
    }
    
    // Get completed challenge IDs
    final completedChallenges = userProgress.completedChallenges;
    
    // Filter out completed challenges
    final availableChallenges = _challenges
        .where((c) => !completedChallenges.contains(c.id))
        .toList();
    
    // Get user's skill levels
    final skillLevels = userProgress.skills;
    
    // Calculate a score for each challenge based on user's skills and challenge difficulty
    final scoredChallenges = availableChallenges.map((challenge) {
      // Base score is inverse of difficulty (easier challenges score higher)
      double score = 6 - challenge.difficultyLevel;
      
      // Adjust score based on target skills
      for (final skillName in challenge.targetSkills) {
        try {
          // Try to find corresponding skill
          final skillType = SkillType.values.firstWhere(
            (s) => s.toString().split('.').last.toLowerCase() == skillName.toLowerCase(),
            orElse: () => throw Exception('Invalid skill type: $skillName'),
          );
          
          // Get user's skill level for this skill
          final userLevel = userProgress.getSkillLevel(skillType);
          
          // Boost score if user is developing this skill
          // (optimal challenge is slightly above current skill)
          if (userLevel >= SkillLevel.beginner.index && userLevel <= SkillLevel.intermediate.index) {
            score += 1.0;
          }
          
          // Reduce score if challenge is too easy for user's skill level
          if (challenge.difficultyLevel < 3 && userLevel >= SkillLevel.advanced.index) {
            score -= 1.0;
          }
          
          // Reduce score if challenge is too hard for user's skill level
          if (challenge.difficultyLevel > 3 && userLevel <= SkillLevel.novice.index) {
            score -= 1.0;
          }
        } catch (e) {
          // Skill not found, ignore
          debugPrint('Error calculating challenge score: $e');
        }
      }
      
      return {'challenge': challenge, 'score': score};
    }).toList();
    
    // Sort by score descending
    scoredChallenges.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // Return top challenges (limited to 5)
    return scoredChallenges
        .take(5)
        .map((item) => item['challenge'] as ChallengeModel)
        .toList();
  }
  
  /// Create a new challenge
  Future<ChallengeModel> createChallenge({
    required String title,
    required String description,
    required int difficultyLevel,
    required List<String> targetSkills,
    String? storyId,
    required String codingConcept,
    Map<String, dynamic>? culturalContext,
    List<Map<String, dynamic>>? initialBlocks,
    required List<String> availableBlockTypes,
    required Map<String, dynamic> validation,
    List<Map<String, dynamic>>? hints,
    List<Map<String, dynamic>>? achievements,
    int? sequenceOrder,
  }) async {
    await _ensureInitialized();
    
    final newChallenge = ChallengeModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      difficultyLevel: difficultyLevel,
      targetSkills: targetSkills,
      storyId: storyId,
      codingConcept: codingConcept,
      culturalContext: culturalContext ?? {},
      initialBlocks: initialBlocks,
      availableBlockTypes: availableBlockTypes,
      validation: validation,
      hints: hints ?? [],
      achievements: achievements ?? [],
      sequenceOrder: sequenceOrder,
    );
    
    // Add to cache
    _challenges.add(newChallenge);
    
    // Save to storage (would be implemented with real storage)
    // For now, just log
    debugPrint('Created new challenge: ${newChallenge.id}');
    
    return newChallenge;
  }
  
  /// Mark a challenge as completed for a user
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _ensureInitialized();
    
    // Find the challenge
    final challenge = await getChallengeById(challengeId);
    if (challenge == null) {
      throw Exception('Challenge not found: $challengeId');
    }
    
    // Update learning service
    await _learningService.completeChallenge(
      challengeId,
      difficulty: challenge.difficultyLevel,
      improvedSkills: challenge.targetSkills,
    );
    
    debugPrint('Challenge completed: $challengeId by user: $userId');
  }
}