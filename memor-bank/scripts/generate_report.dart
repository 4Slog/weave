// Generate Report Script for Memory Bank
// This script generates reports from build information

import 'dart:convert';
import 'dart:io';
import 'dart:async';

// Main function to generate a report
Future<void> main(List<String> args) async {
  print('Memory Bank - Report Generator');
  print('=============================');
  
  // Parse arguments
  final options = _parseArguments(args);
  print('Generating report for the last ${options['last']} builds');
  
  try {
    // Load build information
    final builds = await _loadBuilds(options['last'] as int);
    print('Loaded ${builds.length} builds');
    
    if (builds.isEmpty) {
      print('No builds found');
      return;
    }
    
    // Generate summary report
    await _generateSummaryReport(builds);
    
    // Generate comparison report if requested
    if (options['compare'] as bool) {
      await _generateComparisonReport(builds);
    }
    
    // Generate metrics report if requested
    if (options['metrics'] as bool) {
      await _generateMetricsReport();
    }
    
    print('Reports generated successfully');
    
  } catch (e) {
    print('Error generating report: $e');
  }
}

// Parse command line arguments
Map<String, dynamic> _parseArguments(List<String> args) {
  int last = 10; // Default number of builds to include
  bool compare = true; // Default to include comparison
  bool metrics = true; // Default to include metrics
  
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('--last=')) {
      last = int.tryParse(args[i].substring('--last='.length)) ?? 10;
    } else if (args[i] == '--no-compare') {
      compare = false;
    } else if (args[i] == '--no-metrics') {
      metrics = false;
    }
  }
  
  return {
    'last': last,
    'compare': compare,
    'metrics': metrics,
  };
}

// Load build information from JSON files
Future<List<Map<String, dynamic>>> _loadBuilds(int count) async {
  try {
    final buildsDir = Directory('../builds');
    if (!await buildsDir.exists()) {
      return [];
    }
    
    final files = await buildsDir.list().toList();
    final jsonFiles = files
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    
    // Sort files by modification time (most recent first)
    jsonFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    
    // Limit to the requested number of builds
    final limitedFiles = jsonFiles.take(count).toList();
    
    // Load build information from JSON files
    final builds = <Map<String, dynamic>>[];
    for (final file in limitedFiles) {
      final content = await file.readAsString();
      builds.add(jsonDecode(content));
    }
    
    // Sort builds by start time (most recent first)
    builds.sort((a, b) => DateTime.parse(b['startTime']).compareTo(DateTime.parse(a['startTime'])));
    
    return builds;
  } catch (e) {
    print('Error loading builds: $e');
    return [];
  }
}

