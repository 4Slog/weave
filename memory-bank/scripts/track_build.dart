// Track Build Script for Memory Bank
// This script records information about Flutter builds

import 'dart:convert';
import 'dart:io';
import 'dart:async';

// Main function to track a build
Future<void> main(List<String> args) async {
  print('Memory Bank - Build Tracking');
  print('===========================');
  
  // Parse arguments
  final buildType = _parseArguments(args);
  print('Build type: $buildType');
  
  // Record start time
  final startTime = DateTime.now();
  print('Build started at: ${startTime.toIso8601String()}');
  
  // Create build ID
  final buildId = 'build_${startTime.millisecondsSinceEpoch}';
  
  try {
    // Get Flutter and Dart versions
    final flutterVersion = await _getFlutterVersion();
    print('Flutter version: ${flutterVersion['Flutter'] ?? 'Unknown'}');
    print('Dart version: ${flutterVersion['Dart'] ?? 'Unknown'}');
    
    // Get dependencies
    final dependencies = await _getDependencies();
    print('Dependencies: ${dependencies.length} packages');
    
    // Simulate build process (in a real scenario, this would be the actual build)
    print('Running build process...');
    final buildResult = await _runBuild(buildType);
    
    // Record end time and calculate duration
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print('Build completed at: ${endTime.toIso8601String()}');
    print('Build duration: ${duration.inSeconds} seconds');
    
    // Get app size
    final appSize = await _getAppSize(buildType);
    print('App size: ${appSize ?? 'Unknown'}');
    
    // Save build information
    await _saveBuildInfo(
      buildId: buildId,
      buildType: buildType,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      flutterVersion: flutterVersion,
      dependencies: dependencies,
      buildResult: buildResult,
      appSize: appSize,
    );
    
    print('Build information saved successfully');
    
    // Check if we should notify on failure
    if (!buildResult['success'] && await _shouldNotifyOnFailure()) {
      await _sendNotification(
        'Build Failed',
        'Build $buildId of type $buildType failed with error: ${buildResult['error']}',
      );
    }
    
  } catch (e) {
    print('Error tracking build: $e');
    // Save error information
    await _saveBuildInfo(
      buildId: buildId,
      buildType: buildType,
      startTime: startTime,
      endTime: DateTime.now(),
      duration: DateTime.now().difference(startTime),
      error: e.toString(),
    );
    
    // Send notification
    if (await _shouldNotifyOnFailure()) {
      await _sendNotification(
        'Build Tracking Error',
        'Error tracking build $buildId: $e',
      );
    }
  }
}

// Parse command line arguments
String _parseArguments(List<String> args) {
  String buildType = 'debug'; // Default build type
  
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('--type=')) {
      buildType = args[i].substring('--type='.length);
    }
  }
  
  return buildType;
}

// Get Flutter and Dart versions
Future<Map<String, String>> _getFlutterVersion() async {
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
    print('Error getting Flutter version: $e');
    return {};
  }
}

// Get project dependencies
Future<List<Map<String, String>>> _getDependencies() async {
  try {
    final pubspecFile = File('../pubspec.yaml');
    final lockFile = File('../pubspec.lock');
    
    if (!lockFile.existsSync()) {
      return [];
    }
    
    final lockContent = await lockFile.readAsString();
    final dependencies = <Map<String, String>>[];
    
    // This is a simplified parser for pubspec.lock
    // In a real implementation, you would use a proper YAML parser
    final packageMatches = RegExp(r'(\w+):\s+\n\s+dependency:.*?\n\s+version:\s+"([^"]+)"', dotAll: true).allMatches(lockContent);
    
    for (final match in packageMatches) {
      dependencies.add({
        'name': match.group(1)!,
        'version': match.group(2)!,
      });
    }
    
    return dependencies;
  } catch (e) {
    print('Error getting dependencies: $e');
    return [];
  }
}

