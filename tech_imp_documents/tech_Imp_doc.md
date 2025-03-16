Technical Implementation Document: Kente Codeweaver Enhancements
Overview
This document provides comprehensive technical specifications for implementing enhancements to the Kente Codeweaver application. The enhancements focus on creating a more engaging storytelling experience, implementing adaptive learning features, and developing a robust reward system—all while subtly integrating cultural elements.
Prerequisites
Before beginning implementation, ensure you have:

Flutter SDK (latest stable version)
Access to the existing codebase and assets
Google Gemini API key (in .env file)
Basic understanding of Flutter, Provider state management, and AI integration

Project Structure & Source Files
You'll need to work with the following existing files and create several new ones:
Existing Files to Modify

Models:

lib/models/story_model.dart - Extend with new narrative fields
lib/models/user_progress.dart - Enhance with skill tracking capabilities
lib/models/block_model.dart - Augment with learning concept associations


Providers:

lib/providers/story_provider.dart - Enhance for narrative continuity
lib/providers/block_provider.dart - Modify for adaptive challenge support


Services:

lib/services/gemini_story_service.dart - Update with enhanced prompts
lib/services/storage_service.dart - Extend for additional data storage


UI Components:

lib/screens/story_screen.dart - Update for branching narrative support
lib/screens/block_workspace.dart - Enhance with contextual hints



New Files to Create

Models:

lib/models/badge_model.dart - For achievement system
lib/models/story_branch_model.dart - For narrative branching


Services:

lib/services/story_memory_service.dart - For narrative continuity
lib/services/adaptive_learning_service.dart - For personalized learning
lib/services/story_mentor_service.dart - For contextual guidance
lib/services/engagement_service.dart - For tracking user interaction
lib/services/badge_service.dart - For managing achievements


Providers:

lib/providers/engagement_provider.dart - For engagement state management
lib/providers/badge_provider.dart - For achievement state management


UI Components:

lib/widgets/narrative_choice_widget.dart - For story branching UI
lib/widgets/badge_display_widget.dart - For displaying achievements
lib/widgets/contextual_hint_widget.dart - For in-story guidance



Resource Files
You'll need to create JSON files from the provided TXT versions:

Convert blocks.txt to assets/data/blocks.json
Convert colors_cultural_info.txt to assets/data/colors_cultural_info.json
Convert patterns_cultural_info.txt to assets/data/patterns_cultural_info.json
Convert regional_info.txt to assets/data/regional_info.json
Convert symbols_cultural_info.txt to assets/data/symbols_cultural_info.json

Implementation Phases
Phase 1: Enhanced Storytelling System
1.1 Extend StoryModel
Modify lib/models/story_model.dart to include the following new fields:
dartCopyclass StoryModel {
  final String id;
  final String title;
  final String content;
  final int difficultyLevel;
  final List<String> codeBlocks;
  final String imageUrl;
  
  // New fields for enhanced storytelling
  final String? previousStoryId;  // For story continuation
  final List<String> narrativeHooks;  // Elements to engage users
  final Map<String, dynamic> characterDevelopment;  // How characters evolve
  final List<String> unsolvedMysteries;  // Plot threads for future stories
  final List<String> learningConcepts;  // Coding concepts in the story
  final String narrativeType;  // e.g., "mystery", "adventure", "exploration"
  final String endingType;  // e.g., "cliffhanger", "resolved", "choice"
  final Map<String, String> nextStoryHints;  // Hints for future stories

  StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.difficultyLevel,
    required this.codeBlocks,
    this.imageUrl = '',
    this.previousStoryId,
    this.narrativeHooks = const [],
    this.characterDevelopment = const {},
    this.unsolvedMysteries = const [],
    this.learningConcepts = const [],
    this.narrativeType = 'standard',
    this.endingType = 'standard',
    this.nextStoryHints = const {},
  });

  // Update fromJson and toJson methods to handle new fields
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      difficultyLevel: json['difficultyLevel'],
      codeBlocks: List<String>.from(json['codeBlocks']),
      imageUrl: json['imageUrl'] ?? '',
      previousStoryId: json['previousStoryId'],
      narrativeHooks: json['narrativeHooks'] != null 
          ? List<String>.from(json['narrativeHooks']) 
          : [],
      characterDevelopment: json['characterDevelopment'] ?? {},
      unsolvedMysteries: json['unsolvedMysteries'] != null 
          ? List<String>.from(json['unsolvedMysteries']) 
          : [],
      learningConcepts: json['learningConcepts'] != null 
          ? List<String>.from(json['learningConcepts']) 
          : [],
      narrativeType: json['narrativeType'] ?? 'standard',
      endingType: json['endingType'] ?? 'standard',
      nextStoryHints: json['nextStoryHints'] != null 
          ? Map<String, String>.from(json['nextStoryHints']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'difficultyLevel': difficultyLevel,
      'codeBlocks': codeBlocks,
      'imageUrl': imageUrl,
      'previousStoryId': previousStoryId,
      'narrativeHooks': narrativeHooks,
      'characterDevelopment': characterDevelopment,
      'unsolvedMysteries': unsolvedMysteries,
      'learningConcepts': learningConcepts,
      'narrativeType': narrativeType,
      'endingType': endingType,
      'nextStoryHints': nextStoryHints,
    };
  }
}
1.2 Create StoryBranchModel
Create a new model at lib/models/story_branch_model.dart:
dartCopyclass StoryBranchModel {
  final String id;
  final String description;
  final String targetStoryId;
  final Map<String, dynamic> requirements;
  final int difficultyLevel;

  StoryBranchModel({
    required this.id,
    required this.description,
    required this.targetStoryId,
    this.requirements = const {},
    this.difficultyLevel = 1,
  });

  factory StoryBranchModel.fromJson(Map<String, dynamic> json) {
    return StoryBranchModel(
      id: json['id'],
      description: json['description'],
      targetStoryId: json['targetStoryId'],
      requirements: json['requirements'] ?? {},
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'targetStoryId': targetStoryId,
      'requirements': requirements,
      'difficultyLevel': difficultyLevel,
    };
  }
}
1.3 Create StoryMemoryService
Create a new service at lib/services/story_memory_service.dart:
dartCopyimport 'dart:convert';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/services/storage_service.dart';

class StoryMemoryService {
  final StorageService _storageService = StorageService();
  
  // Store user's story history
  Future<void> saveStoryProgress(String userId, StoryModel story) async {
    // Get existing story history
    final storyHistory = await getStoryHistory(userId);
    
    // Add the current story to history
    storyHistory.add({
      'storyId': story.id,
      'timestamp': DateTime.now().toIso8601String(),
      'choices': [], // Will be populated as user makes choices
      'completedChallenges': [],
    });
    
    // Save updated history
    await _storageService.saveProgress('${userId}_story_history', jsonEncode(storyHistory));
  }
  
  // Get user's story history
  Future<List<Map<String, dynamic>>> getStoryHistory(String userId) async {
    final historyJson = await _storageService.getProgress('${userId}_story_history');
    if (historyJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> history = jsonDecode(historyJson);
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing story history: $e');
      return [];
    }
  }
  
