import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';

/// Service for monitoring and tracking app performance
class PerformanceMonitorService {
  // Singleton implementation
  static final PerformanceMonitorService _instance = PerformanceMonitorService._internal();

  factory PerformanceMonitorService() {
    return _instance;
  }

  PerformanceMonitorService._internal();

  // Dependencies
  final StorageService _storageService = StorageService();

  // Performance tracking state
  bool _isInitialized = false;
  bool _isMonitoring = false;

  // Frame timing
  Ticker? _ticker;
  final Queue<Duration> _frameTimes = Queue<Duration>();
  final int _maxFrameTimeCount = 120; // Track 2 seconds of frames at 60fps
  double _averageFps = 0;
  double _worstFps = 0;

  // Memory usage
  final List<Map<String, dynamic>> _memorySnapshots = [];
  Timer? _memoryMonitorTimer;

  // Performance events
  final List<Map<String, dynamic>> _performanceEvents = [];

  // App info
  String _appVersion = 'unknown';
  String _buildNumber = 'unknown';

  /// Initialize the performance monitor service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get app info
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;

      _isInitialized = true;
      debugPrint('PerformanceMonitorService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize PerformanceMonitorService: $e');
    }
  }

  /// Start monitoring performance
  void startMonitoring() {
    if (_isMonitoring) return;

    // Start frame timing
    _ticker = Ticker(_onTick)..start();

    // Start memory monitoring
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _captureMemorySnapshot(),
    );

    _isMonitoring = true;
    debugPrint('Performance monitoring started');

    // Record start event
    _recordPerformanceEvent('monitoring_started', {
      'app_version': _appVersion,
      'build_number': _buildNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Stop monitoring performance
  void stopMonitoring() {
    if (!_isMonitoring) return;

    // Stop frame timing
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;

    // Stop memory monitoring
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;

    _isMonitoring = false;
    debugPrint('Performance monitoring stopped');

    // Record stop event
    _recordPerformanceEvent('monitoring_stopped', {
      'timestamp': DateTime.now().toIso8601String(),
      'average_fps': _averageFps,
      'worst_fps': _worstFps,
      'memory_snapshots_count': _memorySnapshots.length,
    });
  }

  /// Record a performance event
  void recordEvent(String eventName, Map<String, dynamic> data) {
    _recordPerformanceEvent(eventName, {
      ...data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Start tracking a specific operation
  String startOperation(String operationName) {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';

    _recordPerformanceEvent('operation_started', {
      'operation_id': operationId,
      'operation_name': operationName,
      'start_time': DateTime.now().toIso8601String(),
    });

    return operationId;
  }

  /// End tracking a specific operation
  void endOperation(String operationId, {bool success = true, String? errorMessage}) {
    _recordPerformanceEvent('operation_ended', {
      'operation_id': operationId,
      'end_time': DateTime.now().toIso8601String(),
      'success': success,
      'error_message': errorMessage,
    });
  }

  /// Get current performance metrics
  Map<String, dynamic> getCurrentMetrics() {
    return {
      'average_fps': _averageFps,
      'worst_fps': _worstFps,
      'memory_usage': _getLastMemorySnapshot(),
      'is_monitoring': _isMonitoring,
      'app_version': _appVersion,
      'build_number': _buildNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Save current performance report to storage
  Future<void> savePerformanceReport() async {
    final report = {
      'app_version': _appVersion,
      'build_number': _buildNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'average_fps': _averageFps,
      'worst_fps': _worstFps,
      'memory_snapshots': _memorySnapshots.take(10).toList(), // Only save the last 10 snapshots
      'events': _performanceEvents.take(100).toList(), // Only save the last 100 events
    };

    final reportId = 'performance_report_${DateTime.now().millisecondsSinceEpoch}';
    await _storageService.cacheData(reportId, report);

    debugPrint('Performance report saved with ID: $reportId');
  }

  /// Get all saved performance reports
  Future<List<Map<String, dynamic>>> getSavedReports() async {
    final reports = <Map<String, dynamic>>[];
    final keys = await _storageService.getAllKeys();

    for (final key in keys) {
      if (key.startsWith('cache_performance_report_')) {
        final reportData = await _storageService.getCachedData(key.replaceFirst('cache_', ''));
        if (reportData != null) {
          reports.add(reportData as Map<String, dynamic>);
        }
      }
    }

    // Sort by timestamp (newest first)
    reports.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp'] as String);
      final bTime = DateTime.parse(b['timestamp'] as String);
      return bTime.compareTo(aTime);
    });

    return reports;
  }

  /// Clear old performance reports
  Future<void> clearOldReports({int keepCount = 5}) async {
    final reports = await getSavedReports();

    if (reports.length <= keepCount) return;

    // Keep only the newest reports
    final reportsToDelete = reports.sublist(keepCount);

    // Clear cache for old reports
    if (reportsToDelete.isNotEmpty) {
      await _storageService.clearCache();
    }

    debugPrint('Cleared ${reportsToDelete.length} old performance reports');
  }

  // Private methods

  /// Handle ticker callback for frame timing
  void _onTick(Duration elapsed) {
    // Add current frame time
    _frameTimes.add(elapsed);

    // Keep only the last N frames
    if (_frameTimes.length > _maxFrameTimeCount) {
      _frameTimes.removeFirst();
    }

    // Calculate FPS if we have enough frames
    if (_frameTimes.length >= 2) {
      _calculateFps();
    }
  }

  /// Calculate FPS from frame times
  void _calculateFps() {
    if (_frameTimes.length < 2) return;

    final List<Duration> times = _frameTimes.toList();
    final List<double> frameRates = [];

    // Calculate frame rates
    for (int i = 1; i < times.length; i++) {
      final Duration frameDuration = times[i] - times[i - 1];
      if (frameDuration.inMicroseconds > 0) {
        final double fps = 1000000 / frameDuration.inMicroseconds;
        frameRates.add(fps);
      }
    }

    if (frameRates.isEmpty) return;

    // Calculate average FPS
    _averageFps = frameRates.reduce((a, b) => a + b) / frameRates.length;

    // Calculate worst FPS
    _worstFps = frameRates.reduce((a, b) => a < b ? a : b);

    // Log if FPS drops below threshold
    if (_worstFps < 30) {
      _recordPerformanceEvent('low_fps_detected', {
        'timestamp': DateTime.now().toIso8601String(),
        'fps': _worstFps,
        'average_fps': _averageFps,
      });
    }
  }

  /// Capture a memory snapshot
  Future<void> _captureMemorySnapshot() async {
    if (kIsWeb) {
      // Web doesn't support memory info
      return;
    }

    try {
      // Get memory info
      final memoryInfo = await _getMemoryInfo();

      // Add to snapshots
      _memorySnapshots.add({
        'timestamp': DateTime.now().toIso8601String(),
        ...memoryInfo,
      });

      // Keep only the last 60 snapshots (10 minutes at 10-second intervals)
      if (_memorySnapshots.length > 60) {
        _memorySnapshots.removeAt(0);
      }

      // Check for memory leaks
      _checkForMemoryLeaks();
    } catch (e) {
      debugPrint('Error capturing memory snapshot: $e');
    }
  }

  /// Get memory information
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // This is a simplified version - in a real app, you'd use platform channels
    // to get more detailed memory information

    return {
      'used_memory': 0, // Placeholder
      'total_memory': 0, // Placeholder
    };
  }

  /// Check for potential memory leaks
  void _checkForMemoryLeaks() {
    if (_memorySnapshots.length < 10) return;

    // Get the last 10 snapshots
    final recentSnapshots = _memorySnapshots.sublist(_memorySnapshots.length - 10);

    // Check if memory usage is consistently increasing
    bool isIncreasing = true;
    for (int i = 1; i < recentSnapshots.length; i++) {
      final current = recentSnapshots[i]['used_memory'] as int? ?? 0;
      final previous = recentSnapshots[i - 1]['used_memory'] as int? ?? 0;

      if (current <= previous) {
        isIncreasing = false;
        break;
      }
    }

    if (isIncreasing) {
      _recordPerformanceEvent('potential_memory_leak', {
        'timestamp': DateTime.now().toIso8601String(),
        'memory_trend': recentSnapshots.map((s) => s['used_memory']).toList(),
      });
    }
  }

  /// Get the last memory snapshot
  Map<String, dynamic> _getLastMemorySnapshot() {
    if (_memorySnapshots.isEmpty) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'used_memory': 0,
        'total_memory': 0,
      };
    }

    return _memorySnapshots.last;
  }

  /// Record a performance event
  void _recordPerformanceEvent(String eventName, Map<String, dynamic> data) {
    final event = {
      'event': eventName,
      ...data,
    };

    _performanceEvents.add(event);

    // Keep only the last 1000 events
    if (_performanceEvents.length > 1000) {
      _performanceEvents.removeAt(0);
    }

    // Log to analytics if it's an important event
    if (['low_fps_detected', 'potential_memory_leak'].contains(eventName)) {
      _storageService.logAnalyticsEvent(eventName, data);
    }
  }
}