// Simulate running a build (in a real scenario, this would run the actual build command)
Future<Map<String, dynamic>> _runBuild(String buildType) async {
  try {
    // In a real implementation, this would run the actual build command
    // For example: flutter build apk --release
    
    // Simulate build process
    await Future.delayed(Duration(seconds: 2));
    
    // Simulate build success (in a real scenario, this would check the actual build result)
    return {
      'success': true,
      'output': 'Build completed successfully',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

// Get app size
Future<String?> _getAppSize(String buildType) async {
  try {
    // In a real implementation, this would get the actual app size
    // For example, by checking the size of the APK or IPA file
    
    // Simulate getting app size
    switch (buildType) {
      case 'debug':
        return '45.2 MB';
      case 'profile':
        return '38.7 MB';
      case 'release':
        return '32.1 MB';
      default:
        return null;
    }
  } catch (e) {
    print('Error getting app size: $e');
    return null;
  }
}

// Save build information to a JSON file
Future<void> _saveBuildInfo({
  required String buildId,
  required String buildType,
  required DateTime startTime,
  required DateTime endTime,
  required Duration duration,
  Map<String, String>? flutterVersion,
  List<Map<String, String>>? dependencies,
  Map<String, dynamic>? buildResult,
  String? appSize,
  String? error,
}) async {
  final buildInfo = {
    'buildId': buildId,
    'buildType': buildType,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inMilliseconds,
    'flutterVersion': flutterVersion,
    'dependencies': dependencies,
    'buildResult': buildResult,
    'appSize': appSize,
    'error': error,
  };
  
  // Create builds directory if it doesn't exist
  final buildsDir = Directory('../builds');
  if (!await buildsDir.exists()) {
    await buildsDir.create(recursive: true);
  }
  
  // Save build information to a JSON file
  final buildFile = File('../builds/$buildId.json');
  await buildFile.writeAsString(JsonEncoder.withIndent('  ').convert(buildInfo));
  
  // Save build log
  if (buildResult != null && buildResult['output'] != null) {
    final logFile = File('../logs/$buildId.log');
    await logFile.writeAsString(buildResult['output']);
  }
  
  // Update metrics
  await _updateMetrics(buildInfo);
}

// Update metrics with the new build information
Future<void> _updateMetrics(Map<String, dynamic> buildInfo) async {
  try {
    final metricsDir = Directory('../metrics');
    if (!await metricsDir.exists()) {
      await metricsDir.create(recursive: true);
    }
    
    // Update build times metric
    final buildTimesFile = File('../metrics/build_times.json');
    List<Map<String, dynamic>> buildTimes = [];
    
    if (await buildTimesFile.exists()) {
      final content = await buildTimesFile.readAsString();
      buildTimes = List<Map<String, dynamic>>.from(jsonDecode(content));
    }
    
    buildTimes.add({
      'buildId': buildInfo['buildId'],
      'buildType': buildInfo['buildType'],
      'timestamp': buildInfo['endTime'],
      'duration': buildInfo['duration'],
    });
    
    // Keep only the last 100 builds
    if (buildTimes.length > 100) {
      buildTimes = buildTimes.sublist(buildTimes.length - 100);
    }
    
    await buildTimesFile.writeAsString(JsonEncoder.withIndent('  ').convert(buildTimes));
    
    // Update app size metric
    if (buildInfo['appSize'] != null) {
      final appSizesFile = File('../metrics/app_sizes.json');
      List<Map<String, dynamic>> appSizes = [];
      
      if (await appSizesFile.exists()) {
        final content = await appSizesFile.readAsString();
        appSizes = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      
      appSizes.add({
        'buildId': buildInfo['buildId'],
        'buildType': buildInfo['buildType'],
        'timestamp': buildInfo['endTime'],
        'size': buildInfo['appSize'],
      });
      
      // Keep only the last 100 builds
      if (appSizes.length > 100) {
        appSizes = appSizes.sublist(appSizes.length - 100);
      }
      
      await appSizesFile.writeAsString(JsonEncoder.withIndent('  ').convert(appSizes));
    }
  } catch (e) {
    print('Error updating metrics: $e');
  }
}

// Check if we should notify on failure
Future<bool> _shouldNotifyOnFailure() async {
  try {
    final configFile = File('../config.json');
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      return config['notifyOnFailure'] ?? false;
    }
    return false;
  } catch (e) {
    print('Error checking notification settings: $e');
    return false;
  }
}

// Send a notification
Future<void> _sendNotification(String title, String message) async {
  try {
    print('NOTIFICATION: $title - $message');
    
    // In a real implementation, this would send an actual notification
    // For example, via email, Slack, or desktop notification
    
    final configFile = File('../config.json');
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      final notifications = config['notifications'] ?? {};
      
      if (notifications['desktop'] == true) {
        // Send desktop notification
        print('Sending desktop notification...');
      }
      
      if (notifications['email'] == true) {
        // Send email notification
        print('Sending email notification...');
      }
      
      if (notifications['slack'] == true) {
        // Send Slack notification
        print('Sending Slack notification...');
      }
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}