  // Record a choice made within a story
  Future<void> recordStoryChoice(String userId, String storyId, String choiceId, String result) async {
    final storyHistory = await getStoryHistory(userId);
    
    // Find the current story in history
    final storyIndex = storyHistory.indexWhere((item) => item['storyId'] == storyId);
    if (storyIndex == -1) {
      return; // Story not found in history
    }
    
    // Add the choice to the story
    storyHistory[storyIndex]['choices'].add({
      'choiceId': choiceId,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Save updated history
    await _storageService.saveProgress('${userId}_story_history', jsonEncode(storyHistory));
  }
  
  // Get narrative elements to reference in future stories
  Future<Map<String, dynamic>> getNarrativeContext(String userId) async {
    final storyHistory = await getStoryHistory(userId);
    
    // Extract characters, unresolved mysteries, and achievements from history
    List<String> characters = [];
    List<String> unsolvedMysteries = [];
    List<String> achievements = [];
    
    // Process in reverse order to prioritize recent stories
    for (var item in storyHistory.reversed) {
      final storyJson = await _storageService.getProgress('story_${item['storyId']}');
      if (storyJson != null) {
        final story = StoryModel.fromJson(jsonDecode(storyJson));
        
        // Extract characters
        if (story.characterDevelopment.isNotEmpty) {
          characters.addAll(
            story.characterDevelopment.keys
                .where((char) => !characters.contains(char))
          );
        }
        
        // Extract unsolved mysteries
        unsolvedMysteries.addAll(
          story.unsolvedMysteries
              .where((mystery) => !unsolvedMysteries.contains(mystery))
        );
        
        // Limit the size of lists to prevent prompts from becoming too large
        if (characters.length > 5) characters = characters.sublist(0, 5);
        if (unsolvedMysteries.length > 3) unsolvedMysteries = unsolvedMysteries.sublist(0, 3);
        if (achievements.length > 5) achievements = achievements.sublist(0, 5);
      }
    }
    
    return {
      'characters': characters,
      'unsolvedMysteries': unsolvedMysteries,
      'achievements': achievements,
    };
  }
}
1.4 Enhance GeminiStoryService
Update lib/services/gemini_story_service.dart with improved prompts:
dartCopy// Add this method to the existing GeminiStoryService class
Future<StoryModel> generateEnhancedStory({
  required int age,
  required String theme,
  String? characterName,
  String? previousStoryId,
  String? narrativeType,
  Map<String, dynamic>? narrativeContext,
  List<String>? conceptsToTeach,
}) async {
  // Get narrative context if not provided
  if (narrativeContext == null && previousStoryId != null) {
    final userId = 'current_user'; // Replace with actual user ID
    final memoryService = StoryMemoryService();
    narrativeContext = await memoryService.getNarrativeContext(userId);
  }
  
  final storyType = narrativeType ?? _getRandomNarrativeType();
  
  // Create an enhanced prompt for Gemini
  final prompt = '''
  Create a captivating coding adventure story for a child aged $age about $theme.
  ${characterName != null ? 'Feature the character named $characterName as the protagonist.' : ''}
  ${previousStoryId != null ? 'This is a continuation of a previous story.' : 'This is the beginning of a new story.'}
  
  The story should be written as a "${storyType}" narrative.
  
  Structure the story with:
  1. An engaging opening that introduces a relatable problem
  2. A compelling middle where the character discovers how coding concepts can help
  3. An exciting climax where the coding solution is applied
  4. A resolution that leaves some elements unresolved for future adventures
  5. End with a hook/cliffhanger that makes the reader eager to continue
  
  ${conceptsToTeach != null && conceptsToTeach.isNotEmpty ? 'Naturally weave these coding concepts into the narrative: ${conceptsToTeach.join(', ')}' : 'Include age-appropriate coding concepts that would be engaging to learn.'}
  
  ${narrativeContext != null && narrativeContext['characters'].isNotEmpty ? 'Include these characters from previous stories: ${narrativeContext['characters'].join(', ')}' : ''}
  ${narrativeContext != null && narrativeContext['unsolvedMysteries'].isNotEmpty ? 'Reference these unresolved elements from previous stories: ${narrativeContext['unsolvedMysteries'].join(', ')}' : ''}
  
  Include diverse character perspectives, descriptive language, and dialogue.
  Make sure the story is engaging enough to stand on its own as a great adventure.
  
  Format as JSON with the following fields:
  id, title, content, difficultyLevel, codeBlocks, previousStoryId, narrativeHooks, characterDevelopment, unsolvedMysteries, learningConcepts, narrativeType, endingType, nextStoryHints
  ''';

  try {
    // Use Gemini to generate the story
    final response = await _gemini.prompt(
      parts: [gemini.Part.text(prompt)],
    );

    // Extract the text response
    final responseText = extractTextFromResponse(response);
    
    // Validate and parse response
    if (responseText.isEmpty) {
      throw Exception('Empty response from Gemini API');
    }

    // Extract JSON from response text
    final jsonStr = extractJsonFromText(responseText);
    
    // Create a story model from the JSON
    final storyModel = StoryModel.fromJson(jsonDecode(jsonStr));
    
    // Cache the response
    final cacheKey = 'story_${theme}_${age}_${characterName ?? ""}_${previousStoryId ?? ""}_${storyType}';
    await _storageService.saveProgress(cacheKey, jsonStr);
    
    return storyModel;
  } catch (e) {
    throw Exception('Failed to generate enhanced story: $e');
  }
}

// Helper method to get a random narrative type
String _getRandomNarrativeType() {
  final types = ['adventure', 'mystery', 'exploration', 'challenge'];
  return types[DateTime.now().millisecond % types.length];
}
1.5 Update StoryProvider
Enhance lib/providers/story_provider.dart to support the new story generation features:
dartCopy// Add these properties to the StoryProvider class
List<StoryModel> _storyHistory = [];
List<StoryBranchModel> _availableBranches = [];
bool _isGeneratingBranches = false;
Map<String, dynamic> _narrativeContext = {};

// Add these getters
List<StoryModel> get storyHistory => _storyHistory;
List<StoryBranchModel> get availableBranches => _availableBranches;
bool get isGeneratingBranches => _isGeneratingBranches;

// Add this method to generate an enhanced story
Future<void> generateEnhancedStory({
  required int age,
  required String theme,
  String? characterName,
  String? previousStoryId,
  String? narrativeType,
  List<String>? conceptsToTeach,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    // Get narrative context from story memory service
    final memoryService = StoryMemoryService();
    _narrativeContext = await memoryService.getNarrativeContext('current_user');
    
    // Generate the enhanced story
    final story = await _storyService.generateEnhancedStory(
      age: age,
      theme: theme,
      characterName: characterName,
      previousStoryId: previousStoryId,
      narrativeType: narrativeType,
      narrativeContext: _narrativeContext,
      conceptsToTeach: conceptsToTeach,
    );
    
    _currentStory = story;
    
    // Add to stories list if not already there
    if (!_stories.any((s) => s.id == story.id)) {
      _stories.add(story);
    }
    
    // Add to story history
    _storyHistory.add(story);
    
    // Record story in memory service
    await memoryService.saveStoryProgress('current_user', story);
    
    // Generate story branches
    generateStoryBranches();
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _error = e.toString();
    notifyListeners();
  }
}

// Add this method to generate possible story continuations
Future<void> generateStoryBranches() async {
  if (_currentStory == null) return;
  
  _isGeneratingBranches = true;
  notifyListeners();
  
  try {
    // TODO: Implement story branch generation logic using Gemini
    // This is a placeholder - in a complete implementation, 
    // we would use Gemini to generate multiple possible continuations
    
    // For now, create some sample branches
    _availableBranches = [
      StoryBranchModel(
        id: 'branch_1',
        description: 'Follow the mysterious path into the forest',
        targetStoryId: 'future_story_1',
        difficultyLevel: 2,
      ),
      StoryBranchModel(
        id: 'branch_2',
        description: 'Help the village solve their coding puzzle',
        targetStoryId: 'future_story_2',
        difficultyLevel: 1,
      ),
    ];
    
    _isGeneratingBranches = false;
    notifyListeners();
  } catch (e) {
    _isGeneratingBranches = false;
    _error = e.toString();
    notifyListeners();
  }
}

// Add this method to choose a story branch
Future<void> selectStoryBranch(StoryBranchModel branch) async {
  // Record the user's choice
  final memoryService = StoryMemoryService();
  await memoryService.recordStoryChoice(
    'current_user',
    _currentStory!.id,
    branch.id,
    branch.description,
  );
  
  // Generate the next story based on the branch
  await generateEnhancedStory(
    age: 10, // This should be read from user profile
    theme: _currentStory!.title.split(' ').first, // Simple theme extraction
    previousStoryId: _currentStory!.id,
    narrativeType: _currentStory!.narrativeType,
  );
}
Phase 2: Adaptive Learning Implementation
2.1 Extend UserProgress Model
Enhance lib/models/user_progress.dart to track skill proficiency:
dartCopyclass UserProgress {
  final String userId;
  final List<String> completedStories;
  final Map<String, int> storyScores;
  final int totalBlocks;
  final int currentLevel;
  
  // New fields for adaptive learning
  final Map<String, double> skillProficiency;
  final List<String> conceptsMastered;
  final List<String> conceptsInProgress;
  final List<String> earnedBadges;
  final Map<String, int> challengeAttempts;
  final Map<String, int> attentionMetrics;
  final String preferredLearningStyle;
  
  UserProgress({
    required this.userId,
    this.completedStories = const [],
    this.storyScores = const {},
    this.totalBlocks = 0,
    this.currentLevel = 1,
    this.skillProficiency = const {},
    this.conceptsMastered = const [],
    this.conceptsInProgress = const [],
    this.earnedBadges = const [],
    this.challengeAttempts = const {},
    this.attentionMetrics = const {},
    this.preferredLearningStyle = 'visual', // Default learning style
  });
  
  UserProgress copyWith({
    String? userId,
    List<String>? completedStories,
    Map<String, int>? storyScores,
    int? totalBlocks,
    int? currentLevel,
    Map<String, double>? skillProficiency,
    List<String>? conceptsMastered,
    List<String>? conceptsInProgress,
    List<String>? earnedBadges,
    Map<String, int>? challengeAttempts,
    Map<String, int>? attentionMetrics,
    String? preferredLearningStyle,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      completedStories: completedStories ?? this.completedStories,
      storyScores: storyScores ?? this.storyScores,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      currentLevel: currentLevel ?? this.currentLevel,
      skillProficiency: skillProficiency ?? this.skillProficiency,
      conceptsMastered: conceptsMastered ?? this.conceptsMastered,
      conceptsInProgress: conceptsInProgress ?? this.conceptsInProgress,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      attentionMetrics: attentionMetrics ?? this.attentionMetrics,
      preferredLearningStyle: preferredLearningStyle ?? this.preferredLearningStyle,
    );
  }
  
  // Update fromJson and toJson methods to handle new fields
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'],
      completedStories: List<String>.from(json['completedStories'] ?? []),
      storyScores: Map<String, int>.from(json['storyScores'] ?? {}),
      totalBlocks: json['totalBlocks'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      skillProficiency: json['skillProficiency'] != null
          ? Map<String, double>.from(json['skillProficiency'])
          : {},
      conceptsMastered: List<String>.from(json['conceptsMastered'] ?? []),
      conceptsInProgress: List<String>.from(json['conceptsInProgress'] ?? []),
      earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
      challengeAttempts: json['challengeAttempts'] != null
          ? Map<String, int>.from(json['challengeAttempts'])
          : {},
      attentionMetrics: json['attentionMetrics'] != null
          ? Map<String, int>.from(json['attentionMetrics'])
          : {},
      preferredLearningStyle: json['preferredLearningStyle'] ?? 'visual',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completedStories': completedStories,
      'storyScores': storyScores,
      'totalBlocks': totalBlocks,
      'currentLevel': currentLevel,
      'skillProficiency': skillProficiency,
      'conceptsMastered': conceptsMastered,
      'conceptsInProgress': conceptsInProgress,
      'earnedBadges': earnedBadges,
      'challengeAttempts': challengeAttempts,
      'attentionMetrics': attentionMetrics,
      'preferredLearningStyle': preferredLearningStyle,
    };
  }
}
2.2 Create BadgeModel
Create a new model at lib/models/badge_model.dart:
dartCopyclass BadgeModel {
  final String id;
  final String name;
  final String description;
  final String imageAssetPath;
  final Map<String, double> requiredSkills;
  final String? storyReward;
  final int tier; // 1, 2, 3 (basic, intermediate, advanced)
  
  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAssetPath,
    this.requiredSkills = const {},
    this.storyReward,
    this.tier = 1,
  });
  
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageAssetPath: json['imageAssetPath'],
      requiredSkills: json['requiredSkills'] != null
          ? Map<String, double>.from(json['requiredSkills'])
          : {},
      storyReward: json['storyReward'],
      tier: json['tier'] ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageAssetPath': imageAssetPath,
      'requiredSkills': requiredSkills,
      'storyReward': storyReward,
      'tier': tier,
    };
  }
}
2.3 Create AdaptiveLearningService
Create a new service at lib/services/adaptive_learning_service.dart:
dartCopyimport 'dart:convert';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/storage_service.dart';

