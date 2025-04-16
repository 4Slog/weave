import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/core/services/storage/memory_storage_strategy.dart';

/// Utility class for performance testing.
class PerformanceTestUtils {
  /// Run a performance test for a function.
  ///
  /// [name] is the name of the test.
  /// [function] is the function to test.
  /// [iterations] is the number of times to run the function.
  /// [warmupIterations] is the number of warmup iterations to run before measuring.
  ///
  /// Returns a map with performance metrics.
  static Future<Map<String, dynamic>> runPerformanceTest({
    required String name,
    required Future<void> Function() function,
    int iterations = 10,
    int warmupIterations = 3,
  }) async {
    debugPrint('Running performance test: $name');
    debugPrint('Warming up for $warmupIterations iterations...');

    // Warmup
    for (int i = 0; i < warmupIterations; i++) {
      await function();
    }

    debugPrint('Starting measurement for $iterations iterations...');

    // Measure
    final stopwatch = Stopwatch()..start();
    final List<int> executionTimes = [];

    for (int i = 0; i < iterations; i++) {
      final iterationStopwatch = Stopwatch()..start();
      await function();
      iterationStopwatch.stop();
      executionTimes.add(iterationStopwatch.elapsedMilliseconds);
    }

    stopwatch.stop();

    // Calculate metrics
    final totalTime = stopwatch.elapsedMilliseconds;
    final averageTime = totalTime / iterations;
    final minTime = executionTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = executionTimes.reduce((a, b) => a > b ? a : b);

    // Calculate standard deviation
    final mean = executionTimes.reduce((a, b) => a + b) / executionTimes.length;
    final variance = executionTimes.map((t) => (t - mean) * (t - mean)).reduce((a, b) => a + b) / executionTimes.length;
    final stdDev = sqrt(variance);

    // Print results
    debugPrint('Performance test results for $name:');
    debugPrint('  Total time: ${totalTime}ms');
    debugPrint('  Average time: ${averageTime.toStringAsFixed(2)}ms');
    debugPrint('  Min time: ${minTime}ms');
    debugPrint('  Max time: ${maxTime}ms');
    debugPrint('  Standard deviation: ${stdDev.toStringAsFixed(2)}ms');

    return {
      'name': name,
      'iterations': iterations,
      'totalTime': totalTime,
      'averageTime': averageTime,
      'minTime': minTime,
      'maxTime': maxTime,
      'standardDeviation': stdDev,
      'executionTimes': executionTimes,
    };
  }

  /// Run a memory usage test for a function.
  ///
  /// [name] is the name of the test.
  /// [function] is the function to test.
  /// [iterations] is the number of times to run the function.
  ///
  /// Returns a map with memory usage metrics.
  static Future<Map<String, dynamic>> runMemoryTest({
    required String name,
    required Future<void> Function() function,
    int iterations = 10,
  }) async {
    debugPrint('Running memory test: $name');

    // Initial memory snapshot
    final initialMemory = await getMemoryUsage();

    // Run the function multiple times
    for (int i = 0; i < iterations; i++) {
      await function();
    }

    // Force garbage collection if possible
    await forceGarbageCollection();

    // Final memory snapshot
    final finalMemory = await getMemoryUsage();

    // Calculate metrics
    final memoryDelta = finalMemory - initialMemory;
    final memoryPerIteration = memoryDelta / iterations;

    // Print results
    debugPrint('Memory test results for $name:');
    debugPrint('  Initial memory: ${formatMemory(initialMemory)}');
    debugPrint('  Final memory: ${formatMemory(finalMemory)}');
    debugPrint('  Memory delta: ${formatMemory(memoryDelta)}');
    debugPrint('  Memory per iteration: ${formatMemory(memoryPerIteration.toInt())}');

    return {
      'name': name,
      'iterations': iterations,
      'initialMemory': initialMemory,
      'finalMemory': finalMemory,
      'memoryDelta': memoryDelta,
      'memoryPerIteration': memoryPerIteration,
    };
  }

  /// Compare performance of two implementations.
  ///
  /// [name] is the name of the comparison.
  /// [oldImplementation] is the old implementation to test.
  /// [newImplementation] is the new implementation to test.
  /// [iterations] is the number of times to run each implementation.
  ///
  /// Returns a map with comparison metrics.
  static Future<Map<String, dynamic>> comparePerformance({
    required String name,
    required Future<void> Function() oldImplementation,
    required Future<void> Function() newImplementation,
    int iterations = 10,
  }) async {
    debugPrint('Comparing performance: $name');

    // Test old implementation
    final oldResults = await runPerformanceTest(
      name: 'Old Implementation - $name',
      function: oldImplementation,
      iterations: iterations,
    );

    // Test new implementation
    final newResults = await runPerformanceTest(
      name: 'New Implementation - $name',
      function: newImplementation,
      iterations: iterations,
    );

    // Calculate improvement
    final oldAverage = oldResults['averageTime'] as double;
    final newAverage = newResults['averageTime'] as double;
    final improvement = (oldAverage - newAverage) / oldAverage * 100;

    // Print comparison
    debugPrint('Performance comparison for $name:');
    debugPrint('  Old implementation average: ${oldAverage.toStringAsFixed(2)}ms');
    debugPrint('  New implementation average: ${newAverage.toStringAsFixed(2)}ms');
    debugPrint('  Improvement: ${improvement.toStringAsFixed(2)}%');

    return {
      'name': name,
      'oldResults': oldResults,
      'newResults': newResults,
      'improvement': improvement,
    };
  }

  /// Get current memory usage.
  ///
  /// Returns the current memory usage in bytes.
  static Future<int> getMemoryUsage() async {
    // This is a simplified implementation
    // In a real app, you would use platform-specific methods to get memory usage
    return 0;
  }

  /// Force garbage collection.
  static Future<void> forceGarbageCollection() async {
    // This is a simplified implementation
    // In a real app, you would use platform-specific methods to force GC
    await Future.delayed(Duration(milliseconds: 500));
  }

  /// Format memory size for display.
  static String formatMemory(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Create a test storage service with in-memory storage.
  static StorageService createTestStorageService() {
    return StorageService();
  }

  /// Calculate square root (simplified implementation).
  static double sqrt(double value) {
    double x = value;
    double y = 1.0;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = value / x;
    }
    return x;
  }
}
