# Create the new directory structure
function Create-DirectoryStructure {
    $dirs = @(
        "lib/core/navigation",
        "lib/core/theme",
        "lib/core/utils",
        "lib/core/widgets",
        "lib/features/block_workspace/models",
        "lib/features/block_workspace/providers",
        "lib/features/block_workspace/services",
        "lib/features/block_workspace/widgets",
        "lib/features/block_workspace/screens",
        "lib/features/block_workspace/painters",
        "lib/features/block_workspace/interfaces",
        "lib/features/storytelling/models",
        "lib/features/storytelling/providers",
        "lib/features/storytelling/services/ai",
        "lib/features/storytelling/services/memory",
        "lib/features/storytelling/widgets",
        "lib/features/storytelling/screens",
        "lib/features/storytelling/interfaces",
        "lib/features/cultural_context/models",
        "lib/features/cultural_context/services",
        "lib/features/cultural_context/widgets",
        "lib/features/learning/models",
        "lib/features/learning/providers",
        "lib/features/learning/services",
        "lib/features/settings/models",
        "lib/features/settings/providers",
        "lib/features/settings/screens",
        "lib/services/storage",
        "lib/services/audio",
        "lib/services/tts"
    )

    foreach ($dir in $dirs) {
        New-Item -Path $dir -ItemType Directory -Force
    }
}

# Move core files
function Move-CoreFiles {
    # Move navigation files
    if (Test-Path "lib/navigation/app_router.dart") {
        Copy-Item -Path "lib/navigation/app_router.dart" -Destination "lib/core/navigation/app_router.dart" -Force
    }
    
    # Move theme files
    if (Test-Path "lib/theme/app_theme.dart") {
        Copy-Item -Path "lib/theme/app_theme.dart" -Destination "lib/core/theme/app_theme.dart" -Force
    }
}

# Move block workspace files
function Move-BlockWorkspaceFiles {
    # Move models
    if (Test-Path "lib/models/block_model.dart") {
        Copy-Item -Path "lib/models/block_model.dart" -Destination "lib/features/block_workspace/models/block_model.dart" -Force
    }
    if (Test-Path "lib/models/block_type.dart") {
        Copy-Item -Path "lib/models/block_type.dart" -Destination "lib/features/block_workspace/models/block_type.dart" -Force
    }
    if (Test-Path "lib/models/connection_types.dart") {
        Copy-Item -Path "lib/models/connection_types.dart" -Destination "lib/features/block_workspace/models/connection_types.dart" -Force
    }
    if (Test-Path "lib/models/block_collection.dart") {
        Copy-Item -Path "lib/models/block_collection.dart" -Destination "lib/features/block_workspace/models/block_collection.dart" -Force
    }
    
    # Move providers
    if (Test-Path "lib/providers/block_provider_enhanced.dart") {
        Copy-Item -Path "lib/providers/block_provider_enhanced.dart" -Destination "lib/features/block_workspace/providers/block_provider.dart" -Force
    }
    
    # Move services
    if (Test-Path "lib/services/block_definition_service.dart") {
        Copy-Item -Path "lib/services/block_definition_service.dart" -Destination "lib/features/block_workspace/services/block_definition_service.dart" -Force
    }
    if (Test-Path "lib/services/challenge_service_enhanced.dart") {
        Copy-Item -Path "lib/services/challenge_service_enhanced.dart" -Destination "lib/features/block_workspace/services/challenge_service.dart" -Force
    }
    
    # Move screens
    if (Test-Path "lib/screens/block_workspace_enhanced.dart") {
        Copy-Item -Path "lib/screens/block_workspace_enhanced.dart" -Destination "lib/features/block_workspace/screens/block_workspace.dart" -Force
    }
    
    # Move painters
    if (Test-Path "lib/painters/connections_painter.dart") {
        Copy-Item -Path "lib/painters/connections_painter.dart" -Destination "lib/features/block_workspace/painters/connections_painter.dart" -Force
    }
    if (Test-Path "lib/painters/pattern_painter.dart") {
        Copy-Item -Path "lib/painters/pattern_painter.dart" -Destination "lib/features/block_workspace/painters/pattern_painter.dart" -Force
    }
    
    # Move widgets
    if (Test-Path "lib/widgets/block_widget.dart") {
        Copy-Item -Path "lib/widgets/block_widget.dart" -Destination "lib/features/block_workspace/widgets/block_widget.dart" -Force
    }
    if (Test-Path "lib/widgets/pattern_creation_workspace.dart") {
        Copy-Item -Path "lib/widgets/pattern_creation_workspace.dart" -Destination "lib/features/block_workspace/widgets/pattern_creation_workspace.dart" -Force
    }
}