class AdaptiveLearningService {
  final StorageService _storageService = StorageService();
  
  // Skill threshold for mastery
  static const double _masteryThreshold = 0.8;
  
  // Get user's learning profile
  Future<UserProgress> getUserProgress(String userId) async {
    final progressJson = await _storageService.getProgress('${userId}_progress');
    if (progressJson == null) {
      // Create a new user progress if none exists
      return UserProgress(userId: userId);
    }
    
    try {
      return UserProgress.fromJson(jsonDecode(progressJson));
    } catch (e) {
      print('Error parsing user progress: $e');
      return UserProgress(userId: userId);
    }
  }
  
  // Save user's learning profile
  Future<void> saveUserProgress(UserProgress progress) async {
    await _storageService.saveProgress(
      '${progress.userId}_progress',
      jsonEncode(progress.toJson()),
    );
  }
  
  // Update skill proficiency based on challenge results
  Future<UserProgress> updateSkillProficiency(
    String userId,
    String conceptId,
    bool success,
    double difficulty,
  ) async {
    final progress = await getUserProgress(userId);
    
    // Get current proficiency or default to 0.0
    final currentProficiency = progress.skillProficiency[conceptId] ?? 0.0;
    
    // Calculate proficiency change based on success and difficulty
    // Success increases proficiency more for harder challenges
    // Failure decreases proficiency less for harder challenges
    final double change = success
        ? 0.05 + (difficulty * 0.05) // 0.05-0.15 increase for success
        : -0.03 - (0.10 - difficulty * 0.02); // 0.03-0.01 decrease for failure
    
    // Calculate new proficiency, clamped between 0 and 1
    double newProficiency = (currentProficiency + change).clamp(0.0, 1.0);
    
    // Create updated skill proficiency map
    Map<String, double> updatedSkills = Map.from(progress.skillProficiency);
    updatedSkills[conceptId] = newProficiency;
    
    // Update lists of mastered and in-progress concepts
    List<String> conceptsMastered = List.from(progress.conceptsMastered);
    List<String> conceptsInProgress = List.from(progress.conceptsInProgress);
    
    // Check if concept has been mastered
    if (newProficiency >= _masteryThreshold && 
        !conceptsMastered.contains(conceptId)) {
      conceptsMastered.add(conceptId);
      conceptsInProgress.remove(conceptId);
    } 
    // Check if concept is in progress
    else if (newProficiency < _masteryThreshold && 
        !conceptsInProgress.contains(conceptId) &&
        !conceptsMastered.contains(conceptId)) {
      conceptsInProgress.add(conceptId);
    }
    
    // Update challenge attempts
    Map<String, int> challengeAttempts = Map.from(progress.challengeAttempts);
    challengeAttempts[conceptId] = (challengeAttempts[conceptId] ?? 0) + 1;
    
    // Create updated progress
    final updatedProgress = progress.copyWith(
      skillProficiency: updatedSkills,
      conceptsMastered: conceptsMastered,
      conceptsInProgress: conceptsInProgress,
      challengeAttempts: challengeAttempts,
    );
    
    // Save updated progress
    await saveUserProgress(updatedProgress);
    
    return updatedProgress;
  }
  
