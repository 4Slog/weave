import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/emotional_tone.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';

/// Service that provides storytelling mentorship and adaptive guidance
/// Based on user actions and pattern creation.
class StoryMentorService {
  // Singleton implementation
  static final StoryMentorService _instance = StoryMentorService._internal();
  
  factory StoryMentorService() {
    return _instance;
  }
  
  StoryMentorService._internal();

  // Current challenge context
  Map<String, dynamic> _currentChallengeContext = {};
  
  // Mentoring state
  int _consecutiveErrors = 0;
  DateTime? _lastActionTime;
  int _timeWithoutProgress = 0;
  List<Map<String, dynamic>> _recentActions = [];
  BlockCollection? _lastBlockCollection;
  
  // Random number generator for occasional cultural hints
  final Random _random = Random();
  
  /// Sets the current challenge context for mentoring
  void setCurrentChallengeContext(Map<String, dynamic> context) {
    _currentChallengeContext = context;
    _resetMentoringState();
  }
  
  /// Resets the mentoring state when starting a new challenge
  void _resetMentoringState() {
    _consecutiveErrors = 0;
    _lastActionTime = null;
    _timeWithoutProgress = 0;
    _recentActions = [];
  }
  
  /// Records a user action to track progress and provide appropriate hints
  void recordUserAction({
    required String actionType,
    required bool wasSuccessful,
    String? blockId,
    String? errorType,
    Map<String, dynamic>? additionalData,
  }) {
    final now = DateTime.now();
    
    // Track errors
    if (!wasSuccessful) {
      _consecutiveErrors++;
    } else {
      _consecutiveErrors = 0;
    }
    
    // Calculate time since last action
    if (_lastActionTime != null) {
      final difference = now.difference(_lastActionTime!).inSeconds;
      if (difference > 30) {  // If more than 30 seconds between actions
        _timeWithoutProgress += difference;
      } else {
        // Reset if user is actively working
        _timeWithoutProgress = 0;
      }
    }
    
    _lastActionTime = now;
    
    // Store the action for analysis
    _recentActions.add({
      'actionType': actionType,
      'wasSuccessful': wasSuccessful,
      'timestamp': now.millisecondsSinceEpoch,
      'blockId': blockId,
      'errorType': errorType,
      ...additionalData ?? {},
    });
    
    // Keep only the last 10 actions
    if (_recentActions.length > 10) {
      _recentActions.removeAt(0);
    }
    
    // Log the action for debugging
    debugPrint('User action: $actionType, Success: $wasSuccessful, Block: $blockId');
  }
  
  /// Updates time without progress - should be called periodically
  void updateTimeWithoutProgress(int secondsElapsed) {
    _timeWithoutProgress += secondsElapsed;
  }
  
