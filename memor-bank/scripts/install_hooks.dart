// Install Hooks Script for Memory Bank
// This script installs Git hooks to automatically track code changes

import 'dart:io';
import 'dart:async';

// Main function to install Git hooks
Future<void> main(List<String> args) async {
  print('Memory Bank - Install Hooks');
  print('==========================');
  
  try {
    // Get the Git hooks directory
    final gitDir = await _findGitDir();
    if (gitDir == null) {
      print('Error: Not a Git repository');
      return;
    }
    
    final hooksDir = Directory('${gitDir.path}/hooks');
    if (!await hooksDir.exists()) {
      await hooksDir.create(recursive: true);
    }
    
    print('Installing Git hooks in: ${hooksDir.path}');
    
    // Create the pre-commit hook
    await _createPreCommitHook(hooksDir);
    print('Pre-commit hook installed successfully');
    
    // Create the post-commit hook
    await _createPostCommitHook(hooksDir);
    print('Post-commit hook installed successfully');
    
    // Create the pre-push hook
    await _createPrePushHook(hooksDir);
    print('Pre-push hook installed successfully');
    
    print('Git hooks installed successfully');
    print('Memory Bank will now automatically track code changes');
    
  } catch (e) {
    print('Error installing Git hooks: $e');
  }
}

// Find the .git directory
Future<Directory?> _findGitDir() async {
  Directory current = Directory.current;
  
  while (true) {
    final gitDir = Directory('${current.path}/.git');
    if (await gitDir.exists()) {
      return gitDir;
    }
    
    final parent = current.parent;
    if (parent.path == current.path) {
      // Reached the root directory
      return null;
    }
    
    current = parent;
  }
}

// Create the pre-commit hook
Future<void> _createPreCommitHook(Directory hooksDir) async {
  final hookFile = File('${hooksDir.path}/pre-commit');
  
  final content = '''#!/bin/sh
# Memory Bank pre-commit hook
# This hook runs before a commit is created

# Get the absolute path to the repository root
REPO_ROOT=\$(git rev-parse --show-toplevel)

# Run the auto_track.dart script
echo "Running Memory Bank auto-tracking..."
cd "\$REPO_ROOT"
dart memor-bank/scripts/auto_track.dart pre-commit

# Continue with the commit
exit 0
''';
  
  await hookFile.writeAsString(content);
  
  // Make the hook executable
  await Process.run('chmod', ['+x', hookFile.path]);
}

// Create the post-commit hook
Future<void> _createPostCommitHook(Directory hooksDir) async {
  final hookFile = File('${hooksDir.path}/post-commit');
  
  final content = '''#!/bin/sh
# Memory Bank post-commit hook
# This hook runs after a commit is created

# Get the absolute path to the repository root
REPO_ROOT=\$(git rev-parse --show-toplevel)

# Run the auto_track.dart script
echo "Running Memory Bank auto-tracking..."
cd "\$REPO_ROOT"
dart memor-bank/scripts/auto_track.dart post-commit

# Continue with the commit
exit 0
''';
  
  await hookFile.writeAsString(content);
  
  // Make the hook executable
  await Process.run('chmod', ['+x', hookFile.path]);
}

// Create the pre-push hook
Future<void> _createPrePushHook(Directory hooksDir) async {
  final hookFile = File('${hooksDir.path}/pre-push');
  
  final content = '''#!/bin/sh
# Memory Bank pre-push hook
# This hook runs before changes are pushed to a remote repository

# Get the absolute path to the repository root
REPO_ROOT=\$(git rev-parse --show-toplevel)

# Run the auto_track.dart script
echo "Running Memory Bank auto-tracking..."
cd "\$REPO_ROOT"
dart memor-bank/scripts/auto_track.dart pre-push

# Continue with the push
exit 0
''';
  
  await hookFile.writeAsString(content);
  
  // Make the hook executable
  await Process.run('chmod', ['+x', hookFile.path]);
}