  // Determine the next concept to teach based on user progress
  Future<String> recommendNextConcept(String userId) async {
    final progress = await getUserProgress(userId);
    
    // Concepts ordered by typical learning progression
    final orderedConcepts = [
      'loops',
      'conditionals',
      'variables',
      'functions',
      'arrays',
      'operators',
    ];
    
    // First, check for concepts in progress that aren't mastered
    for (final concept in orderedConcepts) {
      if (progress.conceptsInProgress.contains(concept) &&
          !progress.conceptsMastered.contains(concept)) {
        return concept;
      }
    }
    
    // Then, find the firstRetryClaude hit the max length for a message and has paused its response. You can write Continue to keep the chat going.PScontinueEditTechnical Implementation Document: Kente Codeweaver Enhancements (Continued)
2.3 Create AdaptiveLearningService (Continued)
dartCopy    // Then, find the first concept not yet mastered
    for (final concept in orderedConcepts) {
      if (!progress.conceptsMastered.contains(concept)) {
        return concept;
      }
    }
    
    // If all basic concepts are mastered, suggest an advanced concept
    final advancedConcepts = [
      'recursion',
      'algorithms',
      'data_structures',
      'problem_solving',
    ];
    
    for (final concept in advancedConcepts) {
      if (!progress.conceptsMastered.contains(concept)) {
        return concept;
      }
    }
    
    // If all concepts are mastered, suggest reviewing the first one
    return orderedConcepts.first;
  }
  
  // Determine appropriate difficulty for a concept
  Future<double> recommendDifficulty(String userId, String conceptId) async {
    final progress = await getUserProgress(userId);
    
    // Get current proficiency or default to 0.0
    final proficiency = progress.skillProficiency[conceptId] ?? 0.0;
    
    // Adjust difficulty based on proficiency
    // Low proficiency -> lower difficulty (0.1-0.4)
    // Medium proficiency -> medium difficulty (0.4-0.7)
    // High proficiency -> high difficulty (0.7-1.0)
    if (proficiency < 0.3) {
      return 0.2; // Easy
    } else if (proficiency < 0.6) {
      return 0.5; // Medium
    } else {
      return 0.8; // Hard
    }
  }
  
  // Detect user's preferred learning style based on performance
  Future<String> detectLearningStyle(String userId) async {
    final progress = await getUserProgress(userId);
    
    // This would typically involve more sophisticated analysis
    // For simplicity, we're using a basic heuristic based on challenge attempts
    
    // If user has no data yet, return default
    if (progress.challengeAttempts.isEmpty) {
      return 'visual';
    }
    
    // Count successes by concept type (simplified example)
    int visualSuccess = 0;
    int logicalSuccess = 0;
    int practicalSuccess = 0;
    
    // In a real implementation, we would categorize concepts by learning style
    // and analyze user performance in each category
    
    // Return the learning style with highest success rate
    if (visualSuccess > logicalSuccess && visualSuccess > practicalSuccess) {
      return 'visual';
    } else if (logicalSuccess > visualSuccess && logicalSuccess > practicalSuccess) {
      return 'logical';
    } else {
      return 'practical';
    }
  }
}
2.4 Create StoryMentorService
Create a new service at lib/services/story_mentor_service.dart:
dartCopyimport 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';

class StoryMentorService {
  late final gemini.Gemini _gemini;
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  
  // Initialize the Gemini service
  Future<void> initialize() async {
    try {
      // Get API key from environment variables
      final String? apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found');
      }

      // Initialize Gemini with the API key
      gemini.Gemini.init(apiKey: apiKey);
      _gemini = gemini.Gemini.instance;
      
    } catch (e) {
      throw Exception('Failed to initialize StoryMentorService: $e');
    }
  }
  
  // Generate contextual hints based on the story context and coding concept
  Future<String> generateContextualHint({
    required String userId,
    required String storyContext,
    required String codingConcept,
    required int hintLevel,
    String? learningStyle,
  }) async {
    // Get user progress to personalize hint
    final progress = await _learningService.getUserProgress(userId);
    
    // Determine learning style if not provided
    final style = learningStyle ?? progress.preferredLearningStyle;
    
    // Create prompt for Gemini
    final prompt = '''
    Generate a helpful coding hint for a child learning about "${codingConcept}".
    
    Story context: "${storyContext}"
    
    This is hint number ${hintLevel} (1 is subtle, 3 is more direct).
    
    The child prefers a "${style}" learning style.
    
    The hint should:
    1. Stay within the story context
    2. Be age-appropriate and encouraging
    3. Guide without giving away the complete solution
    4. Be appropriate for hint level ${hintLevel}
    
    For a visual learner, use more imagery and spatial references.
    For a logical learner, focus on patterns and reasoning.
    For a practical learner, relate to real-world examples.
    ''';

    try {
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );

      // Extract the text response
      final String hintText = response.text ?? "";
      
      if (hintText.isEmpty) {
        // Fallback hints if AI generation fails
        return _getFallbackHint(codingConcept, hintLevel);
      }
      
      return hintText;
    } catch (e) {
      print('Error generating hint: $e');
      return _getFallbackHint(codingConcept, hintLevel);
    }
  }
  
  // Provide fallback hints if AI generation fails
  String _getFallbackHint(String concept, int hintLevel) {
    // Basic fallback hints for common concepts
    final Map<String, List<String>> fallbackHints = {
      'loops': [
        'Think about tasks that need to be repeated multiple times in the story.',
        'You might need to use a repeat block to perform an action several times.',
        'Try using a loop block to repeat the same action instead of placing multiple blocks.'
      ],
      'conditionals': [
        'Consider what decisions the character needs to make in the story.',
        'You might need to check if something is true before taking an action.',
        'Use an if block to check a condition before performing an action.'
      ],
      'variables': [
        'Is there anything in the story that changes or needs to be remembered?',
        'You might need to store information for later use in your solution.',
        'Try creating a variable to keep track of important information.'
      ],
      'functions': [
        'Look for patterns of actions that could be grouped together.',
        'Could you create a reusable set of instructions for the character?',
        'Try creating a function block to group related actions together.'
      ],
    };
    
    // Return appropriate hint based on concept and level
    if (fallbackHints.containsKey(concept) && 
        hintLevel <= fallbackHints[concept]!.length) {
      return fallbackHints[concept]![hintLevel - 1];
    }
    
    // Generic fallback hint
    return 'Think about how the concepts you\'ve learned could help solve this problem.';
  }
  
  // Analyze user's solution and provide feedback
  Future<Map<String, dynamic>> analyzeSolution({
    required String userId,
    required List<dynamic> userSolution,
    required String expectedConcept,
    required String storyContext,
  }) async {
    // This would typically involve more sophisticated analysis
    // For simplicity, we're using a basic check
    
    // Check if the solution contains the expected concept
    bool conceptUsed = userSolution.any((block) => 
        block['type'].toString().toLowerCase().contains(expectedConcept.toLowerCase()));
    
    if (conceptUsed) {
      return {
        'success': true,
        'feedback': 'Great job using $expectedConcept to solve the problem!',
        'conceptUsed': true,
      };
    } else {
      return {
        'success': false,
        'feedback': 'Try thinking about how $expectedConcept could help you solve this problem.',
        'conceptUsed': false,
      };
    }
  }
}
Phase 3: Engagement and Rewards System
3.1 Create EngagementService
Create a new service at lib/services/engagement_service.dart:
dartCopyimport 'dart:convert';
import 'package:kente_codeweaver/services/storage_service.dart';

