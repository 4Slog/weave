import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/content_block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/services/tts_service.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:provider/provider.dart';

/// Screen that displays a story and its content blocks
class StoryScreen extends StatefulWidget {
  const StoryScreen({Key? key}) : super(key: key);

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TTSService _ttsService = TTSService();
  bool _isSpeaking = false;
  int _currentBlockIndex = 0;
  
  @override
  void dispose() {
    _stopSpeech();
    super.dispose();
  }
  
  /// Stop text-to-speech when navigating away
  void _stopSpeech() {
    if (_isSpeaking) {
      _ttsService.stop();
      setState(() {
        _isSpeaking = false;
      });
    }
  }
  
  /// Begin text-to-speech for the current block
  void _startSpeech(String text) {
    _ttsService.speak(text).then((_) {
      // When speaking finishes, update state
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
    
    setState(() {
      _isSpeaking = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get story from route arguments
    final StoryModel story = ModalRoute.of(context)!.settings.arguments as StoryModel;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Story: ${story.title}'),
        actions: [
          // TTS control button
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              if (_isSpeaking) {
                _stopSpeech();
              } else {
                _startSpeech(_getCurrentBlockText(story));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Difficulty badge
          _buildDifficultyBadge(story),
          
          // Story content
          Expanded(
            child: _buildStoryContent(story),
          ),
          
          // Navigation buttons
          _buildNavigationControls(story),
          
          // Challenge button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                _prepareAndNavigateToChallenge(story);
              },
              child: const Text('Start Coding Challenge'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get text of current content block or empty string if none
  String _getCurrentBlockText(StoryModel story) {
    if (story.content.isEmpty || _currentBlockIndex >= story.content.length) {
      return '';
    }
    
    final contentBlock = story.content[_currentBlockIndex];
    if (contentBlock is ContentBlock) {
      return contentBlock.text;
    } else if (contentBlock is Map) {
      return contentBlock['text'] ?? '';
    }
    
    return '';
  }
  
  /// Build a difficulty badge widget
  Widget _buildDifficultyBadge(StoryModel story) {
    final difficulty = story.metadata?['difficultyLevel'] ?? 'Basic';
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getDifficultyColor(difficulty),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        'Difficulty: $difficulty',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Get color based on difficulty
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'basic':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
  
  /// Build the story content section
  Widget _buildStoryContent(StoryModel story) {
    if (story.content.isEmpty) {
      return const Center(
        child: Text('This story has no content yet.'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildContentBlocks(story),
      ),
    );
  }
  
  /// Build content block widgets from story
  List<Widget> _buildContentBlocks(StoryModel story) {
    final List<Widget> contentWidgets = [];
    
    for (int i = 0; i < story.content.length; i++) {
      final contentBlock = story.content[i];
      final bool isActive = i == _currentBlockIndex;
      
      if (contentBlock is ContentBlock) {
        contentWidgets.add(_buildContentBlockWidget(contentBlock, isActive));
      } else if (contentBlock is Map) {
        contentWidgets.add(_buildContentBlockFromMap(contentBlock, isActive));
      }
    }
    
    return contentWidgets;
  }
  
  /// Build a widget for a ContentBlock
  Widget _buildContentBlockWidget(ContentBlock block, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: isActive ? Border.all(color: Theme.of(context).primaryColor, width: 2.0) : null,
        borderRadius: BorderRadius.circular(8.0),
        color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      ),
      child: Text(
        block.text,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  /// Build a widget from a Map content block
  Widget _buildContentBlockFromMap(Map block, bool isActive) {
    final String text = block['text'] ?? 'No text content';
    final String? type = block['type'];
    
    // Handle different block types (text, image, etc)
    if (type == 'image' && block['url'] != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          border: isActive ? Border.all(color: Theme.of(context).primaryColor, width: 2.0) : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              block['url'],
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 100),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  text,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      );
    }
    
    // Default to text block
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: isActive ? Border.all(color: Theme.of(context).primaryColor, width: 2.0) : null,
        borderRadius: BorderRadius.circular(8.0),
        color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  /// Build navigation controls for content blocks
  Widget _buildNavigationControls(StoryModel story) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentBlockIndex > 0
              ? () {
                  setState(() {
                    _currentBlockIndex--;
                  });
                }
              : null,
        ),
        Text('${_currentBlockIndex + 1} of ${story.content.length}'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentBlockIndex < story.content.length - 1
              ? () {
                  setState(() {
                    _currentBlockIndex++;
                  });
                }
              : null,
        ),
      ],
    );
  }
  
  /// Prepare block types and navigate to challenge
  void _prepareAndNavigateToChallenge(StoryModel story) {
    // Get the blocks required for this story's challenge
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // Extract required block types from story metadata
    final List<BlockType> requiredBlockTypes = _getRequiredBlockTypes(story);
    
    // Set available block types in provider
    blockProvider.setAvailableBlockTypes(requiredBlockTypes);
    
    // Navigate to challenge
    Navigator.pushNamed(context, '/challenge', arguments: story);
  }
  
  /// Get required block types from story metadata
  List<BlockType> _getRequiredBlockTypes(StoryModel story) {
    final List<BlockType> blockTypes = [];
    
    // Try to get block types from metadata
    if (story.metadata != null && story.metadata!.containsKey('requiredBlockTypes')) {
      final dynamic requiredTypes = story.metadata!['requiredBlockTypes'];
      
      if (requiredTypes is List) {
        for (final dynamic typeItem in requiredTypes) {
          if (typeItem is String) {
            try {
              // Convert string to enum
              final blockType = BlockType.values.firstWhere(
                (type) => type.toString().split('.').last.toLowerCase() == typeItem.toLowerCase(),
                orElse: () => BlockType.pattern,
              );
              blockTypes.add(blockType);
            } catch (e) {
              debugPrint('Error parsing block type: $e');
            }
          }
        }
      }
    }
    
    // If no block types found, use defaults
    if (blockTypes.isEmpty) {
      blockTypes.addAll([
        BlockType.pattern,
        BlockType.color,
        BlockType.structure,
        BlockType.loop,
      ]);
    }
    
    return blockTypes;
  }
}