  /// Gets a contextual hint based on user actions and current state
  Map<String, dynamic> getContextualHint(
    BlockCollection blockCollection, 
    UserProgress userProgress
  ) {
    // Store the current block collection for comparison
    _lastBlockCollection = blockCollection;
    
    // Default hint (generic)
    String hintText = "Try connecting blocks to create patterns!";
    EmotionalTone tone = EmotionalTone.neutral;
    String? imagePath;
    bool isImportant = false;
    
    // Check for specific scenarios that need hints
    if (_consecutiveErrors >= 3) {
      // User is struggling with a specific concept
      hintText = "I notice you're having some difficulty. Try looking at how the connections between blocks work.";
      tone = EmotionalTone.concerned;
      isImportant = true;
    } else if (_timeWithoutProgress > 120) {
      // User hasn't made progress in 2 minutes
      hintText = "Seems like you're thinking! Remember, you can drag blocks from the palette and connect them together.";
      tone = EmotionalTone.thoughtful;
      isImportant = true;
    } else if (blockCollection.blocks.isEmpty) {
      // No blocks placed yet
      hintText = "Start by dragging some blocks from the block palette onto the workspace!";
      tone = EmotionalTone.excited;
    } else if (blockCollection.blocks.length == 1) {
      // Only one block placed
      hintText = "Great start! Now try adding another block and connecting them together.";
      tone = EmotionalTone.happy;
    } else if (!blockCollection.validateConnections()) {
      // Connections are invalid
      hintText = "Some of your connections don't seem right. Make sure each block is properly connected!";
      tone = EmotionalTone.concerned;
    }
    
    // Check if we have specific context-based hints from current challenge
    if (_currentChallengeContext.containsKey('hints')) {
      final List<dynamic> contextHints = _currentChallengeContext['hints'];
      
      // Find applicable context hints
      for (var hint in contextHints) {
        // Check for block count hints
        if (hint['condition'] == 'blockCount' && 
            blockCollection.blocks.length == hint['value']) {
          hintText = hint['text'];
          tone = _parseTone(hint['tone'] ?? 'neutral');
          imagePath = hint['imagePath'];
          break;
        }
        
        // Check for block type hints
        if (hint['condition'] == 'hasBlockType' && 
            hint.containsKey('blockType') && 
            blockCollection.containsBlockType(hint['blockType'])) {
          hintText = hint['text'];
          tone = _parseTone(hint['tone'] ?? 'neutral');
          imagePath = hint['imagePath'];
          break;
        }
        
        // Check for connection hints
        if (hint['condition'] == 'hasConnection' && 
            hint.containsKey('connection') && 
            blockCollection.containsConnection(hint['connection'])) {
          hintText = hint['text'];
          tone = _parseTone(hint['tone'] ?? 'neutral');
          imagePath = hint['imagePath'];
          break;
        }
        
        // Check for missing required block type
        if (hint['condition'] == 'missingBlockType' && 
            hint.containsKey('blockType') && 
            !blockCollection.containsBlockType(hint['blockType']) && 
            _currentChallengeContext.containsKey('validation') &&
            _currentChallengeContext['validation'].containsKey('requiredBlockTypes') &&
            List<String>.from(_currentChallengeContext['validation']['requiredBlockTypes'])
              .contains(hint['blockType'])) {
          hintText = hint['text'];
          tone = _parseTone(hint['tone'] ?? 'concerned');
          imagePath = hint['imagePath'];
          isImportant = true;
          break;
        }
      }
    }
    
    // Consider user skill level from UserProgress
    if (userProgress.skillLevel > 3 && hintText == "Try connecting blocks to create patterns!") {
      hintText = "Remember to create meaningful patterns that tell a story with your connections.";
      tone = EmotionalTone.wise;
    }
    
    // Provide cultural context-based hints when appropriate
    if (_currentChallengeContext.containsKey('culturalContext') && 
        blockCollection.blocks.length >= 2 &&
        userProgress.skillLevel >= 2) {
      
      // 25% chance to show a cultural hint instead of a regular hint
      // when there are no critical issues to address
      if (!isImportant && _consecutiveErrors == 0 && _timeWithoutProgress < 60 && 
          _random.nextDouble() < 0.25) {
        final culturalContext = _currentChallengeContext['culturalContext'];
        if (culturalContext is Map && culturalContext.containsKey('hints')) {
          final culturalHints = List<Map<String, dynamic>>.from(culturalContext['hints']);
          if (culturalHints.isNotEmpty) {
            final randomHint = culturalHints[_random.nextInt(culturalHints.length)];
            hintText = randomHint['text'];
            tone = _parseTone(randomHint['tone'] ?? 'wise');
            imagePath = randomHint['imagePath'];
          }
        }
      }
    }
    
    return {
      'text': hintText,
      'tone': tone,
      'imagePath': imagePath,
      'isImportant': isImportant,
    };
  }
  
  /// Parse emotional tone from string
  EmotionalTone _parseTone(String toneStr) {
    switch (toneStr.toLowerCase()) {
      case 'happy':
        return EmotionalTone.happy;
      case 'excited':
        return EmotionalTone.excited;
      case 'curious':
        return EmotionalTone.curious;
      case 'concerned':
        return EmotionalTone.concerned;
      case 'sad':
        return EmotionalTone.sad;
      case 'proud':
        return EmotionalTone.proud;
      case 'thoughtful':
        return EmotionalTone.thoughtful;
      case 'wise':
        return EmotionalTone.wise;
      default:
        return EmotionalTone.neutral;
    }
  }
  
  /// Validates a pattern against the current challenge requirements
  bool validatePatternForChallenge(BlockCollection pattern) {
    // First, check if the pattern is valid by itself (all connections valid)
    if (!pattern.isValidPattern()) {
      return false;
    }
    
    // If no challenge context is set, we can't validate
    if (_currentChallengeContext.isEmpty) {
      return false; // Can't validate without a challenge context
    }
    
    // Get the validation rules from the challenge context
    if (!_currentChallengeContext.containsKey('validation')) {
      return true; // No validation rules means any valid pattern is acceptable
    }
    
    final validation = _currentChallengeContext['validation'];
    
    // Check required block types
    if (validation.containsKey('requiredBlockTypes')) {
      final requiredTypes = List<String>.from(validation['requiredBlockTypes']);
      
      // Make sure all required types are present
      for (var type in requiredTypes) {
        if (!pattern.containsBlockType(type)) {
          return false; // Missing a required block type
        }
      }
    }
    
    // Check minimum block count
    if (validation.containsKey('minBlocks') && 
        pattern.blocks.length < validation['minBlocks']) {
      return false; // Not enough blocks
    }
    
    // Check maximum block count
    if (validation.containsKey('maxBlocks') && 
        pattern.blocks.length > validation['maxBlocks']) {
      return false; // Too many blocks
    }
    
    // Check required connections
    if (validation.containsKey('requiredConnections')) {
      final requiredConnections = List<Map<String, dynamic>>.from(
        validation['requiredConnections']
      );
      
      // Check each required connection
      for (var connectionSpec in requiredConnections) {
        if (!pattern.containsConnection(connectionSpec)) {
          return false; // Missing a required connection
        }
      }
    }
    
    // Check for a specific pattern structure if defined
    if (validation.containsKey('patternStructure')) {
      final structure = validation['patternStructure'];
      
      // This would be a more complex validation based on the specific 
      // structure requirements - can be extended based on need
      if (structure == 'loop') {
        // Validate that blocks form a loop
        if (!_validateLoopStructure(pattern)) {
          return false;
        }
      } else if (structure == 'symmetrical') {
        // Validate pattern symmetry
        if (!_validateSymmetry(pattern)) {
          return false;
        }
      }
    }
    
    // Check for cultural requirements if defined
    if (validation.containsKey('culturalElements')) {
      final culturalElements = List<Map<String, dynamic>>.from(
        validation['culturalElements']
      );
      
      // Validate cultural elements are included
      for (var element in culturalElements) {
        if (!_validateCulturalElement(pattern, element)) {
          return false;
        }
      }
    }
    
    // All validation checks passed
    return true;
  }
  