class EngagementService {
  final StorageService _storageService = StorageService();
  
  // Track user's session start time
  Future<void> recordSessionStart(String userId) async {
    final sessionData = {
      'startTime': DateTime.now().toIso8601String(),
      'interactions': [],
    };
    
    await _storageService.saveProgress(
      '${userId}_current_session',
      jsonEncode(sessionData),
    );
  }
  
  // Record user interaction with the app
  Future<void> recordInteraction(String userId, String type, Map<String, dynamic> details) async {
    // Get current session data
    final sessionJson = await _storageService.getProgress('${userId}_current_session');
    if (sessionJson == null) {
      // Start a new session if none exists
      await recordSessionStart(userId);
      await recordInteraction(userId, type, details);
      return;
    }
    
    try {
      Map<String, dynamic> sessionData = jsonDecode(sessionJson);
      
      // Add the interaction
      List<dynamic> interactions = sessionData['interactions'] ?? [];
      interactions.add({
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
      });
      
      sessionData['interactions'] = interactions;
      
      // Save updated session data
      await _storageService.saveProgress(
        '${userId}_current_session',
        jsonEncode(sessionData),
      );
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }
  
  // End current session and save metrics
  Future<void> recordSessionEnd(String userId) async {
    // Get current session data
    final sessionJson = await _storageService.getProgress('${userId}_current_session');
    if (sessionJson == null) return;
    
    try {
      Map<String, dynamic> sessionData = jsonDecode(sessionJson);
      
      // Add end time
      sessionData['endTime'] = DateTime.now().toIso8601String();
      
      // Calculate session duration
      final startTime = DateTime.parse(sessionData['startTime']);
      final endTime = DateTime.parse(sessionData['endTime']);
      final duration = endTime.difference(startTime).inSeconds;
      sessionData['durationSeconds'] = duration;
      
      // Get all sessions
      final sessionsJson = await _storageService.getProgress('${userId}_sessions');
      List<dynamic> sessions = sessionsJson != null 
          ? jsonDecode(sessionsJson) 
          : [];
      
      // Add this session
      sessions.add(sessionData);
      
      // Save all sessions
      await _storageService.saveProgress(
        '${userId}_sessions',
        jsonEncode(sessions),
      );
      
      // Clear current session
      await _storageService.deleteProgress('${userId}_current_session');
    } catch (e) {
      print('Error recording session end: $e');
    }
  }
  
  // Calculate engagement score based on interaction patterns
  Future<double> calculateEngagementScore(String userId) async {
    // Get all sessions
    final sessionsJson = await _storageService.getProgress('${userId}_sessions');
    if (sessionsJson == null) return 0.5; // Default score
    
    try {
      List<dynamic> sessions = jsonDecode(sessionsJson);
      
      // If no sessions, return default score
      if (sessions.isEmpty) return 0.5;
      
      // Analyze recent sessions (up to last 5)
      List<dynamic> recentSessions = sessions.length > 5 
          ? sessions.sublist(sessions.length - 5) 
          : sessions;
      
      // Factors that indicate engagement:
      // 1. Session duration
      // 2. Interaction frequency
      // 3. Completion of challenges
      // 4. Return frequency
      
      // Calculate average session duration (normalized to 0-1)
      double avgDuration = 0.0;
      for (var session in recentSessions) {
        avgDuration += (session['durationSeconds'] ?? 0) / 1800.0; // Normalize to 30 min
      }
      avgDuration = (avgDuration / recentSessions.length).clamp(0.0, 1.0);
      
      // Calculate average interactions per minute
      double avgInteractionsPerMinute = 0.0;
      for (var session in recentSessions) {
        final interactions = session['interactions']?.length ?? 0;
        final minutes = (session['durationSeconds'] ?? 0) / 60.0;
        if (minutes > 0) {
          avgInteractionsPerMinute += (interactions / minutes) / 10.0; // Normalize to 10/min
        }
      }
      avgInteractionsPerMinute = (avgInteractionsPerMinute / recentSessions.length).clamp(0.0, 1.0);
      
      // Calculate challenge completion rate
      int totalChallenges = 0;
      int completedChallenges = 0;
      for (var session in recentSessions) {
        for (var interaction in (session['interactions'] ?? [])) {
          if (interaction['type'] == 'challenge_attempt') {
            totalChallenges++;
            if (interaction['details']['success'] == true) {
              completedChallenges++;
            }
          }
        }
      }
      double completionRate = totalChallenges > 0 
          ? (completedChallenges / totalChallenges).clamp(0.0, 1.0) 
          : 0.5;
      
      // Calculate return frequency (days between sessions)
      double returnFrequency = 0.0;
      if (recentSessions.length > 1) {
        List<int> daysBetween = [];
        for (int i = 1; i < recentSessions.length; i++) {
          final previousEnd = DateTime.parse(recentSessions[i-1]['endTime']);
          final currentStart = DateTime.parse(recentSessions[i]['startTime']);
          final days = currentStart.difference(previousEnd).inDays;
          daysBetween.add(days);
        }
        
        // Average days between sessions (inverse, normalized)
        double avgDays = daysBetween.reduce((a, b) => a + b) / daysBetween.length;
        returnFrequency = (1.0 / (avgDays + 1.0)).clamp(0.0, 1.0);
      } else {
        returnFrequency = 0.5; // Default for first session
      }
      
      // Weighted engagement score
      double engagementScore = 
          (avgDuration * 0.3) +
          (avgInteractionsPerMinute * 0.2) +
          (completionRate * 0.3) +
          (returnFrequency * 0.2);
      
      return engagementScore;
    } catch (e) {
      print('Error calculating engagement score: $e');
      return 0.5; // Default score on error
    }
  }
  
  // Recommend story adjustments based on engagement level
  Future<Map<String, dynamic>> recommendStoryAdjustments(String userId) async {
    // Calculate engagement score
    final engagementScore = await calculateEngagementScore(userId);
    
    // Recommend adjustments based on score
    if (engagementScore < 0.3) {
      // Major engagement issue - introduce dramatic elements
      return {
        'adjustmentType': 'major_twist',
        'intensity': 'high',
        'recommendations': [
          'Introduce an unexpected plot twist',
          'Add a new character with an urgent problem',
          'Create a high-stakes challenge',
          'Reduce story length by 30%',
          'Add more visual elements',
        ],
      };
    } else if (engagementScore < 0.6) {
      // Moderate engagement - add new elements
      return {
        'adjustmentType': 'new_element',
        'intensity': 'medium',
        'recommendations': [
          'Introduce a minor mystery or puzzle',
          'Add a supporting character',
          'Include more interactive elements',
          'Reduce story length by 15%',
          'Add more dialogue',
        ],
      };
    } else {
      // Good engagement - continue current approach
      return {
        'adjustmentType': 'minor_variation',
        'intensity': 'low',
        'recommendations': [
          'Continue current narrative style',
          'Gradually increase challenge difficulty',
          'Develop existing character relationships',
          'Maintain current story length',
          'Add subtle foreshadowing',
        ],
      };
    }
  }
}
3.2 Create BadgeService
Create a new service at lib/services/badge_service.dart:
dartCopyimport 'dart:convert';
import 'package:kente_codeweaver/models/badge_model.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';

class BadgeService {
  final StorageService _storageService = StorageService();
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  
  // Get all available badges
  Future<List<BadgeModel>> getAvailableBadges() async {
    // In a production app, this would load from a data file
    // For now, we'll define some sample badges
    
    return [
      BadgeModel(
        id: 'loop_master',
        name: 'Loop Master',
        description: 'Mastered the art of loops in coding',
        imageAssetPath: 'assets/images/badges/loop_master.png',
        requiredSkills: {'loops': 0.8},
        tier: 1,
      ),
      BadgeModel(
        id: 'conditional_expert',
        name: 'Conditional Expert',
        description: 'Expert at using conditionals to make decisions',
        imageAssetPath: 'assets/images/badges/conditional_expert.png',
        requiredSkills: {'conditionals': 0.8},
        tier: 1,
      ),
      BadgeModel(
        id: 'variable_virtuoso',
        name: 'Variable Virtuoso',
        description: 'Skilled at using variables to store information',
        imageAssetPath: 'assets/images/badges/variable_virtuoso.png',
        requiredSkills: {'variables': 0.8},
        tier: 1,
      ),
      BadgeModel(
        id: 'function_master',
        name: 'Function Master',
        description: 'Mastered the art of creating reusable functions',
        imageAssetPath: 'assets/images/badges/function_master.png',
        requiredSkills: {'functions': 0.8},
        tier: 2,
      ),
      BadgeModel(
        id: 'pattern_creator',
        name: 'Pattern Creator',
        description: 'Created beautiful patterns using code',
        imageAssetPath: 'assets/images/badges/pattern_creator.png',
        requiredSkills: {'loops': 0.7, 'variables': 0.6},
        tier: 2,
      ),
      BadgeModel(
        id: 'story_explorer',
        name: 'Story Explorer',
        description: 'Completed 5 coding stories',
        imageAssetPath: 'assets/images/badges/story_explorer.png',
        tier: 1,
      ),
      BadgeModel(
        id: 'debugging_hero',
        name: 'Debugging Hero',
        description: 'Successfully fixed challenging code problems',
        imageAssetPath: 'assets/images/badges/debugging_hero.png',
        requiredSkills: {'debugging': 0.7},
        tier: 2,
      ),
      BadgeModel(
        id: 'coding_adventurer',
        name: 'Coding Adventurer',
        description: 'Completed stories across multiple narrative paths',
        imageAssetPath: 'assets/images/badges/coding_adventurer.png',
        tier: 3,
      ),
    ];
  }
  
