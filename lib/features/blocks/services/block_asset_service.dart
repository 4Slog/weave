import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/optimized_asset_loader.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// Block definition model
class BlockDefinition {
  final String id;
  final String name;
  final String description;
  final String type;
  final String subtype;
  final Map<String, dynamic> properties;
  final String? iconPath;
  final String color;
  
  BlockDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.subtype,
    required this.properties,
    this.iconPath,
    required this.color,
  });
  
  factory BlockDefinition.fromJson(Map<String, dynamic> json) {
    return BlockDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      subtype: json['subtype'] as String,
      properties: json['properties'] as Map<String, dynamic>,
      iconPath: json['iconPath'] as String?,
      color: json['color'] as String,
    );
  }
}

/// Service for managing block assets
class BlockAssetService {
  // Singleton implementation
  static final BlockAssetService _instance = BlockAssetService._internal();

  factory BlockAssetService() {
    return _instance;
  }

  BlockAssetService._internal();
  
  // Dependencies
  late final OptimizedAssetLoader _assetLoader;
  
  // Cache for block data
  List<BlockDefinition>? _blockDefinitions;
  Map<String, dynamic>? _rawBlockData;
  
  // Initialization state
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get dependencies
      _assetLoader = ServiceProvider.get<OptimizedAssetLoader>();
      
      // Load block definitions
      await _loadBlockDefinitions();
      
      // Preload block images
      await _preloadBlockImages();
      
      _isInitialized = true;
      debugPrint('BlockAssetService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BlockAssetService: $e');
    }
  }
  
  /// Load block definitions
  Future<void> _loadBlockDefinitions() async {
    final data = await _assetLoader.loadJson('assets/data/blocks.json');
    _rawBlockData = data;
    
    final blocks = data['blocks'] as List<dynamic>;
    _blockDefinitions = blocks.map((block) => BlockDefinition.fromJson(block as Map<String, dynamic>)).toList();
  }
  
  /// Preload block images
  Future<void> _preloadBlockImages() async {
    if (_blockDefinitions == null) return;
    
    final imagePaths = _blockDefinitions!
        .where((block) => block.iconPath != null)
        .map((block) => block.iconPath!)
        .toList();
    
    // Preload in parallel
    await Future.wait(
      imagePaths.map((path) => _assetLoader.loadImage(path))
    );
  }
  
  /// Get block definition by ID
  BlockDefinition? getBlockDefinition(String blockId) {
    if (_blockDefinitions == null) return null;
    
    try {
      return _blockDefinitions!.firstWhere((block) => block.id == blockId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all block definitions
  List<BlockDefinition> getAllBlockDefinitions() {
    return _blockDefinitions ?? [];
  }
  
  /// Get block definitions by type
  List<BlockDefinition> getBlockDefinitionsByType(String type) {
    if (_blockDefinitions == null) return [];
    
    return _blockDefinitions!.where((block) => block.type == type).toList();
  }
  
  /// Get block icon path
  String? getBlockIconPath(String blockId) {
    final definition = getBlockDefinition(blockId);
    return definition?.iconPath;
  }
  
  /// Get difficulty levels
  List<Map<String, dynamic>> getDifficultyLevels() {
    if (_rawBlockData == null) return [];
    
    return List<Map<String, dynamic>>.from(
      (_rawBlockData!['difficultyLevels'] as List<dynamic>)
        .map((level) => level as Map<String, dynamic>)
    );
  }
  
  /// Get blocks for difficulty level
  List<String> getBlocksForDifficultyLevel(String difficultyId) {
    if (_rawBlockData == null) return [];
    
    final difficultyLevels = _rawBlockData!['difficultyLevels'] as List<dynamic>;
    
    try {
      final difficultyLevel = difficultyLevels.firstWhere(
        (level) => level['id'] == difficultyId,
      ) as Map<String, dynamic>;
      
      return List<String>.from(difficultyLevel['availableBlocks'] as List<dynamic>);
    } catch (e) {
      return [];
    }
  }
  
  /// Get pattern definitions
  List<Map<String, dynamic>> getPatternDefinitions() {
    if (_rawBlockData == null) return [];
    
    return List<Map<String, dynamic>>.from(
      (_rawBlockData!['patterns'] as List<dynamic>)
        .map((pattern) => pattern as Map<String, dynamic>)
    );
  }
  
  /// Get color definitions
  List<Map<String, dynamic>> getColorDefinitions() {
    if (_rawBlockData == null) return [];
    
    return List<Map<String, dynamic>>.from(
      (_rawBlockData!['colors'] as List<dynamic>)
        .map((color) => color as Map<String, dynamic>)
    );
  }
}
