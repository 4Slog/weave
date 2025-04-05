#!/bin/bash

# Complete the migration and move old files to @old/ directory

# Create @old directory if it doesn't exist
mkdir -p @old/models
mkdir -p @old/providers
mkdir -p @old/services
mkdir -p @old/widgets
mkdir -p @old/screens
mkdir -p @old/painters
mkdir -p @old/navigation
mkdir -p @old/theme

# Move old files to @old directory
echo "Moving old files to @old directory..."

# Move models
if [ -d "lib/models" ]; then
    cp lib/models/* @old/models/ 2>/dev/null || true
fi

# Move providers
if [ -d "lib/providers" ]; then
    cp lib/providers/* @old/providers/ 2>/dev/null || true
fi

# Move services
if [ -d "lib/services" ]; then
    cp lib/services/* @old/services/ 2>/dev/null || true
fi

# Move widgets
if [ -d "lib/widgets" ]; then
    cp lib/widgets/* @old/widgets/ 2>/dev/null || true
fi

# Move screens
if [ -d "lib/screens" ]; then
    cp lib/screens/* @old/screens/ 2>/dev/null || true
fi

# Move painters
if [ -d "lib/painters" ]; then
    cp lib/painters/* @old/painters/ 2>/dev/null || true
fi

# Move navigation
if [ -d "lib/navigation" ]; then
    cp lib/navigation/* @old/navigation/ 2>/dev/null || true
fi

# Move theme
if [ -d "lib/theme" ]; then
    cp lib/theme/* @old/theme/ 2>/dev/null || true
fi

# Update main.dart
echo "Updating main.dart..."
if [ -f "lib/main_with_new_structure.dart" ]; then
    # Backup the original main.dart
    if [ -f "lib/main.dart" ]; then
        cp lib/main.dart @old/main.dart
    fi
    
    # Copy the new structure main file to main.dart
    cp lib/main_with_new_structure.dart lib/main.dart
    
    # Move the main_with_new_structure.dart to @old
    cp lib/main_with_new_structure.dart @old/main_with_new_structure.dart
fi

echo "Migration completed successfully!"
echo "Old files have been moved to the @old directory."
echo "The main.dart file has been updated to use the new structure."
