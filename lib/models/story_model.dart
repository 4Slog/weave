import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/content_block_model.dart';
import 'package:uuid/uuid.dart';

/// Represents a challenge associated with a story
class StoryChallenge {
  /// Unique ID for the challenge
  final String id;
  
  /// Title of the challenge
  final String title;
  
  /// Description of the challenge
  final String description;
  
  /// Success criteria for the challenge as JSON map
  final Map<String, dynamic> successCriteria;
  
  /// Difficulty level (1-5)
  final int difficulty;
  
  /// Available block types for this challenge
  final List<String> availableBlockTypes;
  
  /// Starter blocks provided to the user
  final List<BlockModel>? starterBlocks;
  
  /// Index of the story content block where this challenge starts
  final int contentStartIndex;
  
  /// Index of the story content block where this challenge ends
  final int contentEndIndex;
  
  /// Creates a new challenge with the given properties
  StoryChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.successCriteria,
    this.difficulty = 1,
    this.availableBlockTypes = const ['move', 'turn', 'repeat'],
    this.starterBlocks,
    required this.contentStartIndex,
    required this.contentEndIndex,
  });
  
  /// Create a StoryChallenge from JSON data
  factory StoryChallenge.fromJson(Map<String, dynamic> json) {
    List<BlockModel>? starterBlocks;
    if (json['starterBlocks'] != null) {
      starterBlocks = (json['starterBlocks'] as List)
          .map((blockJson) => BlockModel.fromJson(blockJson))
          .toList();
    }
    
    return StoryChallenge(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? 'Challenge',
      description: json['description'] ?? '',
      successCriteria: json['successCriteria'] ?? {},
      difficulty: json['difficulty'] ?? 1,
      availableBlockTypes: json['availableBlockTypes'] != null
          ? List<String>.from(json['availableBlockTypes'])
          : ['move', 'turn', 'repeat'],
      starterBlocks: starterBlocks,
      contentStartIndex: json['contentStartIndex'] ?? 0,
      contentEndIndex: json['contentEndIndex'] ?? 0,
    );
  }
  
  /// Convert this challenge to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'successCriteria': successCriteria,
      'difficulty': difficulty,
      'availableBlockTypes': availableBlockTypes,
      'starterBlocks': starterBlocks?.map((b) => b.toJson()).toList(),
      'contentStartIndex': contentStartIndex,
      'contentEndIndex': contentEndIndex,
    };
  }
}

/// Represents a branch option in a story
class StoryBranch {
  /// Unique ID for the branch
  final String id;
  
  /// Description of the branch option
  final String description;
  
  /// ID of the target story this branch leads to
  final String? targetStoryId;
  
  /// Requirements to access this branch
  final Map<String, dynamic> requirements;
  
  /// Difficulty level (1-5)
  final int difficultyLevel;
  
  /// Creates a branch with the given properties
  StoryBranch({
    required this.id,
    required this.description,
    this.targetStoryId,
    this.requirements = const {},
    this.difficultyLevel = 1,
  });
  
  /// Create a StoryBranch from JSON data
  factory StoryBranch.fromJson(Map<String, dynamic> json) {
    return StoryBranch(
      id: json['id'] ?? const Uuid().v4(),
      description: json['description'] ?? '',
      targetStoryId: json['targetStoryId'],
      requirements: json['requirements'] ?? {},
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }
  
  /// Convert this branch to JSON
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

/// Represents a story in the application
class StoryModel {
  /// Unique ID for the story
  final String id;
  
  /// Title of the story
  final String title;
  
  /// Theme or topic of the story
  final String theme;
  
  /// Cultural region related to this story
  final String region;
  
  /// Character name in the story
  final String characterName;
  
  /// Age group this story is designed for
  final String ageGroup;
  
  /// Content blocks that make up the narrative
  final List<ContentBlock> content;
  
  /// Challenge associated with this story
  final StoryChallenge? challenge;
  
  /// Available branch options after this story
  final List<StoryBranch> branches;
  
  /// Cultural notes and context
  final Map<String, String> culturalNotes;
  
  /// Learning concepts covered in this story
  final List<String> learningConcepts;
  
  /// Creates a new story with the given properties
  StoryModel({
    String? id,
    required this.title,
    required this.theme,
    required this.region,
    required this.characterName,
    required this.ageGroup,
    required this.content,
    this.challenge,
    this.branches = const [],
    this.culturalNotes = const {},
    this.learningConcepts = const [],
  }) : id = id ?? const Uuid().v4();
  
  /// Create a StoryModel from JSON data
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // Parse content blocks
    List<ContentBlock> contentBlocks = [];
    if (json['content'] != null) {
      contentBlocks = (json['content'] as List)
          .map((blockJson) => ContentBlock(
                id: blockJson['id'] ?? const Uuid().v4(),
                text: blockJson['text'] ?? '',
                delay: blockJson['delay'] ?? 0,
                displayDuration: blockJson['displayDuration'] ?? 3000,
                waitForInteraction: blockJson['waitForInteraction'] ?? false,
                imagePath: blockJson['imagePath'],
                animationName: blockJson['animationName'],
              ))
          .toList();
    }
    
    // Parse branches
    List<StoryBranch> branches = [];
    if (json['branches'] != null) {
      branches = (json['branches'] as List)
          .map((branchJson) => StoryBranch.fromJson(branchJson))
          .toList();
    }
    
    // Parse challenge
    StoryChallenge? challenge;
    if (json['challenge'] != null) {
      challenge = StoryChallenge.fromJson(json['challenge']);
    }
    
    // Parse cultural notes
    Map<String, String> culturalNotes = {};
    if (json['culturalNotes'] != null) {
      json['culturalNotes'].forEach((key, value) {
        culturalNotes[key] = value.toString();
      });
    }
    
    return StoryModel(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? 'Untitled Story',
      theme: json['theme'] ?? 'general',
      region: json['region'] ?? 'Ghana',
      characterName: json['characterName'] ?? 'Kwame',
      ageGroup: json['ageGroup'] ?? '7-12',
      content: contentBlocks,
      challenge: challenge,
      branches: branches,
      culturalNotes: culturalNotes,
      learningConcepts: json['learningConcepts'] != null
          ? List<String>.from(json['learningConcepts'])
          : [],
    );
  }
  
  /// Convert this story to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'theme': theme,
      'region': region,
      'characterName': characterName,
      'ageGroup': ageGroup,
      'content': content.map((block) => {
            'id': block.id,
            'text': block.text,
            'delay': block.delay,
            'displayDuration': block.displayDuration,
            'waitForInteraction': block.waitForInteraction,
            'imagePath': block.imagePath,
            'animationName': block.animationName,
          }).toList(),
      'challenge': challenge?.toJson(),
      'branches': branches.map((branch) => branch.toJson()).toList(),
      'culturalNotes': culturalNotes,
      'learningConcepts': learningConcepts,
    };
  }
}