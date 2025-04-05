# Import Update Example

This document provides an example of how to update imports in a file to reflect the new feature-based structure. We'll use the `block_workspace.dart` file as an example.

## Original Imports

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/models/connection_types.dart';
import 'package:kente_codeweaver/providers/block_provider_enhanced.dart';
import 'package:kente_codeweaver/providers/learning_provider_enhanced.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service_enhanced.dart';
import 'package:kente_codeweaver/services/challenge_service_enhanced.dart';
import 'package:kente_codeweaver/services/story_mentor_service.dart';
import 'package:kente_codeweaver/painters/connections_painter.dart';
```

## Updated Imports

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/features/block_workspace/services/challenge_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_mentor_service.dart';
import 'package:kente_codeweaver/features/block_workspace/painters/connections_painter.dart';
```

## Key Changes

1. **Path Structure**: All imports now include the feature directory in the path.
2. **File Names**: Some file names have been simplified (e.g., `block_provider_enhanced.dart` to `block_provider.dart`).
3. **Feature Organization**: Files are now organized by feature rather than by type.

## Automated Update Process

You can use search and replace operations to update imports in bulk. Here are some examples:

1. Replace `import 'package:kente_codeweaver/models/block_` with `import 'package:kente_codeweaver/features/block_workspace/models/block_`
2. Replace `import 'package:kente_codeweaver/providers/block_provider_enhanced.dart'` with `import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart'`
3. Replace `import 'package:kente_codeweaver/providers/learning_provider_enhanced.dart'` with `import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart'`

## Manual Update Process

For more complex cases, you may need to manually update imports. Here's a process to follow:

1. Identify the file you're importing
2. Determine which feature it belongs to
3. Update the import path to include the feature directory
4. Update the file name if it has changed

## Class Name Updates

In some cases, class names have also been simplified. For example:

- `BlockProviderEnhanced` is now `BlockProvider`
- `LearningProviderEnhanced` is now `LearningProvider`
- `AdaptiveLearningServiceEnhanced` is now `AdaptiveLearningService`

You'll need to update these class names in your code as well.

## Example Class Name Update

```dart
// Original
final BlockProviderEnhanced blockProvider = Provider.of<BlockProviderEnhanced>(context);

// Updated
final BlockProvider blockProvider = Provider.of<BlockProvider>(context);
```

By following these guidelines, you can update imports and class names to reflect the new feature-based structure.
