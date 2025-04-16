import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/performance_monitor_service.dart';
import 'package:kente_codeweaver/core/services/enhanced_storage_service.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// A widget that displays performance metrics in debug mode
class PerformanceOverlayWidget extends StatefulWidget {
  /// The child widget
  final Widget child;
  
  /// Whether to show the overlay
  final bool showOverlay;
  
  /// Create a new performance overlay widget
  const PerformanceOverlayWidget({
    Key? key,
    required this.child,
    this.showOverlay = kDebugMode,
  }) : super(key: key);

  @override
  State<PerformanceOverlayWidget> createState() => _PerformanceOverlayWidgetState();
}

class _PerformanceOverlayWidgetState extends State<PerformanceOverlayWidget> {
  // Services
  late final PerformanceMonitorService _performanceService;
  late final EnhancedStorageService _storageService;
  
  // Performance metrics
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _cacheStats = {};
  
  // Update timer
  Timer? _updateTimer;
  
  // Visibility state
  bool _isVisible = false;
  
  @override
  void initState() {
    super.initState();
    
    // Get services
    _performanceService = ServiceProvider.get<PerformanceMonitorService>();
    _storageService = ServiceProvider.get<EnhancedStorageService>();
    
    // Start performance monitoring
    _performanceService.startMonitoring();
    
    // Update metrics periodically
    _updateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updateMetrics(),
    );
    
    // Initial update
    _updateMetrics();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  /// Update performance metrics
  void _updateMetrics() {
    if (!mounted) return;
    
    setState(() {
      _performanceMetrics = _performanceService.getCurrentMetrics();
      _cacheStats = _storageService.getCacheStats();
    });
  }
  
  /// Toggle visibility
  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // If not showing overlay, just return the child
    if (!widget.showOverlay) {
      return widget.child;
    }
    
    return Stack(
      children: [
        // Child widget
        widget.child,
        
        // Performance overlay toggle button
        Positioned(
          top: 40,
          right: 10,
          child: SafeArea(
            child: GestureDetector(
              onTap: _toggleVisibility,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        
        // Performance overlay
        if (_isVisible)
          Positioned(
            top: 90,
            right: 10,
            child: SafeArea(
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildMetricRow('FPS', '${(_performanceMetrics['average_fps'] ?? 0).toStringAsFixed(1)}'),
                    _buildMetricRow('Memory', '${(_cacheStats['current_cache_size_bytes'] ?? 0) ~/ 1024 ~/ 1024} MB'),
                    _buildMetricRow('Cache Hit', '${_cacheStats['hit_ratio_percent'] ?? 0}%'),
                    _buildMetricRow('Cache Size', '${_cacheStats['cache_utilization_percent'] ?? 0}%'),
                    
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _performanceService.savePerformanceReport();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Performance report saved'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Save Report', style: TextStyle(fontSize: 10)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _storageService.clearCache();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache cleared'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Clear Cache', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build a metric row
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
