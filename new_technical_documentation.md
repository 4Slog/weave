# Kente Codeweaver Technical Documentation

## 1. Project Overview

### Application Purpose and Educational Goals
Kente Codeweaver is an AI-powered educational application targeted at children aged 7-15. The application's primary goal is to teach coding through culturally immersive storytelling inspired by traditional Ghanaian Kente weaving. By combining visual programming with cultural context, the application aims to make coding accessible, engaging, and meaningful.

The key educational goals include:
- Teaching fundamental coding concepts (loops, conditionals, functions, variables, debugging)
- Incorporating African cultural heritage through interactive Kente weaving pattern generation
- Utilizing AI for adaptive learning experiences and dynamic storytelling
- Supporting multilingual learning environments
- Providing limited offline functionality relying on cached content

### Target Audience
- **Primary**: Children aged 7-15, particularly in Africa and the global diaspora
- **Secondary**: Educators and parents seeking culturally relevant coding curriculum
- **Tertiary**: School programs and coding boot camps

### Key Features and Capabilities
- **AI-Generated Storytelling**: Personalized, culturally relevant narratives with branching storylines
- **Block-Based Coding Workspace**: Interactive visual programming environment
- **Adaptive Learning**: Personalized learning paths based on user performance
- **Cultural Context Integration**: Educational content about Kente weaving traditions
- **Offline Functionality**: Caching mechanisms for limited offline access
- **Achievement System**: Badges and milestones to track progress

## 2. Architecture

### Technical Stack Overview
- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **AI Integration**: Google Gemini AI (flutter_gemini)
- **Local Storage**: Hive & SQLite
- **Multimedia**: Flutter TTS, audio, and visual assets
- **Future Integration**: Firebase for user authentication and cloud progress tracking

### Component Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                           │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │  Story Screen │  │ Block Workspace│  │ Achievement Screen│   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                        State Management                         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ Story Provider│  │ Block Provider│  │ Learning Provider │   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                           Services                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ Gemini Story  │  │Adaptive Learning│ │ Cultural Data     │   │
│  │   Service     │  │    Service     │ │    Service        │   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │ Storage Service│  │  TTS Service  │  │  Audio Service    │   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                           Models                                │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │  Block Model  │  │  Story Model  │  │ User Progress Model│   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                        External Services                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │
│  │  Google Gemini│  │  Local Storage│  │  Flutter TTS      │   │
│  └───────────────┘  └───────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **User Interaction**: User interacts with the UI (Story Screen, Block Workspace)
2. **State Management**: Providers manage state and trigger service calls
3. **Service Layer**: Services process requests, interact with external APIs, and update models
4. **Model Layer**: Models represent the data structures and business logic
5. **External Services**: Google Gemini AI, local storage, and other external services
6. **Response Flow**: Results flow back up through the layers to update the UI

## 3. Core Components

### 3.1 AI-Driven Storytelling

#### Story Generation Architecture
The AI-driven storytelling system uses a modular architecture with the following components:

1. **Core Components**:
   - `StoryServiceBase`: Abstract base class defining the interface for story services
   - `StoryServiceConfig`: Configuration options for the story service
   - `StoryServiceTypes`: Type definitions for the story service

2. **Parsing Components**:
   - `PromptBuilder`: Constructs prompts for the AI service
   - `StoryResponseParser`: Parses and validates AI responses

3. **Caching Components**:
   - `StoryCacheManager`: Manages caching and retrieval of stories

4. **Connectivity Components**:
   - `ConnectivityManager`: Handles checking and monitoring network connectivity

5. **Enhanced Gemini Integration**:
   - `EnhancedGeminiStoryService`: Improved implementation of the Gemini AI service

#### Branching Narrative System
The branching narrative system allows for:
- Generating story branches based on user choices
- Implementing story state management for continuity
- Enhancing story generation to create coherent branches
- Providing methods for selecting and navigating between branches

#### Offline Capabilities
Offline functionality is implemented through:
- Sophisticated caching mechanisms for generated content
- Fallback mechanisms for offline scenarios
- A cache manager to handle story storage and retrieval
- Connectivity monitoring to adapt to network changes

#### Cultural Context Integration
Cultural context is integrated through:
- Cultural data service providing information about Kente patterns, colors, and symbols
- Integration of cultural context in story prompts
- Cultural context cards in the UI
- Educational content about Kente weaving traditions

### 3.2 Block Workspace