  // Check if user has earned any new badges
  Future<List<BadgeModel>> checkForNewBadges(String userId) async {
    // Get user progress
    final progress = await _learningService.getUserProgress(userId);
    
    // Get all available badges
    final allBadges = await getAvailableBadges();
    
    // Filter to only badges not yet earned
    final unearnedBadges = allBadges.where(
      (badge) => !progress.earnedBadges.contains(badge.id)
    ).toList();
    
    // Check each unearned badge to see if requirements are met
    List<BadgeModel> newlyEarnedBadges = [];
    
    for (final badge in unearnedBadges) {
      bool requirementsMet = true;
      
      // Check skill requirements
      for (final entry in badge.requiredSkills.entries) {
        final skill = entry.key;
        final requiredLevel = entry.value;
        final userLevel = progress.skillProficiency[skill] ?? 0.0;
        
        if (userLevel < requiredLevel) {
          requirementsMet = false;
          break;
        }
      }
      
      // Check story count requirements
      if (badge.id == 'story_explorer' && progress.completedStories.length < 5) {
        requirementsMet = false;
      }
      
      // Check coding adventurer requirements
      if (badge.id == 'coding_adventurer') {
        // This would check if user has completed stories across different paths
        // For now, we'll just check if they've completed 10+ stories
        if (progress.completedStories.length < 10) {
          requirementsMet = false;
        }
      }
      
      // If all requirements met, add to newly earned badges
      if (requirementsMet) {
        newlyEarnedBadges.add(badge);
      }
    }
    
    // If any new badges earned, update user progress
    if (newlyEarnedBadges.isNotEmpty) {
      // Add new badge IDs to earned badges
      List<String> updatedBadges = List.from(progress.earnedBadges);
      for (final badge in newlyEarnedBadges) {
        updatedBadges.add(badge.id);
      }
      
      // Update user progress
      final updatedProgress = progress.copyWith(
        earnedBadges: updatedBadges,
      );
      
      await _learningService.saveUserProgress(updatedProgress);
    }
    
    return newlyEarnedBadges;
  }
  
  // Get user's earned badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    // Get user progress
    final progress = await _learningService.getUserProgress(userId);
    
    // Get all badges
    final allBadges = await getAvailableBadges();
    
    // Filter to only earned badges
    return allBadges.where(
      (badge) => progress.earnedBadges.contains(badge.id)
    ).toList();
  }
}
Phase 4: UI Enhancements
4.1 Create ContextualHintWidget
Create a new widget at lib/widgets/contextual_hint_widget.dart:
dartCopyimport 'package:flutter/material.dart';
import 'package:kente_codeweaver/services/story_mentor_service.dart';

class ContextualHintWidget extends StatefulWidget {
  final String storyContext;
  final String codingConcept;
  final String userId;
  
  const ContextualHintWidget({
    Key? key,
    required this.storyContext,
    required this.codingConcept,
    required this.userId,
  }) : super(key: key);
  
