import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kente_codeweaver/core/services/asset_manager.dart';
import 'package:kente_codeweaver/core/services/performance_monitor_service.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// Service for optimized asset loading and caching
class OptimizedAssetLoader {
  // Singleton implementation
  static final OptimizedAssetLoader _instance = OptimizedAssetLoader._internal();

  factory OptimizedAssetLoader() {
    return _instance;
  }

  OptimizedAssetLoader._internal();

  // Dependencies
  late final AssetManager _assetManager;
  late final PerformanceMonitorService _performanceService;

  // Initialization state
  bool _isInitialized = false;

  // Asset loading queue
  final Map<String, Completer<dynamic>> _loadingQueue = {};

  // Asset preloading state
  bool _isPreloading = false;
  final List<String> _preloadQueue = [];

  /// Initialize the optimized asset loader
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get dependencies
      _assetManager = ServiceProvider.get<AssetManager>();
      _performanceService = ServiceProvider.get<PerformanceMonitorService>();

      _isInitialized = true;
      debugPrint('OptimizedAssetLoader initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OptimizedAssetLoader: $e');
    }
  }

  /// Load an image with optimized caching
  Future<ui.Image> loadImage(String path, {int? targetWidth, int? targetHeight}) async {
    await _ensureInitialized();

    // Start performance tracking
    final operationId = _performanceService.startOperation('load_image');

    try {
      // Check if already loading
      if (_loadingQueue.containsKey(path)) {
        final result = await _loadingQueue[path]!.future;
        _performanceService.endOperation(operationId, success: true);
        return result as ui.Image;
      }

      // Create completer for this load operation
      final completer = Completer<ui.Image>();
      _loadingQueue[path] = completer;

      // Load image
      ui.Image image;
      if (path.startsWith('http')) {
        // Network image
        image = await _assetManager.loadNetworkImage(path);
      } else {
        // Asset image
        image = await _assetManager.loadImage(path);
      }

      // Complete the operation
      completer.complete(image);
      _loadingQueue.remove(path);

      _performanceService.endOperation(operationId, success: true);
      return image;
    } catch (e) {
      _performanceService.endOperation(operationId, success: false, errorMessage: e.toString());
      _loadingQueue.remove(path);
      rethrow;
    }
  }

  /// Load an image with downsampling for memory efficiency
  Future<ui.Image> loadDownsampledImage(String path, {required int targetWidth, required int targetHeight}) async {
    await _ensureInitialized();

    // Start performance tracking
    final operationId = _performanceService.startOperation('load_downsampled_image');

    try {
      // Check if already loading
      final cacheKey = '${path}_${targetWidth}x$targetHeight';
      if (_loadingQueue.containsKey(cacheKey)) {
        final result = await _loadingQueue[cacheKey]!.future;
        _performanceService.endOperation(operationId, success: true);
        return result as ui.Image;
      }

      // Create completer for this load operation
      final completer = Completer<ui.Image>();
      _loadingQueue[cacheKey] = completer;

      // Load image with downsampling
      ui.Image image;
      if (path.startsWith('http')) {
        // Network image
        image = await _assetManager.loadResizedNetworkImage(
          path,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
      } else {
        // Asset image
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        final frame = await codec.getNextFrame();
        image = frame.image;
      }

      // Complete the operation
      completer.complete(image);
      _loadingQueue.remove(cacheKey);

      _performanceService.endOperation(operationId, success: true);
      return image;
    } catch (e) {
      _performanceService.endOperation(operationId, success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Load a JSON asset with caching
  Future<dynamic> loadJson(String path) async {
    await _ensureInitialized();

    // Start performance tracking
    final operationId = _performanceService.startOperation('load_json');

    try {
      // Load JSON
      final jsonData = await _assetManager.loadJson(path);

      _performanceService.endOperation(operationId, success: true);
      return jsonData;
    } catch (e) {
      _performanceService.endOperation(operationId, success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Preload a list of assets
  Future<void> preloadAssets(List<String> assetPaths) async {
    await _ensureInitialized();

    // If already preloading, add to queue
    if (_isPreloading) {
      _preloadQueue.addAll(assetPaths);
      return;
    }

    _isPreloading = true;

    try {
      // Start performance tracking
      final operationId = _performanceService.startOperation('preload_assets');

      // Add initial paths to queue
      _preloadQueue.addAll(assetPaths);

      // Process queue
      while (_preloadQueue.isNotEmpty) {
        final batch = _preloadQueue.take(5).toList(); // Process in batches of 5
        _preloadQueue.removeRange(0, batch.length);

        // Load assets in parallel
        await Future.wait(batch.map((path) async {
          try {
            if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg')) {
              await _assetManager.preloadImage(path);
            } else if (path.endsWith('.json')) {
              await _assetManager.loadJson(path);
            }
          } catch (e) {
            debugPrint('Error preloading asset $path: $e');
          }
        }));
      }

      _performanceService.endOperation(operationId, success: true);
    } catch (e) {
      debugPrint('Error during asset preloading: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload assets for a specific screen or feature
  Future<void> preloadAssetsForFeature(String featureName) async {
    await _ensureInitialized();

    // Define assets to preload for each feature
    final Map<String, List<String>> featureAssets = {
      'story': [
        // Story images
        'assets/images/characters/ananse.png',
        'assets/images/characters/ananse_explaining.png',
        'assets/images/characters/ananse_teaching.png',
        'assets/images/story/background_pattern.png',

        // Story navigation
        'assets/images/navigation/story_breadcrumb.png',

        // Story audio
        'assets/audio/main_theme.mp3',
        'assets/audio/button_tap.mp3',

        // Story data
        'assets/data/stories.json',
      ],

      'block_workspace': [
        // Block images
        'assets/images/blocks/column_icon.png',
        'assets/images/blocks/loop_icon.png',
        'assets/images/blocks/row_icon.png',
        'assets/images/blocks/shuttle_black.png',
        'assets/images/blocks/shuttle_blue.png',
        'assets/images/blocks/shuttle_gold.png',

        // Block navigation
        'assets/images/navigation/challenge_breadcrumb.png',
        'assets/images/navigation/weaving_breadcrumb.png',

        // Block audio
        'assets/audio/challenge_theme.mp3',
        'assets/audio/button_tap.mp3',

        // Block data
        'assets/data/blocks.json',
      ],

      'challenge': [
        // Challenge images
        'assets/images/blocks/tutorial_intro.png',
        'assets/images/tutorial/basic_pattern_explanation.png',
        'assets/images/tutorial/color_meaning_diagram.png',
        'assets/images/tutorial/loop_explanation.png',

        // Challenge navigation
        'assets/images/navigation/challenge_breadcrumb.png',

        // Challenge audio
        'assets/audio/challenge_theme.mp3',
        'assets/audio/success.mp3',
        'assets/audio/failure..mp3',

        // Challenge data
        'assets/data/challenges.json',
      ],

      'cultural': [
        // Cultural images
        'assets/images/patterns/checker_pattern.png',
        'assets/images/patterns/diamonds_pattern.png',
        'assets/images/patterns/square_pattern.png',
        'assets/images/patterns/stripes_horizontal_pattern.png',
        'assets/images/patterns/stripes_vertical_pattern.png',
        'assets/images/patterns/zigzag_pattern.png',

        // Cultural data
        'assets/data/colors_cultural_info.json',
        'assets/data/patterns_cultural_info.json',
        'assets/data/symbols_cultural_info.json',
        'assets/data/cultural_coding_mappings.json',
        'assets/data/regional_info.json',
      ],

      'achievement': [
        // Achievement images
        'assets/images/achievements/advanced_weaver.png',
        'assets/images/achievements/challenge_master.png',
        'assets/images/achievements/Cultural Explorer.png',
        'assets/images/achievements/first_pattern.png',
        'assets/images/achievements/learning_journey.png',
        'assets/images/achievements/pattern_creator.png',
        'assets/images/achievements/story_complete.png',
        'assets/images/achievements/streak_master.png',

        // Achievement navigation
        'assets/images/navigation/achievement_breadcrumb.png',

        // Achievement audio
        'assets/audio/achievement.mp3',
        'assets/audio/success.mp3',
      ],

      'home': [
        // Home navigation
        'assets/images/navigation/home_breadcrumb.png',
        'assets/images/navigation/background_pattern.png',

        // Home audio
        'assets/audio/main_theme.mp3',
        'assets/audio/button_tap.mp3',
      ],
    };

    // Preload assets for the requested feature
    if (featureAssets.containsKey(featureName)) {
      await preloadAssets(featureAssets[featureName]!);
    }
  }

  /// Optimize memory usage by clearing non-essential assets
  Future<void> optimizeMemoryUsage() async {
    await _ensureInitialized();

    // Start performance tracking
    final operationId = _performanceService.startOperation('optimize_memory');

    try {
      // Delegate to asset manager
      _assetManager.optimizeMemoryUsage();

      _performanceService.endOperation(operationId, success: true);
    } catch (e) {
      _performanceService.endOperation(operationId, success: false, errorMessage: e.toString());
      debugPrint('Error optimizing memory usage: $e');
    }
  }

  /// Clear all cached assets
  Future<void> clearCache() async {
    await _ensureInitialized();

    // Clear asset manager cache
    _assetManager.clearCache();

    // Clear network image cache
    await DefaultCacheManager().emptyCache();
  }

  // Helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
