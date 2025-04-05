# Critical Errors Fix Plan

## 1. Fix Core Infrastructure

### Step 1: Create Missing Core Services
- Create the missing `StorageService` in the core services directory
- Ensure it has all the methods referenced throughout the codebase

```dart
// lib/core/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';

class StorageService {
  // Implementation of storage methods
  // ...
}
```

### Step 2: Fix the App Router
- Update the app router to use the new screen paths
- Remove references to screens that no longer exist
- Update route generation logic

```dart
// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/welcome/screens/welcome_screen.dart';
import 'package:kente_codeweaver/features/home/screens/home_screen.dart';
import 'package:kente_codeweaver/features/block_workspace/screens/block_workspace_screen.dart';
import 'package:kente_codeweaver/features/settings/screens/settings_screen.dart';
import 'package:kente_codeweaver/features/storytelling/screens/story_screen.dart';

class AppRouter {
  // Updated route constants
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String blockWorkspace = '/block-workspace';
  static const String settings = '/settings';
  static const String story = '/story';
  
  // Updated route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case blockWorkspace:
        return MaterialPageRoute(builder: (_) => const BlockWorkspaceScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case story:
        return MaterialPageRoute(builder: (_) => const StoryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
```

## 2. Fix Model Classes

### Step 1: Create Missing Pattern Model
- Create the missing `PatternModel` class in the patterns feature

```dart
// lib/features/patterns/models/pattern_model.dart
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';

class PatternModel {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final String userId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final BlockCollection blockCollection;
  
  PatternModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.blockCollection,
  });
  
  // Factory methods, toJson, fromJson, etc.
}
```

### Step 2: Fix Story Models
- Update the `StoryBranchModel` to include missing properties
- Fix the `StoryModel` class to include all required properties

```dart
// lib/features/storytelling/models/story_branch_model.dart
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';

class StoryBranchModel {
  final String id;
  final String content;
  final List<String> learningConcepts;
  final EmotionalTone emotionalTone;
  // Add other required properties
  
  StoryBranchModel({
    required this.id,
    required this.content,
    required this.learningConcepts,
    required this.emotionalTone,
  });
}
```

## 3. Fix Provider Implementations

### Step 1: Create Provider Implementations
- Implement the missing provider classes
- Ensure they match the expected interfaces

```dart
// lib/features/block_workspace/providers/block_provider.dart
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';

class BlockProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  // Implementation
}
```

```dart
// lib/features/learning/providers/learning_provider.dart
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';

class LearningProvider extends ChangeNotifier {
  // Implementation
}
```

## 4. Fix Service Implementations

### Step 1: Create Missing Services
- Implement the missing service classes
- Ensure they match the expected interfaces

```dart
// lib/features/learning/services/adaptive_learning_service.dart
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';

class AdaptiveLearningService {
  final StorageService _storageService;
  
  AdaptiveLearningService(this._storageService);
  
  // Implementation
}
```

## 5. Fix Syntax Errors

### Step 1: Fix Pattern Painter Syntax Error
- Fix the syntax error in pattern_painter.dart line 1052

### Step 2: Fix Missing Required Arguments
- Add required arguments to method calls in gemini_story_service.dart

## Implementation Strategy

1. **Prioritize Core Infrastructure**: Fix the core services and navigation first
2. **Fix Model Classes**: Ensure all model classes are properly defined
3. **Implement Providers**: Create the missing provider implementations
4. **Fix Services**: Implement the missing service classes
5. **Fix Syntax Errors**: Address specific syntax errors
6. **Test Incrementally**: Test each component after fixing it

This approach will systematically address the critical errors while maintaining the new feature-based architecture.
