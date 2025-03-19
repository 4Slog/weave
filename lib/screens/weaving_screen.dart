import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/models/pattern_model.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/providers/pattern_provider.dart';
import 'package:kente_codeweaver/providers/learning_provider.dart';
import 'package:kente_codeweaver/services/audio_service.dart';
import 'package:kente_codeweaver/widgets/pattern_creation_workspace.dart';
import 'package:kente_codeweaver/widgets/breadcrumb_navigation.dart';
import 'package:kente_codeweaver/navigation/app_router.dart';
import 'package:uuid/uuid.dart';

/// Main screen for pattern creation
class WeavingScreen extends StatefulWidget {
  /// Difficulty level of the pattern
  final PatternDifficulty difficulty;
  
  /// Initial blocks for the workspace
  final BlockCollection? initialBlocks;
  
  /// Title of the screen
  final String title;
  
  /// Whether to show tutorial
  final bool showTutorial;
  
  /// Optional challenge ID
  final String? challengeId;
  
  /// Optional pattern to edit
  final PatternModel? patternToEdit;

  /// Creates a weaving screen
  const WeavingScreen({
    Key? key,
    this.difficulty = PatternDifficulty.basic,
    this.initialBlocks,
    this.title = 'Pattern Creation',
    this.showTutorial = false,
    this.challengeId,
    this.patternToEdit,
  }) : super(key: key);

  @override
  _WeavingScreenState createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  /// Current block collection
  late BlockCollection blockCollection;
  
  /// Audio service
  late AudioService _audioService;
  
  /// Whether to show the tutorial overlay
  bool _showTutorialOverlay = false;
  
  /// Whether the tutorial has been shown
  bool _hasShownTutorial = false;
  
  /// Current tutorial step
  int _tutorialStep = 0;
  
  /// Whether the pattern is being saved
  bool _isSaving = false;
  
  /// Pattern name when saving
  String _patternName = '';
  
  /// Pattern description when saving
  String _patternDescription = '';
  
  /// Pattern tags when saving
  List<String> _patternTags = [];
  
  /// Selected tags (for multi-select UI)
  Set<String> _selectedTags = {};
  