#### Block Types and Connections
The block workspace supports various block types:
- **Pattern Blocks**: Represent visual patterns in Kente weaving
- **Color Blocks**: Represent thread colors with cultural meanings
- **Structure Blocks**: Organize patterns (rows, columns)
- **Loop Blocks**: Repeat patterns multiple times
- **Conditional Blocks**: Create patterns that change based on conditions
- **Function Blocks**: Define reusable pattern components

Blocks can be connected through connection points, with rules defining valid connections.

#### Pattern Validation
The system validates patterns based on:
- Connection validity between blocks
- Required block types for specific challenges
- Minimum and maximum number of blocks
- Pattern structure requirements

#### Challenge Integration
Challenges are integrated with the block workspace through:
- Challenge requirements defining success criteria
- Validation of user solutions against requirements
- Feedback on solution correctness
- Adaptive difficulty based on user performance

#### User Interaction Model
The user interaction model includes:
- Drag and drop functionality for block placement
- Connection creation through proximity detection
- Block property editing through UI controls
- Real-time feedback on pattern validity

### 3.3 Adaptive Learning

#### Skill Tracking System
The skill tracking system monitors:
- Concept mastery through challenge completion
- Skill proficiency levels (novice, beginner, intermediate, advanced)
- Learning rate and engagement metrics
- Strengths and areas for improvement

#### Personalized Learning Paths
The system creates personalized learning paths by:
- Recommending next concepts based on current progress
- Adjusting difficulty based on demonstrated abilities
- Providing personalized hints and feedback
- Adapting to different learning styles

#### Milestone and Achievement System
The milestone system includes:
- Predefined milestones for key accomplishments
- Badges awarded for concept mastery and challenge completion
- XP and level progression
- Visual representation of achievements

#### Analytics and Progress Visualization
Learning analytics include:
- Skill progress visualization
- Concept mastery tracking
- Learning rate calculation
- Engagement score metrics

### 3.4 Cultural Context Integration

#### Cultural Data Sources
Cultural data is sourced from:
- JSON files containing information about Kente patterns, colors, symbols, and regions
- Cultural context cards with educational content
- Integration with storytelling elements

#### Integration Points in UI
Cultural context is integrated in the UI through:
- Cultural context cards in the story screen
- Pattern and color descriptions in the block workspace
- Cultural significance explanations in challenge feedback
- Regional information in storytelling

#### Educational Content Delivery
Educational content is delivered through:
- Story narratives incorporating cultural elements
- Challenge descriptions with cultural context
- Badge descriptions with cultural significance
- Hint system with cultural references

## 4. Data Models

### Key Model Classes and Relationships

#### Block Model
- `BlockModel`: Represents a block in the visual programming environment
- `BlockConnection`: Represents a connection point on a block
- `BlockType`: Enum defining the types of blocks available
- `BlockCollection`: Collection of blocks forming a pattern

#### Story Model
- `StoryModel`: Represents a story in the application
- `StoryBranchModel`: Represents a branch option in a story
- `ContentBlock`: Represents a content block in a story
- `StoryChallenge`: Represents a challenge associated with a story

#### User Progress Model
- `UserProgress`: Tracks user progress, skills, and achievements
- `SkillLevel`: Enum defining skill proficiency levels
- `SkillType`: Enum defining types of skills tracked
- `BadgeModel`: Represents an achievement badge

#### Other Models
- `PatternDifficulty`: Defines difficulty levels for patterns
- `EmotionalTone`: Defines emotional tones for storytelling
- `TTSSettings`: Defines text-to-speech settings

### JSON Data Structures
The application uses several JSON files for data storage:
- `blocks.json`: Defines block types, properties, and cultural significance
- `challenges.json`: Contains coding challenges with validation criteria
- `stories.json`: Stores interactive stories with branching narratives
- `colors_cultural_info.json`: Cultural meanings of Kente colors
- `patterns_cultural_info.json`: Cultural meanings of Kente patterns
- `symbols_cultural_info.json`: Cultural meanings of Adinkra symbols
- `regional_info.json`: Information about Ghanaian regions and weaving traditions

### Storage and Caching Strategy
The application uses a multi-layered storage and caching strategy:
- **Hive**: For persistent local storage of user progress
- **In-memory Cache**: For frequently accessed data
- **SQLite**: For structured data storage
- **Asset Bundling**: For static content like images and audio
- **Caching Mechanisms**: For AI-generated content to support offline use

## 5. Implementation Status

### Completed Features
1. **AI-Driven Storytelling**
   - Enhanced AI prompt engineering for engaging narratives
   - Support for branching narratives based on user choices
   - Caching mechanisms for offline functionality
   - Cultural context integration in storytelling

