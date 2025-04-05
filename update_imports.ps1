# Script to update import statements in migrated files

# Define the mapping of old imports to new imports
$importMappings = @{
    "package:kente_codeweaver/models/block_model.dart" = "package:kente_codeweaver/features/block_workspace/models/block_model.dart"
    "package:kente_codeweaver/models/block_type.dart" = "package:kente_codeweaver/features/block_workspace/models/block_type.dart"
    "package:kente_codeweaver/models/block_collection.dart" = "package:kente_codeweaver/features/block_workspace/models/block_collection.dart"
    "package:kente_codeweaver/models/connection_types.dart" = "package:kente_codeweaver/features/block_workspace/models/connection_types.dart"
    "package:kente_codeweaver/models/pattern_difficulty.dart" = "package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart"
    "package:kente_codeweaver/models/pattern_model.dart" = "package:kente_codeweaver/features/block_workspace/models/pattern_model.dart"
    "package:kente_codeweaver/models/story_model.dart" = "package:kente_codeweaver/features/storytelling/models/story_model.dart"
    "package:kente_codeweaver/models/story_branch_model.dart" = "package:kente_codeweaver/features/storytelling/models/story_branch_model.dart"
    "package:kente_codeweaver/models/content_block_model.dart" = "package:kente_codeweaver/features/storytelling/models/content_block_model.dart"
    "package:kente_codeweaver/models/skill_level.dart" = "package:kente_codeweaver/features/learning/models/skill_level.dart"
    "package:kente_codeweaver/models/skill_type.dart" = "package:kente_codeweaver/features/learning/models/skill_type.dart"
    "package:kente_codeweaver/models/user_progress.dart" = "package:kente_codeweaver/features/learning/models/user_progress.dart"
    "package:kente_codeweaver/models/user_progress_extensions.dart" = "package:kente_codeweaver/features/learning/models/user_progress_extensions.dart"
    "package:kente_codeweaver/models/badge_model.dart" = "package:kente_codeweaver/features/badges/models/badge_model.dart"
    "package:kente_codeweaver/models/emotional_tone.dart" = "package:kente_codeweaver/features/storytelling/models/emotional_tone.dart"
    "package:kente_codeweaver/models/tts_settings.dart" = "package:kente_codeweaver/features/storytelling/models/tts_settings.dart"
    
    "package:kente_codeweaver/providers/block_provider.dart" = "package:kente_codeweaver/features/block_workspace/providers/block_provider.dart"
    "package:kente_codeweaver/providers/story_provider.dart" = "package:kente_codeweaver/features/storytelling/providers/story_provider.dart"
    "package:kente_codeweaver/providers/learning_provider.dart" = "package:kente_codeweaver/features/learning/providers/learning_provider.dart"
    "package:kente_codeweaver/providers/settings_provider.dart" = "package:kente_codeweaver/features/settings/providers/settings_provider.dart"
    "package:kente_codeweaver/providers/badge_provider.dart" = "package:kente_codeweaver/features/badges/providers/badge_provider.dart"
    
    "package:kente_codeweaver/services/block_definition_service.dart" = "package:kente_codeweaver/features/block_workspace/services/block_definition_service.dart"
    "package:kente_codeweaver/services/challenge_service.dart" = "package:kente_codeweaver/features/challenges/services/challenge_service.dart"
    "package:kente_codeweaver/services/cultural_data_service.dart" = "package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart"
    "package:kente_codeweaver/services/adaptive_learning_service.dart" = "package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart"
    "package:kente_codeweaver/services/learning_analysis_service.dart" = "package:kente_codeweaver/features/learning/services/learning_analysis_service.dart"
    "package:kente_codeweaver/services/gemini_story_service.dart" = "package:kente_codeweaver/features/storytelling/services/ai/gemini_story_service.dart"
    "package:kente_codeweaver/services/story_mentor_service.dart" = "package:kente_codeweaver/features/storytelling/services/story_mentor_service.dart"
    "package:kente_codeweaver/services/story_memory_service.dart" = "package:kente_codeweaver/features/storytelling/services/memory/story_memory_service.dart"
    "package:kente_codeweaver/services/badge_service.dart" = "package:kente_codeweaver/features/badges/services/badge_service.dart"
    "package:kente_codeweaver/services/storage_service.dart" = "package:kente_codeweaver/core/services/storage_service.dart"
    "package:kente_codeweaver/services/audio_service.dart" = "package:kente_codeweaver/core/services/audio_service.dart"
    "package:kente_codeweaver/services/tts_service.dart" = "package:kente_codeweaver/core/services/tts_service.dart"
    
    "package:kente_codeweaver/screens/block_workspace.dart" = "package:kente_codeweaver/features/block_workspace/screens/block_workspace_screen.dart"
    "package:kente_codeweaver/screens/story_screen.dart" = "package:kente_codeweaver/features/storytelling/screens/story_screen.dart"
    "package:kente_codeweaver/screens/settings_screen.dart" = "package:kente_codeweaver/features/settings/screens/settings_screen.dart"
    "package:kente_codeweaver/screens/welcome_screen.dart" = "package:kente_codeweaver/features/welcome/screens/welcome_screen.dart"
    
    "package:kente_codeweaver/widgets/block_widget.dart" = "package:kente_codeweaver/features/block_workspace/widgets/block_widget.dart"
    "package:kente_codeweaver/widgets/pattern_creation_workspace.dart" = "package:kente_codeweaver/features/block_workspace/widgets/pattern_creation_workspace.dart"
    "package:kente_codeweaver/widgets/narrative_choice_widget.dart" = "package:kente_codeweaver/features/storytelling/widgets/narrative_choice_widget.dart"
    "package:kente_codeweaver/widgets/story_card.dart" = "package:kente_codeweaver/features/storytelling/widgets/story_card.dart"
    "package:kente_codeweaver/widgets/cultural_context_card.dart" = "package:kente_codeweaver/features/cultural_context/widgets/cultural_context_card.dart"
    "package:kente_codeweaver/widgets/badge_display_widget.dart" = "package:kente_codeweaver/features/badges/widgets/badge_display_widget.dart"
    "package:kente_codeweaver/widgets/contextual_hint_widget.dart" = "package:kente_codeweaver/features/learning/widgets/contextual_hint_widget.dart"
    "package:kente_codeweaver/widgets/breadcrumb_navigation.dart" = "package:kente_codeweaver/core/widgets/breadcrumb_navigation.dart"
    
    "package:kente_codeweaver/painters/connections_painter.dart" = "package:kente_codeweaver/features/block_workspace/painters/connections_painter.dart"
    "package:kente_codeweaver/painters/pattern_painter.dart" = "package:kente_codeweaver/features/block_workspace/painters/pattern_painter.dart"
    
    "package:kente_codeweaver/navigation/app_router.dart" = "package:kente_codeweaver/core/navigation/app_router.dart"
    "package:kente_codeweaver/theme/app_theme.dart" = "package:kente_codeweaver/core/theme/app_theme.dart"
}