# Move storytelling files
function Move-StorytellingFiles {
    # Move models
    if (Test-Path "lib/models/story_model.dart") {
        Copy-Item -Path "lib/models/story_model.dart" -Destination "lib/features/storytelling/models/story_model.dart" -Force
    }
    if (Test-Path "lib/models/story_branch_model.dart") {
        Copy-Item -Path "lib/models/story_branch_model.dart" -Destination "lib/features/storytelling/models/story_branch_model.dart" -Force
    }
    if (Test-Path "lib/models/content_block_model.dart") {
        Copy-Item -Path "lib/models/content_block_model.dart" -Destination "lib/features/storytelling/models/content_block_model.dart" -Force
    }
    
    # Move providers
    if (Test-Path "lib/providers/story_provider.dart") {
        Copy-Item -Path "lib/providers/story_provider.dart" -Destination "lib/features/storytelling/providers/story_provider.dart" -Force
    }
    
    # Move services
    if (Test-Path "lib/services/gemini_story_service.dart") {
        Copy-Item -Path "lib/services/gemini_story_service.dart" -Destination "lib/features/storytelling/services/ai/gemini_story_service.dart" -Force
    }
    if (Test-Path "lib/services/gemini_story_service_helper.dart") {
        Copy-Item -Path "lib/services/gemini_story_service_helper.dart" -Destination "lib/features/storytelling/services/ai/gemini_story_service_helper.dart" -Force
    }
    if (Test-Path "lib/services/story_mentor_service_enhanced.dart") {
        Copy-Item -Path "lib/services/story_mentor_service_enhanced.dart" -Destination "lib/features/storytelling/services/story_mentor_service.dart" -Force
    }
    if (Test-Path "lib/services/story_memory_service.dart") {
        Copy-Item -Path "lib/services/story_memory_service.dart" -Destination "lib/features/storytelling/services/memory/story_memory_service.dart" -Force
    }
    
    # Move screens
    if (Test-Path "lib/screens/story_screen.dart") {
        Copy-Item -Path "lib/screens/story_screen.dart" -Destination "lib/features/storytelling/screens/story_screen.dart" -Force
    }
    
    # Move widgets
    if (Test-Path "lib/widgets/narrative_choice_widget.dart") {
        Copy-Item -Path "lib/widgets/narrative_choice_widget.dart" -Destination "lib/features/storytelling/widgets/narrative_choice_widget.dart" -Force
    }
    if (Test-Path "lib/widgets/story_card.dart") {
        Copy-Item -Path "lib/widgets/story_card.dart" -Destination "lib/features/storytelling/widgets/story_card.dart" -Force
    }
}

# Move cultural context files
function Move-CulturalContextFiles {
    # Move services
    if (Test-Path "lib/services/cultural_data_service_enhanced.dart") {
        Copy-Item -Path "lib/services/cultural_data_service_enhanced.dart" -Destination "lib/features/cultural_context/services/cultural_data_service.dart" -Force
    }
    
    # Move widgets
    if (Test-Path "lib/widgets/cultural_context_card.dart") {
        Copy-Item -Path "lib/widgets/cultural_context_card.dart" -Destination "lib/features/cultural_context/widgets/cultural_context_card.dart" -Force
    }
}