  @override
  _ContextualHintWidgetState createState() => _ContextualHintWidgetState();
}

class _ContextualHintWidgetState extends State<ContextualHintWidget> {
  final StoryMentorService _mentorService = StoryMentorService();
  int _currentHintLevel = 1;
  String? _currentHint;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMentorService();
  }
  
  Future<void> _initializeMentorService() async {
    try {
      await _mentorService.initialize();
    } catch (e) {
      print('Error initializing mentor service: $e');
    }
  }
  
  Future<void> _getNextHint() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hint = await _mentorService.generateContextualHint(
        userId: widget.userId,
        storyContext: widget.storyContext,
        codingConcept: widget.codingConcept,
        hintLevel: _currentHintLevel,
      );
      
      setState(() {
        _currentHint = hint;
        _currentHintLevel = _currentHintLevel < 3 ? _currentHintLevel + 1 : 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentHint = 'I\'m having trouble thinking of a hint right now. Try exploring different approaches!';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/ananse_explaining.png',
                  width: 60,
                  height: 60,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kweku Ananse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_currentHint != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentHint!,
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              Text(
                'Need a hint? I can help you with this challenge!',
                style: TextStyle(fontSize: 16),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _getNextHint,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text(_currentHint == null ? 'Get Hint' : 'Another Hint'),
            ),
          ],
        ),
      ),
    );
  }
}
4.2 Create BadgeDisplayWidget
Create a new widget at lib/widgets/badge_display_widget.dart:
dartCopyimport 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

class BadgeDisplayWidget extends StatelessWidget {
  final List<BadgeModel> badges;
  final void Function(BadgeModel)? onBadgeTap;
  
  const BadgeDisplayWidget({
    Key? key,
    required this.badges,
    this.onBadgeTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return badges.isEmpty
        ? _buildEmptyState()
        : _buildBadgeGrid();
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No badges earned yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete coding challenges to earn badges',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgeGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(badge);
      },
    );
  }
  
  Widget _buildBadgeItem(BadgeModel badge) {
    return InkWell(
      onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _getTierColor(badge.tier).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTierColor(badge.tier),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              badge.imageAssetPath,
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: _getTierColor(badge.tier),
                );
              },
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTierColor(int tier) {
    return switch (tier) {
      1 => Colors.green,
      2 => Colors.blue,
      3 => Colors.purple,
      _ => Colors.grey,
    };
  }
}
A.3 Create NarrativeChoiceWidget
Create a new widget at lib/widgets/narrative_choice_widget.dart:
dartCopyimport 'package:flutter/materialRetryClaude hit the max length for a message and has paused its response. You can write Continue to keep the chat going.PScontinueEditTechnical Implementation Document: Kente Codeweaver Enhancements (Continued)
4.3 Create NarrativeChoiceWidget
Create a new widget at lib/widgets/narrative_choice_widget.dart:
dartCopyimport 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/story_branch_model.dart';

class NarrativeChoiceWidget extends StatelessWidget {
  final List<StoryBranchModel> branches;
  final Function(StoryBranchModel) onBranchSelected;
  
  const NarrativeChoiceWidget({
    Key? key,
    required this.branches,
    required this.onBranchSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'What happens next?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...branches.map((branch) => _buildChoiceCard(context, branch)).toList(),
      ],
    );
  }
  
  Widget _buildChoiceCard(BuildContext context, StoryBranchModel branch) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getDifficultyColor(branch.difficultyLevel),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onBranchSelected(branch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  branch.description,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _getDifficultyColor(branch.difficultyLevel),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(int difficultyLevel) {
    return switch (difficultyLevel) {
      1 => Colors.green,
      2 => Colors.amber,
      3 => Colors.orange,
      4 => Colors.red,
      5 => Colors.purple,
      _ => Colors.blue,
    };
  }
}
Phase 5: Integration with Existing Screens
5.1 Update StoryScreen
Modify lib/screens/story_screen.dart to integrate the new features:
dartCopyimport 'package:flutter/material.dart';
import 'package:kente_codeweaver/screens/block_workspace.dart';
import 'package:kente_codeweaver/providers/story_provider.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/services/tts_service.dart';
import 'package:kente_codeweaver/services/engagement_service.dart';
import 'package:kente_codeweaver/services/badge_service.dart';
import 'package:kente_codeweaver/widgets/narrative_choice_widget.dart';
import 'package:kente_codeweaver/models/badge_model.dart';
import 'package:provider/provider.dart';

class StoryScreen extends StatefulWidget {
  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TTSService _ttsService = TTSService();
  final EngagementService _engagementService = EngagementService();
  final BadgeService _badgeService = BadgeService();
  
  bool _isSpeaking = false;
  bool _showingChoices = false;
  bool _isCheckingBadges = false;
  List<BadgeModel> _newBadges = [];
  
  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _trackEngagement();
    _checkForNewBadges();
  }
  
  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }
  
  Future<void> _trackEngagement() async {
    // Record story view interaction
    await _engagementService.recordInteraction(
      'current_user',
      'story_view',
      {
        'storyId': Provider.of<StoryProvider>(context, listen: false).currentStory?.id ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  Future<void> _checkForNewBadges() async {
    if (_isCheckingBadges) return;
    
    setState(() {
      _isCheckingBadges = true;
    });
    
    try {
      final newBadges = await _badgeService.checkForNewBadges('current_user');
      if (newBadges.isNotEmpty) {
        setState(() {
          _newBadges = newBadges;
        });
        
        // Show badge earned dialog after a short delay
        Future.delayed(Duration(seconds: 1), () {
          _showBadgeEarnedDialog(newBadges.first);
        });
      }
    } catch (e) {
      print('Error checking for badges: $e');
    } finally {
      setState(() {
        _isCheckingBadges = false;
      });
    }
  }
  
  void _showBadgeEarnedDialog(BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Badge Earned!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              badge.imageAssetPath,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.emoji_events, size: 100, color: Colors.amber);
              },
            ),
            SizedBox(height: 16),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Show next badge if there are more
              if (_newBadges.length > 1) {
                _newBadges.removeAt(0);
                _showBadgeEarnedDialog(_newBadges.first);
              }
            },
            child: Text('AWESOME!'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSpeech,
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          final story = storyProvider.currentStory;
          
          if (story == null) {
            return Center(child: Text('No story available'));
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(story.difficultyLevel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${story.difficultyLevel}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    if (story.narrativeType.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getNarrativeTypeColor(story.narrativeType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _capitalizeFirstLetter(story.narrativeType),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  story.content,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                
                // Narrative choices
                if (_showingChoices && storyProvider.availableBranches.isNotEmpty)
                  NarrativeChoiceWidget(
                    branches: storyProvider.availableBranches,
                    onBranchSelected: (branch) {
                      storyProvider.selectStoryBranch(branch);
                      setState(() {
                        _showingChoices = false;
                      });
                    },
                  ),
                
                // Learning concepts
                if (story.learningConcepts.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Coding Concepts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: story.learningConcepts
                        .map((concept) => Chip(
                              label: Text(_capitalizeFirstLetter(concept)),
                              backgroundColor: Colors.blue.shade100,
                            ))
                        .toList(),
                  ),
                ],
                
                SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Record challenge start
                          _engagementService.recordInteraction(
                            'current_user',
                            'challenge_start',
                            {
                              'storyId': story.id,
                              'timestamp': DateTime.now().toIso8601String(),
                            },
                          );
                          
                          // Set available blocks in the provider
                          final blockProvider = Provider.of<BlockProvider>(context, listen: false);
                          blockProvider.setAvailableBlocks(story.codeBlocks);
                          
                          // Navigate to block workspace
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BlockWorkspace()),
                          ).then((_) {
                            // Record challenge completion when returning
                            _engagementService.recordInteraction(
                              'current_user',
                              'challenge_complete',
                              {
                                'storyId': story.id,
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                            
                            // Show story branches after challenge
                            setState(() {
                              _showingChoices = true;
                            });
                            
                            // Check for badges
                            _checkForNewBadges();
                          });
                        },
                        child: Text('Start Coding Challenge'),
                      ),
                      SizedBox(height: 20),
                      if (!_showingChoices)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showingChoices = true;
                            });
                            
                            // Generate branches if not already loaded
                            if (storyProvider.availableBranches.isEmpty) {
                              storyProvider.generateStoryBranches();
                            }
                          },
                          icon: Icon(Icons.arrow_forward),
                          label: Text('Continue Story'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _toggleSpeech() async {
    final story = Provider.of<StoryProvider>(context, listen: false).currentStory;
    
    if (story == null) return;
    
    setState(() {
      _isSpeaking = !_isSpeaking;
    });
    
    if (_isSpeaking) {
      await _ttsService.speak(story.content);
      
      // Record TTS usage for engagement tracking
      await _engagementService.recordInteraction(
        'current_user',
        'tts_usage',
        {
          'storyId': story.id,
          'action': 'start',
        },
      );
    } else {
      await _ttsService.stop();
      
      // Record TTS usage for engagement tracking
      await _engagementService.recordInteraction(
        'current_user',
        'tts_usage',
        {
          'storyId': story.id,
          'action': 'stop',
        },
      );
    }
  }
  
  Color _getDifficultyColor(int level) {
    return switch (level) {
      1 => Colors.green,
      2 => Colors.lightGreen,
      3 => Colors.amber,
      4 => Colors.orange,
      5 => Colors.red,
      _ => Colors.blue,
    };
  }
  
  Color _getNarrativeTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'adventure' => Colors.orange,
      'mystery' => Colors.purple,
      'exploration' => Colors.teal,
      'challenge' => Colors.red,
      _ => Colors.blue,
    };
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
5.2 Update BlockWorkspace
Modify lib/screens/block_workspace.dart to include contextual hints:
dartCopy// Add these imports at the top of the file
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';
import 'package:kente_codeweaver/providers/story_provider.dart';
import 'package:kente_codeweaver/services/story_mentor_service.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';

