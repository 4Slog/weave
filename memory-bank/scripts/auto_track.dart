// Auto Track Script for Memory Bank
// This script automatically tracks code changes and updates memory-bank files

import 'dart:convert';
import 'dart:io';
import 'dart:async';

// Main function to automatically track code changes
Future<void> main(List<String> args) async {
  print('Memory Bank - Auto Tracking');
  print('==========================');
  
  try {
    // Get the current timestamp
    final timestamp = DateTime.now();
    print('Tracking changes at: ${timestamp.toIso8601String()}');
    
    // Create a unique ID for this tracking session
    final trackingId = 'track_${timestamp.millisecondsSinceEpoch}';
    
    // Get the list of changed files
    final changedFiles = await _getChangedFiles();
    print('Changed files: ${changedFiles.length}');
    
    if (changedFiles.isEmpty) {
      print('No changes to track');
      return;
    }
    
    // Get the current branch
    final branch = await _getCurrentBranch();
    print('Current branch: $branch');
    
    // Get the last commit hash
    final lastCommit = await _getLastCommitHash();
    print('Last commit: $lastCommit');
    
    // Get the Flutter and Dart versions
    final versions = await _getVersions();
    print('Flutter version: ${versions['Flutter'] ?? 'Unknown'}');
    print('Dart version: ${versions['Dart'] ?? 'Unknown'}');
    
    // Save tracking information
    await _saveTrackingInfo(
      trackingId: trackingId,
      timestamp: timestamp,
      branch: branch,
      lastCommit: lastCommit,
      changedFiles: changedFiles,
      versions: versions,
    );
    
    print('Tracking information saved successfully');
    
    // Update metrics
    await _updateMetrics(changedFiles);
    print('Metrics updated successfully');
    
  } catch (e) {
    print('Error tracking changes: $e');
  }
}

// Get the list of changed files
Future<List<Map<String, dynamic>>> _getChangedFiles() async {
  try {
    // Use git status to get the list of changed files
    final result = await Process.run('git', ['status', '--porcelain']);
    final output = result.stdout.toString();
    
    final changedFiles = <Map<String, dynamic>>[];
    
    // Parse the output to get the list of changed files
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final status = line.substring(0, 2).trim();
      final path = line.substring(3).trim();
      
      // Skip files in the memor-bank directory
      if (path.startsWith('memor-bank/')) continue;
      
      // Determine the change type
      String changeType;
      if (status == 'M') {
        changeType = 'modified';
      } else if (status == 'A') {
        changeType = 'added';
      } else if (status == 'D') {
        changeType = 'deleted';
      } else if (status == 'R') {
        changeType = 'renamed';
      } else if (status == '??') {
        changeType = 'untracked';
      } else {
        changeType = 'unknown';
      }
      
      // Get the file extension
      final extension = path.contains('.') ? path.split('.').last : '';
      
      // Get the file size
      int? size;
      if (File(path).existsSync()) {
        size = await File(path).length();
      }
      
      changedFiles.add({
        'path': path,
        'status': status,
        'changeType': changeType,
        'extension': extension,
        'size': size,
      });
    }
    
    return changedFiles;
  } catch (e) {
    print('Error getting changed files: $e');
    return [];
  }
}

// Get the current branch
Future<String> _getCurrentBranch() async {
  try {
    final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    print('Error getting current branch: $e');
    return 'unknown';
  }
}

// Get the last commit hash
Future<String> _getLastCommitHash() async {
  try {
    final result = await Process.run('git', ['rev-parse', 'HEAD']);
    return result.stdout.toString().trim();
  } catch (e) {
    print('Error getting last commit hash: $e');
    return 'unknown';
  }
}

// Get Flutter and Dart versions
Future<Map<String, String>> _getVersions() async {
  try {
    final result = await Process.run('flutter', ['--version']);
    final output = result.stdout.toString();
    
    final Map<String, String> versions = {};
    
    // Extract Flutter version
    final flutterMatch = RegExp(r'Flutter\s+([^\s•]+)').firstMatch(output);
    if (flutterMatch != null) {
      versions['Flutter'] = flutterMatch.group(1)!;
    }
    
    // Extract Dart version
    final dartMatch = RegExp(r'Dart\s+([^\s•]+)').firstMatch(output);
    if (dartMatch != null) {
      versions['Dart'] = dartMatch.group(1)!;
    }
    
    return versions;
  } catch (e) {
    print('Error getting versions: $e');
    return {};
  }
}

// Save tracking information
Future<void> _saveTrackingInfo({
  required String trackingId,
  required DateTime timestamp,
  required String branch,
  required String lastCommit,
  required List<Map<String, dynamic>> changedFiles,
  required Map<String, String> versions,
}) async {
  final trackingInfo = {
    'trackingId': trackingId,
    'timestamp': timestamp.toIso8601String(),
    'branch': branch,
    'lastCommit': lastCommit,
    'changedFiles': changedFiles,
    'versions': versions,
  };
  
  // Create tracking directory if it doesn't exist
  final trackingDir = Directory('../builds/tracking');
  if (!await trackingDir.exists()) {
    await trackingDir.create(recursive: true);
  }
  
  // Save tracking information to a JSON file
  final trackingFile = File('../builds/tracking/$trackingId.json');
  await trackingFile.writeAsString(JsonEncoder.withIndent('  ').convert(trackingInfo));
}

// Update metrics with the new tracking information
Future<void> _updateMetrics(List<Map<String, dynamic>> changedFiles) async {
  try {
    final metricsDir = Directory('../metrics');
    if (!await metricsDir.exists()) {
      await metricsDir.create(recursive: true);
    }
    
    // Update file changes metric
    final fileChangesFile = File('../metrics/file_changes.json');
    List<Map<String, dynamic>> fileChanges = [];
    
    if (await fileChangesFile.exists()) {
      final content = await fileChangesFile.readAsString();
      fileChanges = List<Map<String, dynamic>>.from(jsonDecode(content));
    }
    
    // Group changes by file extension
    final changesByExtension = <String, int>{};
    for (final file in changedFiles) {
      final extension = file['extension'] as String;
      changesByExtension[extension] = (changesByExtension[extension] ?? 0) + 1;
    }
    
    fileChanges.add({
      'timestamp': DateTime.now().toIso8601String(),
      'totalChanges': changedFiles.length,
      'changesByExtension': changesByExtension,
    });
    
    // Keep only the last 100 entries
    if (fileChanges.length > 100) {
      fileChanges = fileChanges.sublist(fileChanges.length - 100);
    }
    
    await fileChangesFile.writeAsString(JsonEncoder.withIndent('  ').convert(fileChanges));
  } catch (e) {
    print('Error updating metrics: $e');
  }
}
