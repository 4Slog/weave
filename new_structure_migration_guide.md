# Kente Codeweaver Project Restructuring Guide

## Overview

This document provides guidance on migrating the Kente Codeweaver project from its current structure to a more maintainable feature-based architecture. The new structure organizes code by feature rather than by type, making it easier to understand the relationships between components and maintain the codebase.

## Current Structure vs. New Structure

### Current Structure

```
lib/
├── models/
├── providers/
├── services/
├── widgets/
└── screens/
```

The current structure organizes files by their type (models, providers, services, etc.), which makes it difficult to understand the relationships between related components. For example, files related to the block workspace feature are scattered across different directories.

### New Structure

```
lib/
├── core/                       # Core application components
│   ├── navigation/             # App routing
│   ├── theme/                  # App theming
│   ├── utils/                  # Utility functions
│   └── widgets/                # Shared widgets used across features
│
├── features/                   # Main feature modules
│   ├── block_workspace/        # Block workspace feature
│   │   ├── models/             # Block-related models
│   │   ├── providers/          # Block state management
│   │   ├── services/           # Block-related services
│   │   ├── widgets/            # Block-specific widgets
│   │   ├── screens/            # Block workspace screens
│   │   └── painters/           # Custom painters for blocks
│   │
│   ├── storytelling/           # Storytelling feature
│   │   ├── models/             # Story-related models
│   │   ├── providers/          # Story state management
│   │   ├── services/           # Story-related services
│   │   │   ├── ai/             # AI integration services
│   │   │   └── memory/         # Story memory/persistence
│   │   ├── widgets/            # Story-specific widgets
│   │   └── screens/            # Story screens
│   │
│   ├── cultural_context/       # Cultural context feature
│   │   ├── models/             # Cultural data models
│   │   ├── services/           # Cultural data services
│   │   └── widgets/            # Cultural context widgets
│   │
│   ├── learning/               # Learning and progression feature
│   │   ├── models/             # Learning models
│   │   ├── providers/          # Learning state management
│   │   └── services/           # Learning services
│   │
│   └── settings/               # Settings feature
│       ├── models/             # Settings models
│       ├── providers/          # Settings state management
│       └── screens/            # Settings screens
│
├── services/                   # Shared services used across features
│   ├── storage/                # Storage services
│   ├── audio/                  # Audio services
│   └── tts/                    # Text-to-speech services
│
└── main.dart                   # Application entry point
```

The new structure organizes files by feature, making it easier to understand the relationships between related components. Each feature has its own directory with subdirectories for models, providers, services, widgets, and screens related to that feature.

## Migration Steps

### 1. Create the New Directory Structure

Use the provided PowerShell script (`migrate_project.ps1`) to create the new directory structure and copy files to their new locations. The script will:

- Create all necessary directories
- Copy files to their new locations
- Create interface files for cross-feature communication

```powershell
# Run the migration script
powershell -ExecutionPolicy Bypass -File migrate_project.ps1
```

### 2. Update Imports

After moving files to their new locations, you'll need to update imports in all files to reflect the new structure. The script attempts to update imports, but you may need to manually fix some imports.

For example, change:

```dart
import 'package:kente_codeweaver/models/block_model.dart';
```

To:

```dart
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
```

### 3. Implement Interfaces for Cross-Feature Communication

To reduce coupling between features, we've created interfaces for cross-feature communication. For example, the `ChallengeInterface` allows the storytelling feature to interact with the block workspace feature without direct dependencies.

#### Example: ChallengeInterface

```dart
abstract class ChallengeInterface {
  Future<void> prepareChallenge(String challengeId, List<BlockType> requiredBlockTypes);
  Future<bool> validateSolution();
  String? getCurrentChallengeId();
}
```

#### Example: StoryChallengeInterface

```dart
abstract class StoryChallengeInterface {
  Future<void> onChallengeCompleted(String storyId, String challengeId, bool success);
  List<BlockType> getRequiredBlockTypes(String storyId);
  int getChallengeDifficulty(String storyId);
}
```

### 4. Use Dependency Injection

We've created a simple service locator for dependency injection. This allows you to register implementations of interfaces and access them from anywhere in the application.

#### Example: Registering Services

```dart
// Initialize the service locator
ServiceLocator.initialize(context);

// Register a service
final challengeService = ChallengeServiceImpl(
  blockProvider: blockProvider,
  challengeService: ChallengeServiceEnhanced(),
);
ServiceLocator().register<ChallengeInterface>(challengeService);
```

#### Example: Using Services

```dart
// Get a service from the service locator
final challengeInterface = context.getService<ChallengeInterface>();

// Use the service
await challengeInterface.prepareChallenge('challenge_123', blockTypes);
```

### 5. Update the Main Application

Update the main application to use the new structure. See `lib/main_with_new_structure.dart` for an example.

## Enhanced vs. Regular Services

The codebase currently has both regular and enhanced versions of many services (e.g., `story_mentor_service.dart` and `story_mentor_service_enhanced.dart`). During the migration, you should analyze both versions and choose the better one based on features, architecture, and maintainability.

In general, the enhanced versions offer more features and better architecture, but you should make this determination on a case-by-case basis.

## Testing the Migration

After completing the migration, you should thoroughly test the application to ensure everything works correctly. Pay special attention to:

1. Navigation between screens
2. Interactions between features
3. State management
4. Error handling

## Benefits of the New Structure

The new structure offers several benefits:

1. **Domain Cohesion**: Related files are grouped together, making it easier to understand how components interact within a feature.

2. **Clear Boundaries**: Each feature has clear boundaries, reducing coupling between unrelated components.

3. **Easier Navigation**: Developers can quickly find all files related to a specific feature without jumping between directories.

4. **Scalability**: New features can be added as separate modules without affecting existing code.

5. **Maintainability**: Changes to one feature are less likely to impact others.

6. **Onboarding**: New developers can understand the application structure more quickly.

## Conclusion

This migration will significantly improve the maintainability and scalability of the Kente Codeweaver application. By grouping related files by feature rather than by type, developers will be able to more easily understand the relationships between components and make changes with confidence.