// Add these properties to the _BlockWorkspaceState class
final StoryMentorService _mentorService = StoryMentorService();
final AdaptiveLearningService _learningService = AdaptiveLearningService();
bool _showingHint = false;
String _feedback = '';
bool _showFeedback = false;

// Add this method to the _BlockWorkspaceState class
@override
void initState() {
  super.initState();
  _initializeMentorService();
}

Future<void> _initializeMentorService() async {
  try {
    await _mentorService.initialize();
  } catch (e) {
    print('Error initializing mentor service: $e');
  }
}

// Modify the build method to include the hint widget
// Inside the body Column, after the workspace area:
if (_showingHint) {
  final story = Provider.of<StoryProvider>(context, listen: false).currentStory;
  if (story != null && story.learningConcepts.isNotEmpty) {
    return ContextualHintWidget(
      storyContext: story.content.substring(0, min(150, story.content.length)),
      codingConcept: story.learningConcepts.first,
      userId: 'current_user',
    );
  }
}

// Add a floating action button to the scaffold
floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (_showFeedback)
      Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(_feedback),
      ),
    FloatingActionButton(
      onPressed: () {
        setState(() {
          _showingHint = !_showingHint;
        });
      },
      child: Icon(_showingHint ? Icons.lightbulb : Icons.lightbulb_outline),
      tooltip: 'Get a hint',
    ),
  ],
),

// Modify the _validateWorkspace method to include adaptive learning
void _validateWorkspace() {
  final blocks = Provider.of<BlockProvider>(context, listen: false).blocks;
  final story = Provider.of<StoryProvider>(context, listen: false).currentStory;
  
  if (blocks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add some blocks to the workspace first!'))
    );
    return;
  }
  
  // Check if the story has learning concepts
  if (story != null && story.learningConcepts.isNotEmpty) {
    final primaryConcept = story.learningConcepts.first;
    
    // Analyze solution
    _mentorService.analyzeSolution(
      userId: 'current_user',
      userSolution: blocks.map((b) => b.toJson()).toList(),
      expectedConcept: primaryConcept,
      storyContext: story.content.substring(0, min(150, story.content.length)),
    ).then((result) {
      // Update skill proficiency
      _learningService.updateSkillProficiency(
        'current_user',
        primaryConcept,
        result['success'] ?? false,
        story.difficultyLevel / 5.0,
      );
      
      // Show feedback
      setState(() {
        _feedback = result['feedback'] ?? '';
        _showFeedback = true;
      });
      
      // Hide feedback after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
          });
        }
      });
      
      // Show success or failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] ?? false
              ? 'Great job! Your code works!'
              : 'Your solution needs some work. Try again!'),
          backgroundColor: result['success'] ?? false ? Colors.green : Colors.orange,
        )
      );
    });
  } else {
    // Fallback for stories without specific learning concepts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great job! Your code works!'),
        backgroundColor: Colors.green,
      )
    );
  }
}
JSON File Conversion
For each .txt file, create a corresponding .json file in the appropriate directory:

Convert blocks.txt to assets/data/blocks.json
Convert colors_cultural_info.txt to assets/data/colors_cultural_info.json
Convert patterns_cultural_info.txt to assets/data/patterns_cultural_info.json
Convert regional_info.txt to assets/data/regional_info.json
Convert symbols_cultural_info.txt to assets/data/symbols_cultural_info.json

Example process for each file:

Create the target directory if it doesn't exist: mkdir -p assets/data
Copy the content from the .txt file to a new .json file
Validate the JSON syntax (you can use online tools or VS Code's JSON validation)

Testing Guidelines

Linting Tests

Run flutter analyze to identify syntax or style issues
Fix all critical errors before proceeding


Widget Testing

Test all new UI components with basic widget tests
Focus on proper rendering and state management


Integration Testing

Test the end-to-end story flow including branching narratives
Verify adaptive learning features adjust properly based on user performance


Manual Testing

Test all features with different user profiles (beginners, experienced users)
Verify TTS narration works correctly with the enhanced stories
Test with different device orientations and screen sizes



Conclusion
This implementation plan provides a comprehensive roadmap for enhancing the Kente Codeweaver application with a focus on immersive storytelling, adaptive learning, and rewards systems. The phased approach allows for incremental improvements while ensuring each component integrates smoothly with the existing codebase.
The enhancements maintain the application's core focus on teaching coding concepts through engaging narratives while subtly incorporating cultural elements. The AI-driven adaptivity ensures each user receives a personalized learning experience tailored to their skill level and preferences.
By following this technical implementation document, you'll be able to transform Kente Codeweaver into a more engaging, adaptive, and rewarding learning platform that keeps users coming back for more coding adventures.