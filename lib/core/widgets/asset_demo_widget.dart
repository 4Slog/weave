import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';
import 'package:kente_codeweaver/core/widgets/optimized_image.dart';
import 'package:kente_codeweaver/features/blocks/services/block_asset_service.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_asset_service.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_asset_service.dart';

/// A widget that demonstrates how to use the asset services
class AssetDemoWidget extends StatefulWidget {
  const AssetDemoWidget({super.key});

  @override
  State<AssetDemoWidget> createState() => _AssetDemoWidgetState();
}

class _AssetDemoWidgetState extends State<AssetDemoWidget> {
  // Services
  late final AudioService _audioService;
  late final CulturalAssetService _culturalAssetService;
  late final BlockAssetService _blockAssetService;
  late final StoryAssetService _storyAssetService;
  
  // State
  String _selectedCategory = 'patterns';
  List<String> _assetPaths = [];
  
  @override
  void initState() {
    super.initState();
    
    // Get services
    _audioService = ServiceProvider.get<AudioService>();
    _culturalAssetService = ServiceProvider.get<CulturalAssetService>();
    _blockAssetService = ServiceProvider.get<BlockAssetService>();
    _storyAssetService = ServiceProvider.get<StoryAssetService>();
    
    // Load initial assets
    _loadAssets();
  }
  
  /// Load assets based on selected category
  void _loadAssets() {
    setState(() {
      _assetPaths = [];
    });
    
    switch (_selectedCategory) {
      case 'patterns':
        // Preload cultural assets
        _culturalAssetService.preloadAllPatternImages();
        
        // Get pattern image paths
        setState(() {
          _assetPaths = [
            'assets/images/patterns/checker_pattern.png',
            'assets/images/patterns/diamonds_pattern.png',
            'assets/images/patterns/square_pattern.png',
            'assets/images/patterns/stripes_horizontal_pattern.png',
            'assets/images/patterns/stripes_vertical_pattern.png',
            'assets/images/patterns/zigzag_pattern.png',
          ];
        });
        break;
        
      case 'blocks':
        // Get block image paths
        final blockDefinitions = _blockAssetService.getAllBlockDefinitions();
        setState(() {
          _assetPaths = blockDefinitions
              .where((block) => block.iconPath != null)
              .map((block) => block.iconPath!)
              .toList();
        });
        break;
        
      case 'characters':
        // Get character image paths
        setState(() {
          _assetPaths = [
            'assets/images/characters/ananse.png',
            'assets/images/characters/ananse_explaining.png',
            'assets/images/characters/ananse_teaching.png',
          ];
        });
        break;
        
      case 'achievements':
        // Get achievement image paths
        setState(() {
          _assetPaths = [
            'assets/images/achievements/advanced_weaver.png',
            'assets/images/achievements/challenge_master.png',
            'assets/images/achievements/Cultural Explorer.png',
            'assets/images/achievements/first_pattern.png',
            'assets/images/achievements/learning_journey.png',
            'assets/images/achievements/pattern_creator.png',
            'assets/images/achievements/story_complete.png',
            'assets/images/achievements/streak_master.png',
          ];
        });
        break;
    }
  }
  
  /// Play sound effect
  void _playSound(AudioType type) {
    _audioService.playEffect(type);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _categoryButton('Patterns', 'patterns'),
              _categoryButton('Blocks', 'blocks'),
              _categoryButton('Characters', 'characters'),
              _categoryButton('Achievements', 'achievements'),
            ],
          ),
        ),
        
        // Asset grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            itemCount: _assetPaths.length,
            itemBuilder: (context, index) {
              final path = _assetPaths[index];
              return _buildAssetTile(path);
            },
          ),
        ),
      ],
    );
  }
  
  /// Build a category button
  Widget _categoryButton(String label, String category) {
    final isSelected = _selectedCategory == category;
    
    return ElevatedButton(
      onPressed: () {
        _playSound(AudioType.buttonTap);
        setState(() {
          _selectedCategory = category;
        });
        _loadAssets();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      child: Text(label),
    );
  }
  
  /// Build an asset tile
  Widget _buildAssetTile(String path) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          _playSound(AudioType.navigationTap);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image
              Expanded(
                child: OptimizedImage(
                  imagePath: path,
                  fit: BoxFit.contain,
                  preload: true,
                  featureContext: _selectedCategory == 'patterns' ? 'cultural' : 
                                 _selectedCategory == 'blocks' ? 'block_workspace' :
                                 _selectedCategory == 'characters' ? 'story' : 'achievement',
                ),
              ),
              
              // Label
              const SizedBox(height: 8.0),
              Text(
                _getAssetName(path),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get asset name from path
  String _getAssetName(String path) {
    // Extract filename without extension
    final filename = path.split('/').last.split('.').first;
    
    // Convert snake_case to Title Case
    return filename
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