2. **Adaptive Learning**
   - AI-driven difficulty progression instead of age-based metrics
   - Personalized learning paths based on user progress
   - Milestone tracking with rewards
   - Enhanced learning analytics

3. **Cultural Context Integration**
   - Support for different types of cultural data
   - Integration with storytelling and learning
   - Enhanced cultural context cards

4. **Code Architecture**
   - Modular design with clear separation of concerns
   - Organized directory structure
   - Refactored large files into smaller components

### In-Progress Features
1. **Block Workspace Enhancements**
   - Improved block connection validation
   - Better feedback for users
   - Enhanced integration with adaptive learning

2. **Story Generation Improvements**
   - Enhanced prompt engineering
   - Better error handling
   - Improved offline fallbacks

3. **User Interface Refinements**
   - More intuitive navigation
   - Better visual feedback
   - Accessibility improvements

### Planned Features
1. **Multiplayer and Collaboration**
   - Shared workspaces
   - Collaborative challenges
   - Peer feedback

2. **Advanced Analytics**
   - Detailed learning metrics
   - Progress visualization
   - Personalized recommendations

3. **Expanded Cultural Content**
   - More regions and traditions
   - Interactive cultural explorations
   - Historical context

### Known Issues and Limitations
1. **Critical Syntax Errors**
   - Missing commas in array definitions in learning_provider_enhanced.dart
   - Missing commas in generic type declarations in cultural_data_service_enhanced.dart
   - Missing commas in RegExp constructor in gemini_story_service.dart
   - Missing comma in constructor initialization list in gemini_story_service.dart

2. **Performance Issues**
   - Slow loading of complex patterns
   - Memory usage with large story caches
   - Battery consumption during extended use

3. **Offline Limitations**
   - Limited functionality without connectivity
   - Cached content only
   - No new story generation offline

## 6. Development Roadmap

### Short-Term Priorities (Next 2-4 Weeks)
1. **Fix Critical Syntax Errors**
   - Address all identified syntax issues
   - Ensure application compiles correctly
   - Run comprehensive tests

2. **Enhance AI-Driven Storytelling**
   - Complete the modular story service implementation
   - Implement the story memory service
   - Enhance the branching narrative system

3. **Refine Block Workspace**
   - Improve connection validation
   - Implement real-time pattern preview
   - Add contextual hints

4. **Strengthen Adaptive Learning**
   - Complete skill assessment algorithms
   - Implement milestone tracking
   - Develop the recommendation engine

### Medium-Term Goals (1-3 Months)
1. **Optimize Performance**
   - Implement asset preloading
   - Optimize pattern rendering
   - Improve memory management

2. **Enhance User Experience**
   - Refine UI components
   - Add animations and transitions
   - Improve accessibility

3. **Expand Content**
   - Add more challenges
   - Create more story templates
   - Expand cultural context

4. **Implement Analytics**
   - Track user engagement
   - Measure learning outcomes
   - Gather feedback for improvements

### Long-Term Vision (3+ Months)
1. **Cloud Integration**
   - Implement Firebase authentication
   - Add cloud synchronization
   - Enable cross-device progress

2. **Multiplayer Features**
   - Collaborative challenges
   - Peer learning
   - Community sharing

3. **Advanced AI Features**
   - More sophisticated storytelling
   - Personalized learning recommendations
   - Natural language interaction

4. **Platform Expansion**
   - Web version
   - iOS support
   - Desktop applications

## 7. Testing Strategy

### Unit Testing Approach
- Test individual components in isolation
- Mock dependencies for predictable testing
- Verify error handling and edge cases
- Focus on core services and models

### Widget Testing
- Test UI components independently
- Verify user interactions
- Ensure proper rendering
- Test accessibility features

### Integration Testing
- Test component interactions
- Verify end-to-end flows
- Test offline functionality
- Validate data persistence

### Manual Testing Procedures
- User acceptance testing
- Performance testing
- Cross-device testing
- Accessibility verification

## 8. Deployment and Maintenance

### Build Process
- Automated builds using CI/CD
- Version control with Git
- Build tracking with Memory Bank
- Quality assurance checks

### Release Strategy
- Phased rollout
- Beta testing program
- Staged feature releases
- Version numbering scheme

### Monitoring and Analytics
- User engagement tracking
- Error monitoring
- Performance metrics
- Learning outcome measurement

### Update Procedures
- Regular maintenance updates
- Feature releases
- Hotfixes for critical issues
- Content updates
