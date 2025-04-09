# AI Storytelling System Technical Reference

## Component Architecture

The AI storytelling system consists of the following components:

```
┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │
│  GeminiStoryService │────▶│  Gemini AI API      │
│                     │     │                     │
└─────────┬───────────┘     └─────────────────────┘
          │
          │ uses
          ▼
┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │
│ PromptTemplateManager│◀───▶│  ContentValidator   │
│                     │     │                     │
└─────────┬───────────┘     └─────────────────────┘
          │
          │ uses
          ▼
┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │
│  StoryCacheService  │────▶│  StorageService     │
│                     │     │                     │
└─────────────────────┘     └─────────────────────┘
```

## Component Details

### GeminiStoryService

**Purpose**: Main service for generating AI-driven stories, story branches, and continuations.

**Key Methods**:
- `generateStory`: Generates a story based on user progress and learning concepts
- `generateEnhancedStory`: Generates an enhanced story with continuity and cultural context
- `generateStoryBranches`: Generates story branches based on a parent story and user choices
- `continueStoryFromBranch`: Continues a story based on a selected branch
- `checkConnectivity`: Checks if the device is online
- `setOfflineMode`: Sets the service to offline mode (for testing)

**Dependencies**:
- `Gemini`: Google's Gemini AI API
- `StorageService`: For persistent storage
- `EnhancedCulturalDataService`: For cultural context integration
- `StoryCacheService`: For caching stories

### PromptTemplateManager

**Purpose**: Manages templates for different types of AI prompts.

**Key Methods**:
- `createStoryPrompt`: Creates a prompt for generating a basic story
- `createEnhancedStoryPrompt`: Creates a prompt for generating an enhanced story with more personalization
- `createBranchPrompt`: Creates a prompt for generating story branches
- `createContinuationPrompt`: Creates a prompt for continuing a story from a branch
- `createChallengePrompt`: Creates a prompt for generating a challenge based on a story

**Helper Methods**:
- `_getSkillLevelText`: Converts a skill level number to text
- `_formatPreviousStories`: Formats previous stories for inclusion in prompts

### ContentValidator

**Purpose**: Validates AI-generated content to ensure quality and educational value.

**Key Methods**:
- `validateStoryResponse`: Validates a story response from the AI
- `validateBranchesResponse`: Validates story branches response from the AI
- `validateContinuationResponse`: Validates a story continuation response from the AI
- `validateChallengeResponse`: Validates a challenge response from the AI
- `validateStoryModel`: Checks if a story model is valid
- `validateStoryBranchModel`: Checks if a story branch model is valid

**Helper Methods**:
- `_extractJsonFromText`: Extracts JSON from text that might contain markdown or other formatting
- `_checkConceptsCoverage`: Checks if the content covers the required learning concepts
- `_getConceptRelatedTerms`: Gets terms related to a learning concept

### StoryCacheService

**Purpose**: Provides caching for AI-generated stories using a FIFO strategy.

**Key Methods**:
- `cacheStory`: Caches a story in memory and persistent storage
- `getCachedStory`: Gets a cached story if available
- `cacheBranches`: Caches story branches in memory and persistent storage
- `getCachedBranches`: Gets cached branches if available
- `clearCache`: Clears all cached stories and branches
- `clearOldCachedStories`: Clears old cached stories (older than the specified age)

**Helper Methods**:
- `_trimStoryCache`: Trims the story cache if it exceeds the maximum size
- `_trimBranchCache`: Trims the branch cache if it exceeds the maximum size

## Data Models

### StoryModel

**Purpose**: Represents a complete story.

**Key Properties**:
- `id`: Unique identifier for the story
- `title`: Story title
- `theme`: Story theme (e.g., 'loops', 'conditionals', 'cultural')
- `region`: Cultural region (e.g., 'Ashanti', 'Ghana')
- `characterName`: Main character name
- `content`: List of ContentBlockModel objects
- `learningConcepts`: List of learning concepts covered in the story
- `emotionalTone`: Emotional tone of the story
- `culturalNotes`: Map of cultural notes
- `challenge`: Optional StoryChallenge

### ContentBlockModel

**Purpose**: Represents a block of content in a story.

**Key Properties**:
- `id`: Unique identifier for the content block
- `text`: Text content
- `type`: Type of content block (e.g., 'text', 'image', 'code')
- `metadata`: Additional metadata for the content block

### StoryBranchModel

**Purpose**: Represents a branch in a story.

**Key Properties**:
- `id`: Unique identifier for the branch
- `description`: Description of the branch
- `targetStoryId`: ID of the target story
- `parentStoryId`: ID of the parent story
- `choiceText`: Text describing the choice
- `content`: Content that continues the story based on this choice
- `learningConcepts`: List of learning concepts covered in the branch
- `emotionalTone`: Emotional tone of the branch
- `focusConcept`: Main concept this branch focuses on

### StoryChallenge

**Purpose**: Represents a coding challenge embedded in a story.

**Key Properties**:
- `id`: Unique identifier for the challenge
- `title`: Challenge title
- `description`: Challenge description
- `successCriteria`: Criteria for completing the challenge
- `difficulty`: Difficulty level (1-5)
- `availableBlockTypes`: List of block types available for the challenge
- `contentStartIndex`: Index of the content block where the challenge starts
- `contentEndIndex`: Index of the content block where the challenge ends

## Usage Examples

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

## Error Handling

The system includes comprehensive error handling:

1. **API Call Failures**: If the Gemini API call fails, the system falls back to default stories.

2. **JSON Parsing Errors**: If the response cannot be parsed as JSON, the system creates a simple story from the text.

3. **Validation Failures**: If the content validation fails, the system logs the errors and falls back to simpler content.

4. **Connectivity Issues**: If the device is offline, the system uses cached stories or default stories.

5. **Storage Errors**: If there are errors with storage operations, the system logs the errors and continues with in-memory operations.

## Testing

The system includes unit tests for:

- GeminiStoryService
- ContentValidator
- StoryCacheService
- PromptTemplateManager

The tests cover various scenarios including:

- Cached content retrieval
- Offline mode
- Validation failures
- Error handling

## Performance Considerations

1. **Memory Usage**: The FIFO caching strategy ensures efficient memory usage by limiting the number of stories and branches kept in memory.

2. **Network Usage**: The system minimizes network usage by caching stories and using cached content when appropriate.

3. **Battery Usage**: The system minimizes battery usage by avoiding unnecessary API calls and using efficient caching.

4. **Storage Usage**: The system manages storage usage by implementing cache expiration and size limits.

## Security Considerations

1. **API Key Protection**: The Gemini API key is stored securely using environment variables.

2. **Content Filtering**: The ContentValidator ensures that generated content is appropriate and safe.

3. **Data Privacy**: The system does not collect or store personal information beyond what is necessary for story generation.

## Conclusion

The AI storytelling system provides a robust, efficient, and educationally effective way to generate engaging, culturally rich stories that teach coding concepts through the lens of Kente weaving. The system is designed to be maintainable, extensible, and performant, with comprehensive error handling and testing.
