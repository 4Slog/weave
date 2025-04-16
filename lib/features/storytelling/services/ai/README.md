# AI-Driven Storytelling System

This directory contains the implementation of the AI-driven storytelling system for Kente Codeweaver. The system uses Google's Gemini AI to generate engaging, culturally rich stories that teach coding concepts through the lens of Kente weaving.

## Components

### GeminiStoryService

The main service responsible for generating AI-driven stories, story branches, and continuations. It includes:

- Enhanced prompt engineering for more engaging narratives
- Support for generating story branches based on user choices
- Better error handling for offline scenarios
- Caching mechanisms for generated content
- Content validation for quality control
- FIFO caching for efficient memory usage

### PromptTemplateManager

Manages templates for different types of AI prompts, ensuring consistent and high-quality prompts for story generation. It provides templates for:

- Basic stories
- Enhanced stories with more personalization
- Story branches
- Story continuations
- Challenges

### ContentValidator

Validates AI-generated content to ensure it meets quality standards and educational requirements. It checks:

- Required fields are present
- Content length is appropriate
- Learning concepts are covered
- JSON structure is valid

### StoryCacheService

Provides caching for AI-generated stories using a FIFO (First-In-First-Out) strategy. It includes:

- Memory caching for quick access
- Persistent storage for offline use
- Cache size management
- Cache expiration

## Usage

### Generating a Story

```dart
final storyService = GeminiStoryService();
await storyService.initialize();

final story = await storyService.generateStory(
  userProgress: userProgress,
  learningConcepts: ['loops', 'conditionals'],
  emotionalTone: EmotionalTone.excited,
);
```

### Generating an Enhanced Story

```dart
final enhancedStory = await storyService.generateEnhancedStory(
  skillLevel: SkillLevel.beginner,
  theme: 'cultural',
  characterName: 'Kofi',
  narrativeContext: {'previousAdventure': 'Kofi learned about loops'},
  userProgress: userProgress,
);
```

### Generating Story Branches

```dart
final branches = await storyService.generateStoryBranches(
  parentStory: story,
  userProgress: userProgress,
  choiceCount: 3,
);
```

### Continuing a Story from a Branch

```dart
final continuation = await storyService.continueStoryFromBranch(
  selectedBranch: selectedBranch,
  userProgress: userProgress,
);
```

## Offline Support

The system includes robust offline support:

- Cached stories are used when offline
- Default stories are provided as fallbacks
- Stories are cached for future offline use

## Testing

Unit tests are available in the `test/features/storytelling/services/ai` directory.

## Future Enhancements

- Multi-language support
- More sophisticated content validation
- Enhanced cultural context integration
- Better personalization based on user preferences