# Move learning files
function Move-LearningFiles {
    # Move models
    if (Test-Path "lib/models/skill_level.dart") {
        Copy-Item -Path "lib/models/skill_level.dart" -Destination "lib/features/learning/models/skill_level.dart" -Force
    }
    if (Test-Path "lib/models/skill_type.dart") {
        Copy-Item -Path "lib/models/skill_type.dart" -Destination "lib/features/learning/models/skill_type.dart" -Force
    }
    if (Test-Path "lib/models/user_progress.dart") {
        Copy-Item -Path "lib/models/user_progress.dart" -Destination "lib/features/learning/models/user_progress.dart" -Force
    }
    if (Test-Path "lib/models/user_progress_extensions.dart") {
        Copy-Item -Path "lib/models/user_progress_extensions.dart" -Destination "lib/features/learning/models/user_progress_extensions.dart" -Force
    }
    
    # Move providers
    if (Test-Path "lib/providers/learning_provider_enhanced.dart") {
        Copy-Item -Path "lib/providers/learning_provider_enhanced.dart" -Destination "lib/features/learning/providers/learning_provider.dart" -Force
    }
    
    # Move services
    if (Test-Path "lib/services/adaptive_learning_service_enhanced.dart") {
        Copy-Item -Path "lib/services/adaptive_learning_service_enhanced.dart" -Destination "lib/features/learning/services/adaptive_learning_service.dart" -Force
    }
    if (Test-Path "lib/services/learning_analysis_service.dart") {
        Copy-Item -Path "lib/services/learning_analysis_service.dart" -Destination "lib/features/learning/services/learning_analysis_service.dart" -Force
    }
}

# Move shared services
function Move-SharedServices {
    # Move storage services
    if (Test-Path "lib/services/storage_service.dart") {
        Copy-Item -Path "lib/services/storage_service.dart" -Destination "lib/services/storage/storage_service.dart" -Force
    }
    
    # Move audio services
    if (Test-Path "lib/services/audio_service.dart") {
        Copy-Item -Path "lib/services/audio_service.dart" -Destination "lib/services/audio/audio_service.dart" -Force
    }
    
    # Move TTS services
    if (Test-Path "lib/services/tts_service.dart") {
        Copy-Item -Path "lib/services/tts_service.dart" -Destination "lib/services/tts/tts_service.dart" -Force
    }
}

# Create interface files
function Create-InterfaceFiles {
    # Create block workspace interface
    $blockWorkspaceInterface = @"
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';

/// Interface for the block workspace feature to interact with other features
abstract class ChallengeInterface {
  /// Prepare a challenge with the given ID and required block types
  Future<void> prepareChallenge(String challengeId, List<BlockType> requiredBlockTypes);
  
  /// Validate the current solution
  Future<bool> validateSolution();
  
  /// Get the current challenge ID
  String? getCurrentChallengeId();
}
"@
    Set-Content -Path "lib/features/block_workspace/interfaces/challenge_interface.dart" -Value $blockWorkspaceInterface

    # Create storytelling interface
    $storyInterface = @"
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';

/// Interface for the storytelling feature to interact with other features
abstract class StoryChallengeInterface {
  /// Called when a challenge is completed
  Future<void> onChallengeCompleted(String storyId, String challengeId, bool success);
  
  /// Get the required block types for a story's challenge
  List<BlockType> getRequiredBlockTypes(String storyId);
  
  /// Get the difficulty level of a story's challenge
  int getChallengeDifficulty(String storyId);
}
"@
    Set-Content -Path "lib/features/storytelling/interfaces/story_challenge_interface.dart" -Value $storyInterface
}

# Main migration function
function Migrate-Project {
    # Create new directory structure
    Write-Host "Creating directory structure..."
    Create-DirectoryStructure
    
    # Move files to new structure
    Write-Host "Moving core files..."
    Move-CoreFiles
    
    Write-Host "Moving block workspace files..."
    Move-BlockWorkspaceFiles
    
    Write-Host "Moving storytelling files..."
    Move-StorytellingFiles
    
    Write-Host "Moving cultural context files..."
    Move-CulturalContextFiles
    
    Write-Host "Moving learning files..."
    Move-LearningFiles
    
    Write-Host "Moving shared services..."
    Move-SharedServices
    
    Write-Host "Creating interface files..."
    Create-InterfaceFiles
    
    Write-Host "Migration completed successfully!"
    Write-Host "Note: This script has copied files to the new structure. The original files are still in place."
    Write-Host "After verifying the new structure works correctly, you can remove the original files."
}

# Execute the migration
Migrate-Project
