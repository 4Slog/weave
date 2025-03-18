import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/models/emotional_tone.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/services/cultural_data_service.dart';
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;

/// Service that provides storytelling mentorship and adaptive guidance
/// Based on user actions, pattern creation, and AI-driven contextual hints.
class StoryMentorService {
  // Singleton implementation
  static final StoryMentorService _instance = StoryMentorService._internal();
  
  factory StoryMentorService() {
    return _instance;
  }
  
  StoryMentorService._internal();
  
  // Services
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final CulturalDataService _culturalDataService = CulturalDataService();
  
  // Gemini AI instance
  late final gemini.Gemini _gemini;
  bool _isGeminiInitialized = false;

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
  
  /// Initialize the Gemini AI service
  Future<void> initialize() async {
    if (_isGeminiInitialized) return;
    
    try {
      // Initialize Gemini
      _gemini = gemini.Gemini.instance;
      _isGeminiInitialized = true;
      
      // Initialize cultural data service
      await _culturalDataService.initialize();
      
      debugPrint('StoryMentorService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize StoryMentorService: $e');
    }
  }
  
  /// Gets a contextual hint based on user actions and current state
  Future<Map<String, dynamic>> getContextualHint(
    BlockCollection blockCollection, 
    UserProgress userProgress
  ) async {
    // Store the current block collection for comparison
    _lastBlockCollection = blockCollection;
    
    // Ensure Gemini is initialized
    if (!_isGeminiInitialized) {
      await initialize();
    }
    
    // Default hint (generic)
    String hintText = "Try connecting blocks to create patterns!";
    EmotionalTone tone = EmotionalTone.neutral;
    String? imagePath;
    bool isImportant = false;
    
    // First check for critical scenarios that need immediate hints
    if (_consecutiveErrors >= 3) {
      // User is struggling with a specific concept
      hintText = await _generateAIHint(
        blockCollection, 
        userProgress, 
        "The user is struggling with connections. Provide a helpful hint about how to connect blocks properly.",
        hintLevel: 2
      );
      tone = EmotionalTone.concerned;
      isImportant = true;
    } else if (_timeWithoutProgress > 120) {
      // User hasn't made progress in 2 minutes
      hintText = await _generateAIHint(
        blockCollection, 
        userProgress, 
        "The user hasn't made progress in 2 minutes. Provide an encouraging hint to help them get started.",
        hintLevel: 1
      );
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
      hintText = await _generateAIHint(
        blockCollection, 
        userProgress, 
        "The user has invalid connections in their pattern. Provide a hint about proper connections.",
        hintLevel: 1
      );
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
          hintText = await _generateAIHint(
            blockCollection,
            userProgress,
            "The user is missing a required block type: ${hint['blockType']}. Provide a hint about using this type of block.",
            hintLevel: 2
          );
          tone = _parseTone(hint['tone'] ?? 'concerned');
          imagePath = hint['imagePath'];
          isImportant = true;
          break;
        }
      }
    }
    
    // Consider user skill level from UserProgress
    if (userProgress.level > 3 && hintText == "Try connecting blocks to create patterns!") {
      hintText = await _generateAIHint(
        blockCollection,
        userProgress,
        "The user is advanced (level ${userProgress.level}). Provide a sophisticated hint about creating meaningful patterns.",
        hintLevel: 1
      );
      tone = EmotionalTone.wise;
    }
    
    // Provide cultural context-based hints when appropriate
    if (_currentChallengeContext.containsKey('culturalContext') && 
        blockCollection.blocks.length >= 2 &&
        userProgress.level >= 2) {
      
      // 25% chance to show a cultural hint instead of a regular hint
      // when there are no critical issues to address
      if (!isImportant && _consecutiveErrors == 0 && _timeWithoutProgress < 60 && 
          _random.nextDouble() < 0.25) {
        final culturalContext = _currentChallengeContext['culturalContext'];
        if (culturalContext is Map && culturalContext.containsKey('hints')) {
          final culturalHints = List<Map<String, dynamic>>.from(culturalContext['hints']);
          if (culturalHints.isNotEmpty) {
            final randomHint = culturalHints[_random.nextInt(culturalHints.length)];
            
            // Generate AI-enhanced cultural hint
            hintText = await _generateCulturalHint(
              blockCollection,
              userProgress,
              randomHint['text'],
            );
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
  
  /// Generate an AI-driven hint based on the current context
  Future<String> _generateAIHint(
    BlockCollection blockCollection,
    UserProgress userProgress,
    String context,
    {int hintLevel = 1}
  ) async {
    // If Gemini is not initialized, return a fallback hint
    if (!_isGeminiInitialized) {
      return _getFallbackHint(context, hintLevel);
    }
    
    try {
      // Get the user's learning style
      final learningStyle = await _learningService.detectLearningStyle();
      
      // Get block types in the collection
      final blockTypes = blockCollection.blockTypes.map((t) => t.toString().split('.').last).join(', ');
      
      // Build a prompt for Gemini
      final prompt = '''
      You are Ananse, a wise and helpful mentor in a children's coding app that teaches programming through Kente weaving patterns.
      
      Current situation: $context
      
      User's skill level: ${userProgress.level}
      User's learning style: ${learningStyle.toString().split('.').last}
      Current blocks in workspace: ${blockCollection.blocks.length}
      Block types present: $blockTypes
      
      Generate a short, helpful hint (max 2 sentences) that:
      1. Is appropriate for a child aged ${7 + userProgress.level}
      2. Connects coding concepts to Kente weaving traditions
      3. Provides guidance at hint level $hintLevel (1=subtle, 3=explicit)
      4. Matches the user's learning style
      
      The hint should be encouraging and culturally relevant.
      ''';
      
      // Get response from Gemini
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );
      
      // Extract the text response
      String hintText = '';
      try {
        if (response != null) {
          hintText = response.text ?? '';
        }
      } catch (e) {
        debugPrint('Error extracting text from Gemini response: $e');
      }
      
      // Clean up the response (remove quotes, etc.)
      hintText = hintText.replaceAll('"', '').replaceAll('\'', '').trim();
      
      // If we got a valid response, return it
      if (hintText.isNotEmpty) {
        return hintText;
      }
      
      // Fallback if response is empty
      return _getFallbackHint(context, hintLevel);
    } catch (e) {
      debugPrint('Error generating AI hint: $e');
      return _getFallbackHint(context, hintLevel);
    }
  }
  
  /// Generate a culturally relevant hint
  Future<String> _generateCulturalHint(
    BlockCollection blockCollection,
    UserProgress userProgress,
    String baseHint,
  ) async {
    // If Gemini is not initialized, return the base hint
    if (!_isGeminiInitialized) {
      return baseHint;
    }
    
    try {
      // Get cultural information for the blocks
      List<String> culturalElements = [];
      for (final block in blockCollection.blocks) {
        final culturalContext = await _culturalDataService.getBlockCultureContext(block);
        if (culturalContext != null) {
          final significance = culturalContext['culturalSignificance'] ?? 
                             culturalContext['culturalMeaning'];
          if (significance != null) {
            culturalElements.add(significance.toString());
          }
        }
      }
      
      // Build a prompt for Gemini
      final prompt = '''
      You are Ananse, a wise storyteller who teaches children about Kente weaving and coding.
      
      Base hint: $baseHint
      
      Cultural elements in the user's pattern:
      ${culturalElements.join('\n')}
      
      Enhance the base hint by:
      1. Incorporating cultural context about Kente weaving
      2. Making connections between coding concepts and traditional patterns
      3. Keeping it concise (1-2 sentences) and appropriate for a child aged ${7 + userProgress.level}
      
      The hint should be culturally authentic and educational.
      ''';
      
      // Get response from Gemini
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );
      
      // Extract the text response
      String enhancedHint = '';
      try {
        if (response != null) {
          enhancedHint = response.text ?? '';
        }
      } catch (e) {
        debugPrint('Error extracting text from Gemini response: $e');
      }
      
      // Clean up the response
      enhancedHint = enhancedHint.replaceAll('"', '').replaceAll('\'', '').trim();
      
      // If we got a valid response, return it
      if (enhancedHint.isNotEmpty) {
        return enhancedHint;
      }
      
      // Fallback to the base hint
      return baseHint;
    } catch (e) {
      debugPrint('Error generating cultural hint: $e');
      return baseHint;
    }
  }
  
  /// Get a fallback hint when AI generation fails
  String _getFallbackHint(String context, int hintLevel) {
    // Extract key terms from the context
    final lowerContext = context.toLowerCase();
    
    if (lowerContext.contains('struggling')) {
      return "Try connecting similar blocks together, just like how Kente weavers connect similar threads to create patterns.";
    } else if (lowerContext.contains('missing')) {
      return "Your pattern needs another type of block to be complete, like how Kente cloth needs different elements to tell its story.";
    } else if (lowerContext.contains('advanced')) {
      return "Consider how your pattern tells a story through its connections, just as traditional Kente patterns convey meaning through their structure.";
    } else if (lowerContext.contains('hasn\'t made progress')) {
      return "Start by placing a pattern block and connecting it to a color block, like how Kente weavers begin with a base pattern and add colors.";
    } else {
      // Generic fallback hints by level
      switch (hintLevel) {
        case 1:
          return "Think about how your blocks connect to form patterns, similar to threads in Kente cloth.";
        case 2:
          return "Try adding a loop block to repeat your pattern, just like repetition in traditional Kente designs.";
        case 3:
          return "Connect your pattern blocks to color blocks, then add a loop to create a repeating sequence.";
        default:
          return "Experiment with different block combinations to create your own unique pattern.";
      }
    }
  }
  
  /// Generate contextual hint based on skill level
  Future<String> generateContextualHint({
    required String userId,
    required String storyContext,
    required String codingConcept,
    required int hintLevel,
    String? learningStyle,
  }) async {
    // Ensure Gemini is initialized
    if (!_isGeminiInitialized) {
      await initialize();
    }
    
    // Get user progress
    final progress = await _learningService.getUserProgress(userId);
    if (progress == null) {
      return _getFallbackHint("new user, concept: $codingConcept", hintLevel);
    }
    
    // Determine learning style if not provided
    final style = learningStyle ?? 
                 (await _learningService.detectLearningStyle()).toString().split('.').last;
    
    try {
      // Build a prompt for Gemini
      final prompt = '''
      You are Ananse, a wise mentor in a children's coding app that teaches programming through Kente weaving patterns.
      
      Story context: $storyContext
      
      Coding concept to teach: $codingConcept
      Hint level: $hintLevel (1=subtle, 3=explicit)
      User's learning style: $style
      User's skill level: ${progress.level}
      
      Generate a contextual hint that:
      1. Is appropriate for a child aged ${7 + progress.level}
      2. Connects the coding concept to Kente weaving traditions
      3. Provides guidance at the specified hint level
      4. Matches the user's learning style
      5. Is concise (1-2 sentences)
      
      The hint should be encouraging and culturally relevant.
      ''';
      
      // Get response from Gemini
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );
      
      // Extract the text response
      String hintText = '';
      try {
        if (response != null) {
          hintText = response.text ?? '';
        }
      } catch (e) {
        debugPrint('Error extracting text from Gemini response: $e');
      }
      
      // Clean up the response
      hintText = hintText.replaceAll('"', '').replaceAll('\'', '').trim();
      
      // If we got a valid response, return it
      if (hintText.isNotEmpty) {
        return hintText;
      }
      
      // Fallback if response is empty
      return _getFallbackHint("concept: $codingConcept", hintLevel);
    } catch (e) {
      debugPrint('Error generating contextual hint: $e');
      return _getFallbackHint("concept: $codingConcept", hintLevel);
    }
  }
  
  /// Analyze a user's solution
  Future<Map<String, dynamic>> analyzeSolution({
    required String userId,
    required BlockCollection solution,
    required String expectedConcept,
    required String storyContext,
  }) async {
    // Ensure Gemini is initialized
    if (!_isGeminiInitialized) {
      await initialize();
    }
    
    // Get user progress
    final progress = await _learningService.getUserProgress(userId);
    
    // Default analysis result
    final result = {
      'success': validatePatternForChallenge(solution),
      'feedback': 'Your solution works!',
      'conceptMastery': 0.5,
      'suggestions': <String>[],
    };
    
    try {
      // Build a description of the solution
      final blockTypes = solution.blockTypes
          .map((t) => t.toString().split('.').last)
          .toList();
      
      final connectionCount = solution.countConnections();
      final hasLoops = solution.hasLoopStructure();
      
      // Build a prompt for Gemini
      final prompt = '''
      You are an educational AI analyzing a child's coding solution in an app that teaches programming through Kente weaving patterns.
      
      Story context: $storyContext
      Expected coding concept: $expectedConcept
      
      Solution details:
      - Block count: ${solution.blocks.length}
      - Block types used: ${blockTypes.join(', ')}
      - Connection count: $connectionCount
      - Contains loops: $hasLoops
      - Pattern difficulty: ${solution.difficulty.toString().split('.').last}
      
      Analyze this solution and provide:
      1. Whether it successfully demonstrates the expected concept (true/false)
      2. Brief, encouraging feedback (1 sentence)
      3. Concept mastery level (0.0-1.0)
      4. One specific suggestion for improvement
      
      Format your response as JSON:
      {
        "success": true/false,
        "feedback": "Your feedback here",
        "conceptMastery": 0.7,
        "suggestions": ["Your suggestion here"]
      }
      ''';
      
      // Get response from Gemini
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(prompt)],
      );
      
      // Extract the text response
      String analysisText = '';
      try {
        if (response != null) {
          analysisText = response.text ?? '';
        }
      } catch (e) {
        debugPrint('Error extracting text from Gemini response: $e');
      }
      
      // Try to parse JSON response
      if (analysisText.isNotEmpty) {
        // Extract JSON if wrapped in code blocks
        final jsonRegex = RegExp(r'```(?:json)?\s*({[\s\S]*?})\s*```');
        final jsonMatch = jsonRegex.firstMatch(analysisText);
        
        String jsonStr;
        if (jsonMatch != null && jsonMatch.group(1) != null) {
          jsonStr = jsonMatch.group(1)!;
        } else {
          // Try to extract just a JSON object
          final objectRegex = RegExp(r'({[\s\S]*})');
          final objectMatch = objectRegex.firstMatch(analysisText);
          if (objectMatch != null && objectMatch.group(1) != null) {
            jsonStr = objectMatch.group(1)!;
          } else {
            jsonStr = analysisText;
          }
        }
        
        try {
          final analysisResult = json.decode(jsonStr);
          
          // Update result with AI analysis
          if (analysisResult['success'] != null) {
            result['success'] = analysisResult['success'];
          }
          
          if (analysisResult['feedback'] != null) {
            result['feedback'] = analysisResult['feedback'];
          }
          
          if (analysisResult['conceptMastery'] != null) {
            result['conceptMastery'] = analysisResult['conceptMastery'];
          }
          
          if (analysisResult['suggestions'] != null && 
              analysisResult['suggestions'] is List) {
            result['suggestions'] = analysisResult['suggestions'];
          }
        } catch (e) {
          debugPrint('Error parsing analysis JSON: $e');
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error analyzing solution: $e');
      return result;
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
        earned = types.every((type) {
          // For now, just check if the pattern contains any block of this type
          // This is a simplification - in a real implementation, we would need to
          // properly convert the type string to a BlockType enum
          return pattern.blocks.any((block) => 
            block.type.toString().toLowerCase().contains(type.toString().toLowerCase()) ||
            block.subtype.toLowerCase().contains(type.toString().toLowerCase())
          );
        });
      }
      
      // Other custom achievement checks can be added here
      
      if (earned) {
        earnedAchievements.add(achievement);
      }
    }
    
    return earnedAchievements;
  }
}
