# AI Story Generation Implementation Plan

## Overview
This document outlines the comprehensive plan for implementing the AI story generation system in Kente Codeweaver, based on the project audit and discussions with the development team. The AI story generation system is a core component of the application, serving as the primary educational delivery mechanism through engaging, culturally relevant narratives.

## Current Implementation Status

The AI story generation system is **partially implemented** with the following components in place:

- ✅ Basic architecture and interfaces defined
- ✅ Story model structures implemented
- ✅ Static story content available in JSON files
- ✅ UI components for story presentation
- ⚠️ Gemini AI integration partially implemented
- ❌ Dynamic story generation not fully functional
- ❌ Branching narrative generation incomplete
- ❌ Response processing and validation incomplete

## Implementation Requirements

Based on our discussions, the following requirements have been established for the AI story generation system:

### Story Structure and Content
- **Story Length**: 8-12 content blocks per story segment
- **Structure**:
  - 2-3 blocks for introduction/context setting
  - 3-5 blocks for concept development through narrative
  - 1-2 blocks for challenge introduction
  - 2-3 blocks for conclusion/reflection
- **Concept Teaching**: Subtle integration of coding concepts without explicit instruction
- **Adaptive Content**: Stories should adapt based on user performance in previous challenges
- **Concept Repetition**: System should track taught concepts and avoid repetition unless introducing higher-level versions

### Technical Implementation
- **API Integration**: Google Gemini AI with existing API key setup
- **Caching Strategy**: First-in-first-out (FIFO) caching on user devices
- **Content Generation**: AI-generated content with predefined guides as fallbacks
- **Content Validation**: Automated filtering, educational validation, cultural sensitivity checks
- **Performance Handling**: Progressive loading, background generation, pre-generation, timeout handling

### Quality Metrics
- **Validation Criteria**:
  - Educational alignment
  - Narrative coherence
  - Age appropriateness
  - Engagement factors
  - Cultural authenticity
  - Language quality
- **Performance Metrics**:
  - Generation success rate
  - Response time
  - User engagement
  - Completion rate
  - Challenge success rate
  - Retention impact
  - Concept mastery correlation

### Cultural Integration
- **Cultural Content**: Should be verifiable from readily available, verified sources
- **Content Generation**: Cultural notes can be AI-generated or rephrased from verified sources

### Future Expansion
- **Multilingual Support**: Planned for future implementation
- **User Contribution**: Basic user customization (character names, theme selection, challenge preferences, narrative choices)

## Implementation Plan

### Phase 1: Core Implementation
1. Complete the GeminiStoryService implementation
2. Implement robust prompt construction
3. Develop response processing system
4. Create basic caching mechanism

### Phase 2: Enhancement
1. Implement branching narrative generation
2. Enhance cultural integration
3. Improve error handling and fallbacks
4. Optimize performance and caching

### Phase 3: Testing and Refinement
1. Conduct comprehensive testing
2. Refine prompts based on results
3. Optimize response processing
4. Implement user feedback system

## Key Components to Implement

### 1. Enhanced Prompt Construction
```dart
String _buildEnhancedPrompt(Map<String, dynamic> params) {
  // Create a detailed prompt for the AI model
  final sb = StringBuffer();
  
  // Add system instructions
  sb.writeln("You are a storyteller for an educational coding app called Kente Codeweaver.");
  sb.writeln("Create an engaging, culturally authentic story that teaches coding concepts through Kente weaving metaphors.");
  
  // Add educational parameters
  sb.writeln("\nEDUCATIONAL PARAMETERS:");
  sb.writeln("- Concepts to teach: ${params['concepts'].join(', ')}");
  sb.writeln("- Difficulty level: ${params['difficulty']}");
  sb.writeln("- Target age group: ${params['ageGroup']}");
  
  // Add cultural context
  sb.writeln("\nCULTURAL CONTEXT:");
  sb.writeln("- Region: ${params['region']}");
  sb.writeln("- Cultural elements: ${params['culturalElements']}");
  
  // Add narrative parameters
  sb.writeln("\nNARRATIVE PARAMETERS:");
  sb.writeln("- Character name: ${params['characterName']}");
  sb.writeln("- Emotional tone: ${params['emotionalTone']}");
  sb.writeln("- Previous story context: ${params['previousContext']}");
  
  // Add output format instructions
  sb.writeln("\nOUTPUT FORMAT:");
  sb.writeln("Return a JSON object with the following structure:");
  sb.writeln("""
  {
    "title": "Story title",
    "theme": "Story theme",
    "region": "Cultural region",
    "characterName": "Main character name",
    "ageGroup": "Target age group",
    "content": [
      {
        "id": "unique_id",
        "text": "Story text",
        "delay": 0,
        "displayDuration": 5000,
        "waitForInteraction": false,
        "emotionalTone": "neutral"
      },
      // More content blocks...
    ],
    "challenge": {
      "id": "challenge_id",
      "title": "Challenge title",
      "description": "Challenge description",
      "successCriteria": {
        "requiresBlockType": ["block_type1", "block_type2"],
        "minConnections": 1
      },
      "difficulty": 1,
      "availableBlockTypes": ["block_type1", "block_type2", "block_type3"],
      "contentStartIndex": 5,
      "contentEndIndex": 7
    },
    "culturalNotes": {
      "note1": "Cultural note 1",
      "note2": "Cultural note 2"
    },
    "learningConcepts": ["concept1", "concept2"]
  }
  """);
  
  return sb.toString();
}
```