# Function to update imports in a file
function Update-Imports {
    param (
        [string]$filePath
    )
    
    Write-Host "Updating imports in $filePath..."
    
    # Read the file content
    $content = Get-Content -Path $filePath -Raw
    
    # Flag to track if any changes were made
    $changed = $false
    
    # Replace each old import with the new import
    foreach ($oldImport in $importMappings.Keys) {
        $newImport = $importMappings[$oldImport]
        
        if ($content -match [regex]::Escape($oldImport)) {
            $content = $content -replace [regex]::Escape($oldImport), $newImport
            $changed = $true
            Write-Host "  Replaced: $oldImport -> $newImport"
        }
    }
    
    # Write the updated content back to the file if changes were made
    if ($changed) {
        Set-Content -Path $filePath -Value $content
        Write-Host "  File updated."
    } else {
        Write-Host "  No changes needed."
    }
}

# Function to process all Dart files in a directory recursively
function Process-Directory {
    param (
        [string]$directory
    )
    
    # Get all Dart files in the directory
    $dartFiles = Get-ChildItem -Path $directory -Filter "*.dart" -File
    
    # Update imports in each Dart file
    foreach ($file in $dartFiles) {
        Update-Imports -filePath $file.FullName
    }
    
    # Process subdirectories
    $subdirectories = Get-ChildItem -Path $directory -Directory
    foreach ($subdir in $subdirectories) {
        Process-Directory -directory $subdir.FullName
    }
}

# Main function
function Update-AllImports {
    # Process the lib directory
    Process-Directory -directory "lib"
    
    Write-Host "Import update completed successfully!"
}

# Execute the main function
Update-AllImports
