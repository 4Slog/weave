import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/core/services/tts_service.dart';
import 'package:kente_codeweaver/features/engagement/services/engagement_service.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/features/badges/providers/badge_provider.dart';
import 'package:kente_codeweaver/features/badges/widgets/badge_display_widget.dart';
import 'package:kente_codeweaver/features/storytelling/widgets/detailed_narrative_choice_widget.dart';
import 'package:provider/provider.dart';

/// Enhanced screen that displays a story with branching narratives,
/// emotional TTS, engagement tracking, and badge display
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  // Using engagement service for tracking user interactions
  final EngagementService _engagementService = EngagementService();
  final AudioService _audioService = AudioService();

  bool _isSpeaking = false;
  int _currentBlockIndex = 0;
  bool _showBranches = false;
  bool _showBadges = false;
  bool _isInitialized = false;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Initialize TTS service
    _initializeTTS();
  }

  /// Initialize TTS service
  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _stopSpeech();
    _animationController.dispose();
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

  /// Begin text-to-speech for the current block with emotional tone
  void _startSpeech(String text, {EmotionalTone tone = EmotionalTone.neutral}) {
    if (!_isInitialized) return;

    _ttsService.speak(text, tone: tone).then((_) {
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

    // Track engagement
    _engagementService.recordInteraction('tts_usage');
  }

  /// Speak the current content block with appropriate emotional tone
  void _speakCurrentBlock(StoryModel story) {
    if (story.content.isEmpty || _currentBlockIndex >= story.content.length) {
      return;
    }

    // Get the current block's text and tone
    final String text = _getCurrentBlockText(story);
    final EmotionalTone tone = _getCurrentBlockTone(story);

    // Start speech with the appropriate tone
    _startSpeech(text, tone: tone);
  }

  /// Parse emotional tone from string
  EmotionalTone _parseToneFromString(String? toneStr) {
    if (toneStr == null) return EmotionalTone.neutral;

    try {
      return EmotionalTone.values.firstWhere(
        (tone) => tone.toString().split('.').last == toneStr,
        orElse: () => EmotionalTone.neutral,
      );
    } catch (_) {
      return EmotionalTone.neutral;
    }
  }

  /// Get story from route arguments
  StoryModel? _getStoryFromArguments(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    // If arguments are a StoryModel, return it directly
    if (args is StoryModel) {
      return args;
    }

    // If arguments are a Map with storyId, get the story from the provider
    if (args is Map<String, dynamic> && args.containsKey('storyId')) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final storyId = args['storyId'];

      // Find the story in the provider's stories list
      try {
        return storyProvider.stories.firstWhere((s) => s.id == storyId);
      } catch (e) {
        // If story not found, select it in the provider (which will load it if needed)
        storyProvider.selectStory(storyId);
        return storyProvider.selectedStory;
      }
    }

    // If no valid arguments, return null
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Get providers
    final storyProvider = Provider.of<StoryProvider>(context);
    final badgeProvider = Provider.of<BadgeProvider>(context);

    // Handle loading state
    if (storyProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Story')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle error state
    if (storyProvider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load story: ${storyProvider.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => storyProvider.clearError(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Get story from route arguments
    final StoryModel? story = _getStoryFromArguments(context);

    // If no story found, show error
    if (story == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Story not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Web-specific warning for features that might not work in browser
    if (kIsWeb && !_isInitialized) {
      // Show a one-time warning about web limitations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some features like AI story generation may be limited in web browser.'),
              duration: Duration(seconds: 5),
            ),
          );
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }

    // Track story view
    _engagementService.recordStoryProgress(
      storyId: story.id,
      progressIndex: _currentBlockIndex,
      totalBlocks: story.content.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Story: ${story.title}'),
        actions: [
          // Badge display button
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Show Badges',
            onPressed: () {
              setState(() {
                _showBadges = !_showBadges;
                if (_showBadges) {
                  _showBranches = false;
                  // Check for new badges
                  _refreshBadges(badgeProvider);
                }
              });

              // Track interaction
              _engagementService.recordInteraction('badge_button_tap');
            },
          ),
          // TTS control button
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
            tooltip: _isSpeaking ? 'Stop Narration' : 'Start Narration',
            onPressed: () {
              if (_isSpeaking) {
                _stopSpeech();
              } else {
                _speakCurrentBlock(story);
              }

              // Track interaction
              _engagementService.recordInteraction('tts_button_tap');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Difficulty badge
          _buildDifficultyBadge(story),

          // Main content area
          Expanded(
            child: _showBadges
                ? _buildBadgeDisplay(badgeProvider)
                : _showBranches
                    ? _buildBranchOptions(story, storyProvider)
                    : _buildStoryContent(story),
          ),

          // Navigation controls
          if (!_showBadges && !_showBranches)
            _buildNavigationControls(story),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _showBadges || _showBranches
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      setState(() {
                        _showBadges = false;
                        _showBranches = false;
                      });

                      // Track interaction
                      _engagementService.recordInteraction('back_to_story_button');
                    },
                    child: const Text('Back to Story'),
                  )
                : _currentBlockIndex >= story.content.length - 1
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () {
                          setState(() {
                            _showBranches = true;
                            _animationController.forward(from: 0.0);
                          });

                          // Track story completion
                          _engagementService.recordStoryProgress(
                            storyId: story.id,
                            progressIndex: story.content.length,
                            totalBlocks: story.content.length,
                            decisions: {'completed': true},
                          );

                          // Play achievement sound
                          _audioService.playEffect(AudioType.achievement);
                        },
                        child: const Text('Continue Your Journey'),
                      )
                    : ElevatedButton(
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

    final dynamic contentBlock = story.content[_currentBlockIndex];
    if (contentBlock is ContentBlockModel) {
      return contentBlock.text;
    } else if (contentBlock is Map<dynamic, dynamic>) {
      return contentBlock['text'] ?? '';
    }

    return '';
  }

  /// Get emotional tone of current content block
  EmotionalTone _getCurrentBlockTone(StoryModel story) {
    if (story.content.isEmpty || _currentBlockIndex >= story.content.length) {
      return EmotionalTone.neutral;
    }

    final dynamic contentBlock = story.content[_currentBlockIndex];
    if (contentBlock is ContentBlockModel) {
      return contentBlock.ttsSettings.tone;
    } else if (contentBlock is Map<dynamic, dynamic> && contentBlock.containsKey('emotionalTone')) {
      final toneStr = contentBlock['emotionalTone'];
      return _parseToneFromString(toneStr);
    }

    return EmotionalTone.neutral;
  }

  /// Build a difficulty badge widget
  Widget _buildDifficultyBadge(StoryModel story) {
    final difficulty = story.challenge?.difficulty ?? 1;

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getDifficultyColor(difficulty),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            'Difficulty: ${_getDifficultyName(difficulty)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get difficulty name based on level
  String _getDifficultyName(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Basic';
    }
  }

  /// Get color based on difficulty
  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
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
      final dynamic contentBlock = story.content[i];
      final bool isActive = i == _currentBlockIndex;

      if (contentBlock is ContentBlockModel) {
        contentWidgets.add(_buildContentBlockWidget(contentBlock, isActive));
      } else if (contentBlock is Map<dynamic, dynamic>) {
        contentWidgets.add(_buildContentBlockFromMap(contentBlock, isActive));
      }
    }

    return contentWidgets;
  }

  /// Build a widget for a ContentBlockModel
  Widget _buildContentBlockWidget(ContentBlockModel block, bool isActive) {
    // Get emotional tone color
    final EmotionalTone tone = block.ttsSettings.tone;
    final Color toneColor = tone.color.withAlpha(isActive ? 51 : 13);
    final Color borderColor = isActive ? tone.color : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
        color: toneColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker image if available
          if (block.speaker != null && block.speaker!.avatarPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(block.speaker!.avatarPath!),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    block.speaker!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        tone.icon,
                        size: 16,
                        color: tone.color,
                      ),
                    ),
                ],
              ),
            ),

          // Text content
          Text(
            block.text,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          // Image if available
          if (block.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  block.imagePath!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a widget from a Map content block
  Widget _buildContentBlockFromMap(Map<dynamic, dynamic> block, bool isActive) {
    final String text = block['text'] ?? 'No text content';
    final String? type = block['type'];
    final String? emotionalToneStr = block['emotionalTone'];
    final String? speakerImage = block['speakerImage'];

    // Parse emotional tone
    final EmotionalTone tone = _parseToneFromString(emotionalToneStr);
    final Color toneColor = tone.color.withAlpha(isActive ? 51 : 13);
    final Color borderColor = isActive ? tone.color : Colors.transparent;

    // Handle different block types (text, image, etc)
    if (type == 'image' && block['url'] != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          border: isActive ? Border.all(color: borderColor, width: 2.0) : null,
          borderRadius: BorderRadius.circular(12.0),
          color: toneColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Image.network(
                block['url'],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  text,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Default to text block
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
        color: toneColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker image if available
          if (speakerImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(speakerImage),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speaker',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        tone.icon,
                        size: 16,
                        color: tone.color,
                      ),
                    ),
                ],
              ),
            ),

          // Text content
          Text(
            text,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
                    _stopSpeech();
                  });

                  // Track navigation
                  _engagementService.recordInteraction(
                    'navigation_previous',
                    details: {'current_index': _currentBlockIndex},
                  );
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
                    _stopSpeech();
                  });

                  // Track navigation
                  _engagementService.recordInteraction(
                    'navigation_next',
                    details: {'current_index': _currentBlockIndex},
                  );

                  // Record story progress
                  _engagementService.recordStoryProgress(
                    storyId: story.id,
                    progressIndex: _currentBlockIndex,
                    totalBlocks: story.content.length,
                  );
                }
              : null,
        ),
      ],
    );
  }

  /// Build branch options widget
  Widget _buildBranchOptions(StoryModel story, StoryProvider storyProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What happens next?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how your journey with ${story.characterName} continues:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: story.branches.isEmpty
                  ? const Center(
                      child: Text(
                        'No branch options available for this story yet.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : DetailedNarrativeChoiceWidget(
                      branches: story.branches.map((branch) => StoryBranchModel(
                        id: branch.id,
                        description: branch.description,
                        targetStoryId: branch.targetStoryId ?? 'generated_${branch.id}',
                        requirements: branch.requirements,
                        difficultyLevel: branch.difficultyLevel,
                      )).toList(),
                      onBranchSelected: (branch) async {
                        // Select the branch
                        storyProvider.selectBranch(branch);

                        // Track branch selection
                        _engagementService.recordInteraction(
                          'branch_selection',
                          details: {
                            'branch_id': branch.id,
                            'difficulty': branch.difficultyLevel,
                          },
                        );

                        // Play selection sound
                        _audioService.playEffect(AudioType.confirmationTap);

                        // Follow the branch to generate a new story
                        final newStory = await storyProvider.followBranch('current_user');

                        if (newStory != null) {
                          // Navigate to the new story if still mounted
                          if (mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/story',
                              arguments: newStory,
                            );
                          }
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build badge display widget
  Widget _buildBadgeDisplay(BadgeProvider badgeProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Badges you\'ve earned on your learning journey:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BadgeDisplayWidget(
                      category: 'story',
                      earnedOnly: true,
                      onBadgeTap: (badge) {
                        // Show badge details
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(badge.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  badge.imageAssetPath,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.emoji_events,
                                      size: 80,
                                      color: _getBadgeTierColor(badge.tier),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(badge.description),
                                if (badge.storyReward != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'This badge unlocks a special story!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );

                        // Track badge view
                        _engagementService.recordInteraction(
                          'badge_view',
                          details: {'badge_id': badge.id},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on badge tier
  Color _getBadgeTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.blue[700]!;
      case 3:
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Refresh badges from the provider
  void _refreshBadges(BadgeProvider badgeProvider) {
    badgeProvider.refreshEarnedBadges();
  }

  /// Prepare block types and navigate to challenge
  void _prepareAndNavigateToChallenge(StoryModel story) {
    // Get the blocks required for this story's challenge
    // Get the block provider
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);

    // Extract required block types from story metadata
    final List<BlockType> requiredBlockTypes = _getRequiredBlockTypes(story);

    // Set available block types in provider
    blockProvider.setAvailableBlockTypes(requiredBlockTypes);

    // Track challenge start
    _engagementService.recordChallengeAttempt(
      challengeId: story.challenge?.id ?? story.id,
      success: false,
      difficulty: story.challenge?.difficulty ?? 1,
    );

    // Navigate to challenge
    Navigator.pushNamed(context, '/challenge', arguments: story);
  }

  /// Get required block types from story metadata
  List<BlockType> _getRequiredBlockTypes(StoryModel story) {
    final List<BlockType> blockTypes = [];

    // Try to get block types from challenge
    if (story.challenge != null && story.challenge!.availableBlockTypes.isNotEmpty) {
      for (final typeStr in story.challenge!.availableBlockTypes) {
        try {
          // Convert string to enum
          final blockType = BlockType.values.firstWhere(
            (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
            orElse: () => BlockType.pattern,
          );
          blockTypes.add(blockType);
        } catch (e) {
          debugPrint('Error parsing block type: $e');
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

