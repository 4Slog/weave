import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kente_codeweaver/core/services/asset_manager.dart';
import 'package:kente_codeweaver/core/services/enhanced_storage_service.dart';
import 'package:kente_codeweaver/core/services/performance_monitor_service.dart';
import 'package:kente_codeweaver/core/services/synchronization_service.dart';
import 'package:kente_codeweaver/core/services/ai_content_manager.dart';
import 'package:kente_codeweaver/core/services/optimized_asset_loader.dart';
import 'package:kente_codeweaver/core/services/offline_mode_handler.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';
import 'package:kente_codeweaver/core/utils/connectivity_utils.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_asset_service.dart';
import 'package:kente_codeweaver/features/blocks/services/block_asset_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_asset_service.dart';

/// Service provider for dependency injection
class ServiceProvider {
  // GetIt instance
  static final GetIt _getIt = GetIt.instance;

  // Flag to track initialization
  static bool _isInitialized = false;

  /// Initialize all services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register services
      _registerServices();

      // Initialize services
      await _initializeServices();

      _isInitialized = true;
      debugPrint('ServiceProvider initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ServiceProvider: $e');
    }
  }

  /// Register services with GetIt
  static void _registerServices() {
    // Register core services
    _getIt.registerSingleton<EnhancedStorageService>(EnhancedStorageService());
    _getIt.registerSingleton<AssetManager>(AssetManager());
    _getIt.registerSingleton<PerformanceMonitorService>(PerformanceMonitorService());
    _getIt.registerSingleton<SynchronizationService>(SynchronizationService());

    // Register performance optimization services
    _getIt.registerSingleton<AIContentManager>(AIContentManager());
    _getIt.registerSingleton<OptimizedAssetLoader>(OptimizedAssetLoader());
    _getIt.registerSingleton<OfflineModeHandler>(OfflineModeHandler());

    // Register asset services
    _getIt.registerSingleton<AudioService>(AudioService());
    _getIt.registerSingleton<CulturalAssetService>(CulturalAssetService());
    _getIt.registerSingleton<BlockAssetService>(BlockAssetService());
    _getIt.registerSingleton<StoryAssetService>(StoryAssetService());

    // Register utilities
    _getIt.registerSingleton<ConnectivityUtils>(ConnectivityUtils());

    debugPrint('Services registered');
  }

  /// Initialize registered services
  static Future<void> _initializeServices() async {
    // Initialize services in order
    await _getIt<EnhancedStorageService>().initialize();
    await _getIt<AssetManager>().initialize();
    await _getIt<PerformanceMonitorService>().initialize();
    _getIt<ConnectivityUtils>().initialize();

    // Initialize performance optimization services
    await _getIt<AIContentManager>().initialize();
    await _getIt<OptimizedAssetLoader>().initialize();
    await _getIt<SynchronizationService>().initialize();
    await _getIt<OfflineModeHandler>().initialize();

    // Initialize asset services
    await _getIt<AudioService>().initialize();
    await _getIt<CulturalAssetService>().initialize();
    await _getIt<BlockAssetService>().initialize();
    await _getIt<StoryAssetService>().initialize();

    // Start performance monitoring in non-debug mode
    if (!kDebugMode) {
      _getIt<PerformanceMonitorService>().startMonitoring();
    }

    // Prepare for offline mode
    await _getIt<OfflineModeHandler>().prepareForOfflineMode();

    debugPrint('Services initialized');
  }

  /// Get a registered service
  static T get<T extends Object>() {
    return _getIt<T>();
  }

  /// Check if the service provider is initialized
  static bool get isInitialized => _isInitialized;
}