  /// Validates if blocks form a loop structure
  bool _validateLoopStructure(BlockCollection pattern) {
    // A loop requires that we can traverse connections and return to starting point
    if (pattern.blocks.isEmpty) return false;
    
    // Start from any block
    var startBlock = pattern.blocks.first;
    Set<String> visitedBlocks = {};
    
    // Try to find a loop starting from this block
    return _findLoop(pattern, startBlock.id, startBlock.id, visitedBlocks, 0);
  }
  
  /// Recursive helper to find a loop in the pattern
  bool _findLoop(
    BlockCollection pattern, 
    String currentBlockId, 
    String targetBlockId, 
    Set<String> visitedBlocks, 
    int depth
  ) {
    // If we've already visited this block, not a loop
    if (visitedBlocks.contains(currentBlockId) && currentBlockId != targetBlockId) {
      return false;
    }
    
    // If we've found our target after visiting at least 3 blocks
    if (currentBlockId == targetBlockId && depth > 2) {
      return true;
    }
    
    // Mark current block as visited
    visitedBlocks.add(currentBlockId);
    
    // Get the current block
    final currentBlock = pattern.findBlockById(currentBlockId);
    if (currentBlock == null) return false;
    
    // Check all connections from this block
    for (var conn in currentBlock.connections) {
      if (conn.connectedToId != null) {
        // Try to follow this connection
        if (_findLoop(pattern, conn.connectedToId!, targetBlockId, 
                      Set<String>.from(visitedBlocks), depth + 1)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Validates if a pattern has symmetrical structure
  bool _validateSymmetry(BlockCollection pattern) {
    // This would implement symmetry checking
    // For now, this is a placeholder that could be expanded later
    
    // Basic check: even number of blocks
    if (pattern.blocks.length % 2 != 0) {
      return false;
    }
    
    // A more complex symmetry check would analyze the pattern structure
    // based on connection topology and block types
    
    // For now we'll just return true since we've verified block count
    return true;
  }
  
  /// Validates if a pattern contains required cultural elements
  bool _validateCulturalElement(BlockCollection pattern, Map<String, dynamic> element) {
    String elementType = element['type'];
    String elementValue = element['value'];
    
    // Check if any block has this cultural element
    for (var block in pattern.blocks) {
      if (block.properties.containsKey('culturalElements')) {
        var culturalElements = block.properties['culturalElements'];
        
        if (culturalElements is Map && 
            culturalElements.containsKey(elementType) &&
            culturalElements[elementType] == elementValue) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Get a list of achievements the user can earn in the current challenge
  List<Map<String, dynamic>> getAvailableAchievements() {
    if (_currentChallengeContext.containsKey('achievements')) {
      return List<Map<String, dynamic>>.from(_currentChallengeContext['achievements']);
    }
    return [];
  }
  
  /// Check if the user has earned any achievements with their current pattern
  List<Map<String, dynamic>> checkForEarnedAchievements(
    BlockCollection pattern, 
    UserProgress userProgress
  ) {
    final earnedAchievements = <Map<String, dynamic>>[];
    
    // Get available achievements
    final achievements = getAvailableAchievements();
    
    for (var achievement in achievements) {
      bool earned = false;
      
      // Simple achievement for pattern size
      if (achievement.containsKey('requiredBlockCount')) {
        earned = pattern.blocks.length >= achievement['requiredBlockCount'];
      }
      
      // Achievement for using specific block types
      if (achievement.containsKey('requiredBlockTypes')) {
        final types = achievement['requiredBlockTypes'] as List;
        earned = types.every((type) => pattern.containsBlockType(type));
      }
      
      // Other custom achievement checks can be added here
      
      if (earned) {
        earnedAchievements.add(achievement);
      }
    }
    
    return earnedAchievements;
  }
}