  /// Tutorial steps with content
  final List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Welcome to Kente Pattern Weaving!',
      'content': 'This workspace allows you to create your own Kente-inspired patterns. We\'ll guide you through the basics of pattern creation.',
    },
    {
      'title': 'Block Palette',
      'content': 'On the bottom of the screen is your block palette. You can choose different types of blocks from here to use in your pattern.',
    },
    {
      'title': 'Adding Blocks',
      'content': 'Tap on a block in the palette to add it to your workspace. Try adding a few different blocks now.',
    },
    {
      'title': 'Moving Blocks',
      'content': 'You can move blocks by dragging them around the workspace. Position them where you want them in your pattern.',
    },
    {
      'title': 'Connecting Blocks',
      'content': 'Blocks connect automatically when their connection points are close to each other. Look for small circles on the edges of blocks - these are connection points.',
    },
    {
      'title': 'Cultural Meaning',
      'content': 'Each pattern and color in Kente weaving has cultural significance. Tap the info button to learn more about the cultural context of your pattern elements.',
    },
    {
      'title': 'Saving Your Pattern',
      'content': 'When you\'re happy with your pattern, tap the save button to give it a name and save it to your collection.',
    },
    {
      'title': 'Ready to Create!',
      'content': 'Now you\'re ready to create your own Kente pattern! Remember, the pattern you create represents your own unique story.',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize audio service
    _audioService = AudioService();
    _audioService.initialize();
    
    // Initialize block collection
    if (widget.patternToEdit != null) {
      // Edit existing pattern
      blockCollection = widget.patternToEdit!.blockCollection.copy();
      _patternName = widget.patternToEdit!.name;
      _patternDescription = widget.patternToEdit!.description;
      _patternTags = List<String>.from(widget.patternToEdit!.tags);
      _selectedTags = Set<String>.from(_patternTags);
    } else if (widget.initialBlocks != null) {
      // Use provided initial blocks
      blockCollection = widget.initialBlocks!.copy();
    } else {
      // Start with empty collection
      blockCollection = BlockCollection(blocks: []);
    }
    
    // Show tutorial if requested and not already shown
    if (widget.showTutorial && !_hasShownTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showTutorialOverlay = true;
          _hasShownTutorial = true;
        });
      });
    }
    
    // Play background music
    _audioService.playMusic('audio/learning_theme.mp3');
  }
  
  @override
  void dispose() {
    // Clean up audio
    _audioService.stopAll();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              setState(() {
                _showTutorialOverlay = true;
                _tutorialStep = 0;
              });
              _audioService.playEffect(AudioType.buttonTap);
            },
          ),
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Pattern',
            onPressed: _showSaveDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Breadcrumb navigation
              _buildBreadcrumbNavigation(),
              
              // Pattern creation workspace
              Expanded(
                child: PatternCreationWorkspace(
                  initialBlocks: blockCollection,
                  difficulty: widget.difficulty,
                  title: widget.title,
                  breadcrumbs: _getBreadcrumbs(),
                  onPatternChanged: _handlePatternChanged,
                  showAIMentor: true,
                  showCulturalContext: true,
                  audioService: _audioService,
                ),
              ),
            ],
          ),
          
          // Tutorial overlay
          if (_showTutorialOverlay)
            _buildTutorialOverlay(),
            
          // Saving indicator
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build breadcrumb navigation
  Widget _buildBreadcrumbNavigation() {
    return BreadcrumbNavigation(
      items: _getBreadcrumbs(),
      onNavigate: (route, args) {
        Navigator.pushNamed(context, route, arguments: args);
      },
    );
  }
  
  /// Get breadcrumb items
  List<BreadcrumbItem> _getBreadcrumbs() {
    return [
      // Home
      BreadcrumbItem(
        label: 'Home',
        route: AppRouter.home,
        fallbackIcon: Icons.home,
      ),
      // Patterns
      BreadcrumbItem(
        label: 'Patterns',
        route: '/patterns', // Would be defined in AppRouter
        fallbackIcon: Icons.pattern,
      ),
      // Current pattern
      BreadcrumbItem(
        label: widget.patternToEdit?.name ?? 'New Pattern',
        route: AppRouter.weaving,
        fallbackIcon: Icons.edit,
        arguments: {
          'difficulty': widget.difficulty.index,
          'title': widget.title,
        },
      ),
    ];
  }
  
  /// Handle pattern changes
  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      blockCollection = updatedBlocks;
    });
    
    // In a real implementation, this would be where you validate
    // the pattern and update state accordingly
  }
  
  /// Validate the current pattern
  bool _validatePattern() {
    // Basic validation check (would be enhanced in a real implementation)
    return blockCollection.blocks.length >= 2 && blockCollection.validateConnections();
  }
  
  /// Show the tutorial overlay
  Widget _buildTutorialOverlay() {
    // Get current tutorial step
    final step = _tutorialSteps[_tutorialStep];
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tutorial title
              Text(
                step['title']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Tutorial content
              Text(
                step['content']!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous button (if not first step)
                  if (_tutorialStep > 0)
                    TextButton(
                      onPressed: _previousTutorialStep,
                      child: const Text('Previous'),
                    ),
                    
                  const SizedBox(width: 16),
                  
                  // Next/Close button
                  ElevatedButton(
                    onPressed: _tutorialStep < _tutorialSteps.length - 1
                        ? _nextTutorialStep
                        : _closeTutorial,
                    child: Text(
                      _tutorialStep < _tutorialSteps.length - 1
                          ? 'Next'
                          : 'Close',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Move to next tutorial step
  void _nextTutorialStep() {
    setState(() {
      _tutorialStep++;
    });
    _audioService.playEffect(AudioType.buttonTap);
  }
  
  /// Move to previous tutorial step
  void _previousTutorialStep() {
    setState(() {
      _tutorialStep--;
    });
    _audioService.playEffect(AudioType.buttonTap);
  }
  
  /// Close the tutorial
  void _closeTutorial() {
    setState(() {
      _showTutorialOverlay = false;
    });
    _audioService.playEffect(AudioType.buttonTap);
  }
  
  /// Show save dialog
  void _showSaveDialog() {
    // Check if there's enough blocks to save
    if (blockCollection.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some blocks to your pattern before saving.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Play sound
    _audioService.playEffect(AudioType.buttonTap);
    
    // Preset values if editing an existing pattern
    if (widget.patternToEdit != null) {
      _patternName = widget.patternToEdit!.name;
      _patternDescription = widget.patternToEdit!.description;
      _patternTags = List<String>.from(widget.patternToEdit!.tags);
      _selectedTags = Set<String>.from(_patternTags);
    } else {
      // Default values for new pattern
      _patternName = 'My Kente Pattern';
      _patternDescription = '';
      _patternTags = [];
      _selectedTags = {};
    }
    
    // Available tags
    final availableTags = [
      'Traditional',
      'Modern',
      'Simple',
      'Complex',
      'Colorful',
      'Monochrome',
      'Symbolic',
      'Abstract',
      'Geometric',
      'Cultural',
    ];
    
    // Show dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Save Pattern'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pattern name
                  TextField(
                    controller: TextEditingController(text: _patternName),
                    decoration: const InputDecoration(
                      labelText: 'Pattern Name',
                      hintText: 'Enter a name for your pattern',
                    ),
                    onChanged: (value) {
                      _patternName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Pattern description
                  TextField(
                    controller: TextEditingController(text: _patternDescription),
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Describe your pattern',
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _patternDescription = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  const Text(
                    'Tags (select all that apply):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tag selection
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                            
                            _patternTags = _selectedTags.toList();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              // Cancel button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              
              // Save button
              ElevatedButton(
                onPressed: () {
                  // Validate name
                  if (_patternName.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a pattern name.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop();
                  _savePattern();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Save the pattern
  void _savePattern() async {
    // Set saving state
    setState(() {
      _isSaving = true;
    });
    
    // Get providers
    final patternProvider = Provider.of<PatternProvider>(context, listen: false);
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    
    try {
      // Get current user ID from learning provider
      final userId = learningProvider.userProgress.userId;
      
      // Create cultural context metadata
      final culturalContext = _extractCulturalContext();
      
      // Create or update the pattern
      if (widget.patternToEdit != null) {
        // Update existing pattern
        await patternProvider.updatePattern(
          patternId: widget.patternToEdit!.id,
          name: _patternName,
          description: _patternDescription,
          tags: _patternTags,
          blockCollection: blockCollection,
          culturalContext: culturalContext,
        );
      } else {
        // Create new pattern
        await patternProvider.createPattern(
          name: _patternName,
          blockCollection: blockCollection,
          description: _patternDescription,
          tags: _patternTags,
          challengeId: widget.challengeId,
          culturalContext: culturalContext,
        );
        
        // Record learning progress
        learningProvider.recordAction(
          actionType: 'pattern_creation',
          wasSuccessful: true,
          metadata: {
            'blockCount': blockCollection.blocks.length,
            'patternName': _patternName,
          },
        );
      }
      
      // Play success sound
      _audioService.playEffect(AudioType.success);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pattern "${_patternName}" saved successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate back or to patterns screen
      if (widget.patternToEdit != null) {
        Navigator.of(context).pop();
      } else {
        // Go to patterns screen or pop if from challenge
        if (widget.challengeId != null) {
          Navigator.of(context).pop(true); // Return success
        } else {
          // TODO: Navigate to patterns screen when implemented
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving pattern: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset saving state
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  /// Extract cultural context from pattern
  Map<String, dynamic> _extractCulturalContext() {
    // This would extract cultural information from the blocks
    // For now, we'll just create a simple map with pattern types and colors
    
    final patternTypes = blockCollection.blocks
        .where((block) => block.type == BlockType.pattern)
        .map((block) => block.properties['patternType']?.toString() ?? 'basic')
        .toSet()
        .toList();
    
    final colorTypes = blockCollection.blocks
        .where((block) => block.type == BlockType.color)
        .map((block) => block.properties['color']?.toString() ?? 'black')
        .toSet()
        .toList();
    
    return {
      'patterns': patternTypes,
      'colors': colorTypes,
      'difficulty': widget.difficulty.toString().split('.').last,
      'blockCount': blockCollection.blocks.length,
      'connectionCount': blockCollection.countConnections(),
    };
  }
  
  /// Show cultural context dialog
  void _showCulturalContextDialog() {
    // This would be implemented to show cultural information
    // about the elements in the pattern
  }
}
