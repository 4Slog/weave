# Complete the migration and move old files to @old/ directory

# Create @old directory if it doesn't exist
function Create-OldDirectory {
    if (-not (Test-Path "@old")) {
        New-Item -Path "@old" -ItemType Directory -Force
    }
    
    # Create subdirectories in @old to match the old structure
    $oldDirs = @(
        "@old/models",
        "@old/providers",
        "@old/services",
        "@old/widgets",
        "@old/screens",
        "@old/painters",
        "@old/navigation",
        "@old/theme"
    )
    
    foreach ($dir in $oldDirs) {
        New-Item -Path $dir -ItemType Directory -Force
    }
}

# Move old files to @old directory
function Move-OldFiles {
    # Move models
    if (Test-Path "lib/models") {
        Get-ChildItem -Path "lib/models" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/models/$($_.Name)" -Force
        }
    }
    
    # Move providers
    if (Test-Path "lib/providers") {
        Get-ChildItem -Path "lib/providers" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/providers/$($_.Name)" -Force
        }
    }
    
    # Move services
    if (Test-Path "lib/services") {
        Get-ChildItem -Path "lib/services" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/services/$($_.Name)" -Force
        }
    }
    
    # Move widgets
    if (Test-Path "lib/widgets") {
        Get-ChildItem -Path "lib/widgets" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/widgets/$($_.Name)" -Force
        }
    }
    
    # Move screens
    if (Test-Path "lib/screens") {
        Get-ChildItem -Path "lib/screens" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/screens/$($_.Name)" -Force
        }
    }
    
    # Move painters
    if (Test-Path "lib/painters") {
        Get-ChildItem -Path "lib/painters" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/painters/$($_.Name)" -Force
        }
    }
    
    # Move navigation
    if (Test-Path "lib/navigation") {
        Get-ChildItem -Path "lib/navigation" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/navigation/$($_.Name)" -Force
        }
    }
    
    # Move theme
    if (Test-Path "lib/theme") {
        Get-ChildItem -Path "lib/theme" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "@old/theme/$($_.Name)" -Force
        }
    }
}

# Replace main.dart with main_with_new_structure.dart
function Update-MainFile {
    if (Test-Path "lib/main_with_new_structure.dart") {
        # Backup the original main.dart
        if (Test-Path "lib/main.dart") {
            Copy-Item -Path "lib/main.dart" -Destination "@old/main.dart" -Force
        }
        
        # Copy the new structure main file to main.dart
        Copy-Item -Path "lib/main_with_new_structure.dart" -Destination "lib/main.dart" -Force
        
        # Move the main_with_new_structure.dart to @old
        Copy-Item -Path "lib/main_with_new_structure.dart" -Destination "@old/main_with_new_structure.dart" -Force
    }
}

# Main function
function Complete-Migration {
    # Create @old directory
    Write-Host "Creating @old directory structure..."
    Create-OldDirectory
    
    # Move old files to @old directory
    Write-Host "Moving old files to @old directory..."
    Move-OldFiles
    
    # Update main.dart
    Write-Host "Updating main.dart..."
    Update-MainFile
    
    Write-Host "Migration completed successfully!"
    Write-Host "Old files have been moved to the @old directory."
    Write-Host "The main.dart file has been updated to use the new structure."
}

# Execute the migration
Complete-Migration