// Generate a summary report of builds
Future<void> _generateSummaryReport(List<Map<String, dynamic>> builds) async {
  try {
    final reportDir = Directory('../reports');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final reportFile = File('../reports/summary_report_$timestamp.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('Memory Bank - Build Summary Report');
    buffer.writeln('=================================');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Number of builds: ${builds.length}');
    buffer.writeln();
    
    // Calculate statistics
    int successCount = 0;
    int failureCount = 0;
    int totalDuration = 0;
    
    for (final build in builds) {
      final success = build['buildResult'] != null && build['buildResult']['success'] == true;
      if (success) {
        successCount++;
      } else {
        failureCount++;
      }
      
      totalDuration += build['duration'] as int;
    }
    
    buffer.writeln('Statistics:');
    buffer.writeln('- Successful builds: $successCount');
    buffer.writeln('- Failed builds: $failureCount');
    buffer.writeln('- Success rate: ${(successCount / builds.length * 100).toStringAsFixed(2)}%');
    buffer.writeln('- Average build duration: ${(totalDuration / builds.length / 1000).toStringAsFixed(2)} seconds');
    buffer.writeln();
    
    // List builds
    buffer.writeln('Build List:');
    buffer.writeln('-----------');
    
    for (final build in builds) {
      final buildId = build['buildId'];
      final buildType = build['buildType'];
      final startTime = DateTime.parse(build['startTime']);
      final duration = build['duration'] as int;
      final success = build['buildResult'] != null && build['buildResult']['success'] == true;
      
      buffer.writeln('Build ID: $buildId');
      buffer.writeln('Type: $buildType');
      buffer.writeln('Time: ${startTime.toIso8601String()}');
      buffer.writeln('Duration: ${(duration / 1000).toStringAsFixed(2)} seconds');
      buffer.writeln('Status: ${success ? 'Success' : 'Failure'}');
      
      if (!success && build['error'] != null) {
        buffer.writeln('Error: ${build['error']}');
      }
      
      buffer.writeln();
    }
    
    await reportFile.writeAsString(buffer.toString());
    print('Summary report generated: ${reportFile.path}');
  } catch (e) {
    print('Error generating summary report: $e');
  }
}

// Generate a comparison report between builds
Future<void> _generateComparisonReport(List<Map<String, dynamic>> builds) async {
  if (builds.length < 2) {
    print('Not enough builds for comparison');
    return;
  }
  
  try {
    final reportDir = Directory('../reports');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final reportFile = File('../reports/comparison_report_$timestamp.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('Memory Bank - Build Comparison Report');
    buffer.writeln('====================================');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Number of builds compared: ${builds.length}');
    buffer.writeln();
    
    // Compare the most recent build with the previous one
    final latestBuild = builds[0];
    final previousBuild = builds[1];
    
    buffer.writeln('Comparison between:');
    buffer.writeln('- Latest build: ${latestBuild['buildId']} (${latestBuild['buildType']})');
    buffer.writeln('- Previous build: ${previousBuild['buildId']} (${previousBuild['buildType']})');
    buffer.writeln();
    
    // Compare build duration
    final latestDuration = latestBuild['duration'] as int;
    final previousDuration = previousBuild['duration'] as int;
    final durationDiff = latestDuration - previousDuration;
    final durationPercentage = (durationDiff / previousDuration * 100).toStringAsFixed(2);
    
    buffer.writeln('Build Duration:');
    buffer.writeln('- Latest: ${(latestDuration / 1000).toStringAsFixed(2)} seconds');
    buffer.writeln('- Previous: ${(previousDuration / 1000).toStringAsFixed(2)} seconds');
    buffer.writeln('- Difference: ${(durationDiff / 1000).toStringAsFixed(2)} seconds ($durationPercentage%)');
    buffer.writeln();
    
    // Compare app size if available
    if (latestBuild['appSize'] != null && previousBuild['appSize'] != null) {
      buffer.writeln('App Size:');
      buffer.writeln('- Latest: ${latestBuild['appSize']}');
      buffer.writeln('- Previous: ${previousBuild['appSize']}');
      buffer.writeln();
    }
    
    // Compare dependencies if available
    if (latestBuild['dependencies'] != null && previousBuild['dependencies'] != null) {
      final latestDeps = Map.fromEntries(
        (latestBuild['dependencies'] as List).map((dep) => MapEntry(dep['name'], dep['version']))
      );
      
      final previousDeps = Map.fromEntries(
        (previousBuild['dependencies'] as List).map((dep) => MapEntry(dep['name'], dep['version']))
      );
      
      final addedDeps = <String>[];
      final removedDeps = <String>[];
      final updatedDeps = <String, Map<String, String>>{};
      
      // Find added and updated dependencies
      for (final entry in latestDeps.entries) {
        final name = entry.key;
        final version = entry.value;
        
        if (!previousDeps.containsKey(name)) {
          addedDeps.add(name);
        } else if (previousDeps[name] != version) {
          updatedDeps[name] = {
            'from': previousDeps[name]!,
            'to': version,
          };
        }
      }
      
      // Find removed dependencies
      for (final name in previousDeps.keys) {
        if (!latestDeps.containsKey(name)) {
          removedDeps.add(name);
        }
      }
      
      buffer.writeln('Dependencies:');
      
      if (addedDeps.isNotEmpty) {
        buffer.writeln('- Added:');
        for (final name in addedDeps) {
          buffer.writeln('  - $name: ${latestDeps[name]}');
        }
      }
      
      if (removedDeps.isNotEmpty) {
        buffer.writeln('- Removed:');
        for (final name in removedDeps) {
          buffer.writeln('  - $name: ${previousDeps[name]}');
        }
      }
      
      if (updatedDeps.isNotEmpty) {
        buffer.writeln('- Updated:');
        for (final entry in updatedDeps.entries) {
          buffer.writeln('  - ${entry.key}: ${entry.value['from']} -> ${entry.value['to']}');
        }
      }
      
      if (addedDeps.isEmpty && removedDeps.isEmpty && updatedDeps.isEmpty) {
        buffer.writeln('- No changes in dependencies');
      }
      
      buffer.writeln();
    }
    
    await reportFile.writeAsString(buffer.toString());
    print('Comparison report generated: ${reportFile.path}');
  } catch (e) {
    print('Error generating comparison report: $e');
  }
}

// Generate a metrics report
Future<void> _generateMetricsReport() async {
  try {
    final metricsDir = Directory('../metrics');
    if (!await metricsDir.exists()) {
      print('No metrics available');
      return;
    }
    
    final reportDir = Directory('../reports');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final reportFile = File('../reports/metrics_report_$timestamp.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('Memory Bank - Build Metrics Report');
    buffer.writeln('=================================');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    // Load build times
    final buildTimesFile = File('../metrics/build_times.json');
    if (await buildTimesFile.exists()) {
      final content = await buildTimesFile.readAsString();
      final buildTimes = List<Map<String, dynamic>>.from(jsonDecode(content));
      
      buffer.writeln('Build Times:');
      buffer.writeln('------------');
      
      // Group build times by build type
      final buildTimesByType = <String, List<Map<String, dynamic>>>{};
      
      for (final buildTime in buildTimes) {
        final buildType = buildTime['buildType'] as String;
        buildTimesByType[buildType] ??= [];
        buildTimesByType[buildType]!.add(buildTime);
      }
      
      // Calculate statistics for each build type
      for (final entry in buildTimesByType.entries) {
        final buildType = entry.key;
        final times = entry.value;
        
        // Calculate average and trend
        final durations = times.map((t) => t['duration'] as int).toList();
        final average = durations.reduce((a, b) => a + b) / durations.length;
        
        buffer.writeln('Build type: $buildType');
        buffer.writeln('- Number of builds: ${times.length}');
        buffer.writeln('- Average duration: ${(average / 1000).toStringAsFixed(2)} seconds');
        
        // Calculate trend (is build time increasing or decreasing?)
        if (times.length >= 5) {
          final recentDurations = durations.take(5).toList();
          final recentAverage = recentDurations.reduce((a, b) => a + b) / recentDurations.length;
          
          final trend = recentAverage - average;
          final trendPercentage = (trend / average * 100).abs().toStringAsFixed(2);
          
          if (trend.abs() > average * 0.05) { // Only report significant trends (>5%)
            buffer.writeln('- Trend: ${trend > 0 ? 'Increasing' : 'Decreasing'} by $trendPercentage%');
          } else {
            buffer.writeln('- Trend: Stable');
          }
        }
        
        buffer.writeln();
      }
    }
    
    // Load app sizes
    final appSizesFile = File('../metrics/app_sizes.json');
    if (await appSizesFile.exists()) {
      final content = await appSizesFile.readAsString();
      final appSizes = List<Map<String, dynamic>>.from(jsonDecode(content));
      
      buffer.writeln('App Sizes:');
      buffer.writeln('----------');
      
      // Group app sizes by build type
      final appSizesByType = <String, List<Map<String, dynamic>>>{};
      
      for (final appSize in appSizes) {
        final buildType = appSize['buildType'] as String;
        appSizesByType[buildType] ??= [];
        appSizesByType[buildType]!.add(appSize);
      }
      
      // Report the latest app size for each build type
      for (final entry in appSizesByType.entries) {
        final buildType = entry.key;
        final sizes = entry.value;
        
        // Sort by timestamp (most recent first)
        sizes.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        
        if (sizes.isNotEmpty) {
          buffer.writeln('Build type: $buildType');
          buffer.writeln('- Latest size: ${sizes[0]['size']}');
          buffer.writeln('- Build ID: ${sizes[0]['buildId']}');
          buffer.writeln('- Timestamp: ${sizes[0]['timestamp']}');
          buffer.writeln();
        }
      }
    }
    
    await reportFile.writeAsString(buffer.toString());
    print('Metrics report generated: ${reportFile.path}');
  } catch (e) {
    print('Error generating metrics report: $e');
  }
}