### 2. Response Processing
```dart
StoryModel _processAIResponse(String responseText, Map<String, dynamic> params) {
  try {
    // Extract JSON from response
    final jsonStr = GeminiStoryServiceHelper.extractJsonFromText(responseText);
    final storyData = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    // Validate required fields
    _validateStoryData(storyData);
    
    // Create content blocks
    final contentBlocks = _createContentBlocksFromData(storyData['content']);
    
    // Create challenge
    final challenge = storyData['challenge'] != null 
        ? _createChallengeFromData(storyData['challenge'])
        : null;
    
    // Create cultural notes
    final culturalNotes = storyData['culturalNotes'] != null
        ? Map<String, String>.from(storyData['culturalNotes'])
        : <String, String>{};
    
    // Create learning concepts
    final learningConcepts = storyData['learningConcepts'] != null
        ? List<String>.from(storyData['learningConcepts'])
        : params['concepts'] as List<String>;
    
    // Create story model
    return StoryModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      title: storyData['title'] ?? 'Untitled Story',
      theme: storyData['theme'] ?? params['theme'] as String,
      region: storyData['region'] ?? params['region'] as String,
      characterName: storyData['characterName'] ?? params['characterName'] as String,
      ageGroup: storyData['ageGroup'] ?? params['ageGroup'] as String,
      content: contentBlocks,
      challenge: challenge,
      branches: [], // Branches will be generated separately
      culturalNotes: culturalNotes,
      learningConcepts: learningConcepts,
      emotionalTone: _parseEmotionalTone(storyData['emotionalTone']),
      difficultyLevel: storyData['difficultyLevel'] ?? params['difficulty'] as int,
    );
  } catch (e) {
    debugPrint('Error processing AI response: $e');
    return _createFallbackStory(params);
  }
}
```

### 3. Caching System
```dart
class StoryCacheService {
  final StorageService _storageService;
  final Map<String, StoryModel> _memoryCache = {};
  final int _maxCacheSize = 20;
  
  StoryCacheService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();
  
  /// Cache a story in memory and persistent storage
  Future<void> cacheStory(String cacheKey, StoryModel story) async {
    // Add to memory cache
    _memoryCache[cacheKey] = story;
    
    // Trim cache if it exceeds maximum size (FIFO)
    if (_memoryCache.length > _maxCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    
    // Save to persistent storage
    await _storageService.saveProgress(
      'story_cache_$cacheKey',
      jsonEncode(story.toJson()),
    );
  }
  
  /// Get a cached story if available
  Future<StoryModel?> getCachedStory(String cacheKey) async {
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }
    
    // Check persistent storage
    try {
      final cachedData = await _storageService.getProgress('story_cache_$cacheKey');
      if (cachedData != null) {
        final storyData = jsonDecode(cachedData) as Map<String, dynamic>;
        final story = StoryModel.fromJson(storyData);
        
        // Add to memory cache
        _memoryCache[cacheKey] = story;
        
        return story;
      }
    } catch (e) {
      debugPrint('Error retrieving cached story: $e');
    }
    
    return null;
  }
  
  /// Clear old cached stories
  Future<void> clearOldCachedStories() async {
    // Implementation for cleanup mechanism
  }
}
```

## Next Steps

1. Begin implementation of the core components
2. Develop comprehensive test cases for story generation
3. Create a validation system for generated content
4. Implement the caching and memory management system
5. Integrate with the adaptive learning system

## Conclusion

The AI story generation system is a critical component of Kente Codeweaver, serving as the primary educational delivery mechanism. By implementing this system according to the outlined plan, we will create a dynamic, personalized, and culturally authentic storytelling experience that effectively teaches coding concepts while maintaining high engagement levels.

The implementation will focus on creating subtle, engaging narratives that teach coding concepts without explicit instruction, adapting to user performance, and maintaining cultural authenticity. The system will use Google's Gemini AI with appropriate caching and fallback mechanisms to ensure a smooth user experience even in offline scenarios.
