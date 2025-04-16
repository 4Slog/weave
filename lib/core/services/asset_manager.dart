import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kente_codeweaver/core/utils/memory_utils.dart';

/// Service for managing and optimizing asset loading
class AssetManager {
  // Singleton implementation
  static final AssetManager _instance = AssetManager._internal();

  factory AssetManager() {
    return _instance;
  }

  AssetManager._internal();

  // Cache for loaded assets
  final LRUCache<String, dynamic> _assetCache = LRUCache<String, dynamic>(
    maxSize: 100, // Cache up to 100 assets
  );

  // Cache for preloaded images
  final Map<String, ui.Image> _imageCache = {};

  // Cache for JSON data
  final Map<String, dynamic> _jsonCache = {};

  // Flag to track initialization
  bool _isInitialized = false;

  // Critical assets that should be preloaded
  final List<String> _criticalAssets = [];

  /// Initialize the asset manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Define critical assets that should be preloaded
      _criticalAssets.addAll([
        // Core UI assets
        'assets/images/navigation/home_breadcrumb.png',
        'assets/images/navigation/challenge_breadcrumb.png',
        'assets/images/navigation/story_breadcrumb.png',

        // Character assets
        'assets/images/characters/ananse.png',

        // Audio assets
        'assets/audio/main_theme.mp3',
        'assets/audio/button_tap.mp3',

        // Data assets
        'assets/data/blocks.json',
        'assets/data/challenges.json',
        'assets/data/stories.json',
        'assets/data/cultural_coding_mappings.json',
      ]);

      // Preload critical assets
      await preloadCriticalAssets();

      _isInitialized = true;
      debugPrint('AssetManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AssetManager: $e');
    }
  }

  /// Preload critical assets
  Future<void> preloadCriticalAssets() async {
    final futures = <Future>[];

    for (final assetPath in _criticalAssets) {
      if (assetPath.endsWith('.png') || assetPath.endsWith('.jpg')) {
        futures.add(preloadImage(assetPath));
      } else if (assetPath.endsWith('.json')) {
        futures.add(loadJson(assetPath));
      }
    }

    await Future.wait(futures);
    debugPrint('Preloaded ${futures.length} critical assets');
  }

  /// Load an asset based on its type
  Future<dynamic> loadAsset(String path) async {
    // Check cache first
    final cachedAsset = _assetCache.get(path);
    if (cachedAsset != null) {
      return cachedAsset;
    }

    // Load based on file extension
    dynamic asset;
    if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      asset = await loadImage(path);
    } else if (path.endsWith('.json')) {
      asset = await loadJson(path);
    } else if (path.endsWith('.mp3') || path.endsWith('.wav')) {
      asset = path; // For audio, just return the path
    } else {
      // For other types, load as bytes
      asset = await rootBundle.load(path);
    }

    // Cache for future use
    _assetCache.put(path, asset);

    return asset;
  }

  /// Load an image asset
  Future<ui.Image> loadImage(String path) async {
    // Check image cache first
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    // Load image
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: null, // Use original size
      targetHeight: null, // Use original size
    );
    final frame = await codec.getNextFrame();

    // Cache image
    _imageCache[path] = frame.image;

    return frame.image;
  }

  /// Preload an image asset
  Future<void> preloadImage(String path) async {
    try {
      final image = await loadImage(path);
      _imageCache[path] = image;
    } catch (e) {
      debugPrint('Error preloading image $path: $e');
    }
  }

  /// Load a JSON asset
  Future<dynamic> loadJson(String path) async {
    // Check JSON cache first
    if (_jsonCache.containsKey(path)) {
      return _jsonCache[path];
    }

    // Load JSON
    final jsonString = await rootBundle.loadString(path);
    final jsonData = jsonDecode(jsonString);

    // Cache JSON
    _jsonCache[path] = jsonData;

    return jsonData;
  }

  /// Load a network image with caching
  Future<ui.Image> loadNetworkImage(String url) async {
    // Use flutter_cache_manager to handle caching
    final file = await DefaultCacheManager().getSingleFile(url);
    final bytes = await file.readAsBytes();

    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
      targetWidth: null, // Use original size
      targetHeight: null, // Use original size
    );
    final frame = await codec.getNextFrame();

    return frame.image;
  }

  /// Load a network image with resizing
  Future<ui.Image> loadResizedNetworkImage(
    String url, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    // Use flutter_cache_manager to handle caching
    final file = await DefaultCacheManager().getSingleFile(url);
    final bytes = await file.readAsBytes();

    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();

    return frame.image;
  }

  /// Clear the asset cache
  void clearCache() {
    _assetCache.clear();

    // Dispose image resources
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();

    _jsonCache.clear();

    debugPrint('Asset cache cleared');
  }

  /// Clear specific assets from the cache
  void clearAssets(List<String> paths) {
    for (final path in paths) {
      _assetCache.remove(path);

      if (_imageCache.containsKey(path)) {
        _imageCache[path]!.dispose();
        _imageCache.remove(path);
      }

      _jsonCache.remove(path);
    }
  }

  /// Get the size of the asset cache
  int get cacheSize => _assetCache.size + _imageCache.length + _jsonCache.length;

  /// Check if an asset is cached
  bool isAssetCached(String path) {
    return _assetCache.containsKey(path) ||
           _imageCache.containsKey(path) ||
           _jsonCache.containsKey(path);
  }

  /// Optimize memory usage by clearing non-critical assets
  void optimizeMemoryUsage() {
    // Keep critical assets
    final assetsToKeep = Set<String>.from(_criticalAssets);

    // Clear non-critical assets from image cache
    final imagesToRemove = <String>[];
    for (final path in _imageCache.keys) {
      if (!assetsToKeep.contains(path)) {
        imagesToRemove.add(path);
      }
    }

    for (final path in imagesToRemove) {
      _imageCache[path]!.dispose();
      _imageCache.remove(path);
    }

    // Clear non-critical assets from JSON cache
    final jsonToRemove = <String>[];
    for (final path in _jsonCache.keys) {
      if (!assetsToKeep.contains(path)) {
        jsonToRemove.add(path);
      }
    }

    for (final path in jsonToRemove) {
      _jsonCache.remove(path);
    }

    // Clear non-critical assets from general cache
    final assetsToRemove = <String>[];
    for (final path in _assetCache.keys) {
      if (!assetsToKeep.contains(path)) {
        assetsToRemove.add(path);
      }
    }

    for (final path in assetsToRemove) {
      _assetCache.remove(path);
    }

    debugPrint('Memory optimization complete. Removed ${imagesToRemove.length} images, ${jsonToRemove.length} JSON files, and ${assetsToRemove.length} other assets.');
  }

  /// Save a file to the local file system
  Future<String> saveFile(String filename, List<int> bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  /// Load a file from the local file system
  Future<Uint8List> loadFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error loading file: $e');
      rethrow;
    }
  }

  /// Check if a file exists in the local file system
  Future<bool> fileExists(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';
      final file = File(path);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking if file exists: $e');
      return false;
    }
  }

  /// Delete a file from the local file system
  Future<bool> deleteFile(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$filename';
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
