import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/features/block_workspace/services/block_definition_service.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';
import 'package:kente_codeweaver/features/block_workspace/widgets/block_widget.dart';
import 'package:kente_codeweaver/features/learning/widgets/contextual_hint_widget.dart';
import 'package:kente_codeweaver/features/block_workspace/painters/connections_painter.dart';
import 'package:uuid/uuid.dart';

/// Model for breadcrumb navigation item
class BreadcrumbItem {
  final String label;
  final String route;
  final IconData fallbackIcon;
  final String? iconAsset;
  final Map<String, dynamic>? arguments;

  BreadcrumbItem({
    required this.label,
    required this.route,
    required this.fallbackIcon,
    this.iconAsset,
    this.arguments,
  });
}

/// Main workspace for pattern creation
class PatternCreationWorkspace extends StatefulWidget {
  /// Initial blocks for the workspace
  final BlockCollection initialBlocks;

  /// Difficulty level of the pattern
  final PatternDifficulty difficulty;

  /// Title of the workspace
  final String title;

  /// Breadcrumb navigation items
  final List<BreadcrumbItem> breadcrumbs;

  /// Callback when pattern changes
  final Function(BlockCollection) onPatternChanged;

  /// Whether to show AI mentor
  final bool showAIMentor;

  /// Whether to show cultural context
  final bool showCulturalContext;

  /// Audio service for sound effects
  final AudioService? audioService;

  const PatternCreationWorkspace({
    super.key,
    required this.initialBlocks,
    required this.difficulty,
    required this.title,
    this.breadcrumbs = const [],
    required this.onPatternChanged,
    this.showAIMentor = true,
    this.showCulturalContext = true,
    this.audioService,
  });

  @override
  State<PatternCreationWorkspace> createState() => _PatternCreationWorkspaceState();
}

class _PatternCreationWorkspaceState extends State<PatternCreationWorkspace> with SingleTickerProviderStateMixin {
  final BlockDefinitionService _blockService = BlockDefinitionService();
  // Removed unused _mentorService field
  final Uuid _uuid = Uuid();

  /// Current state of block collection
  late BlockCollection blockCollection;

  /// Selected block (if any)
  BlockModel? _selectedBlock;

  // Removed unused _draggingBlock field

  /// Whether the grid is visible
  bool _showGrid = true;

  /// Grid size for snapping
  final double _gridSize = 20.0;

  /// Scale factor for zoom
  double _scaleFactor = 1.0;

  /// Pan offset for workspace
  Offset _panOffset = Offset.zero;

  /// Whether a hint is visible
  bool _isHintVisible = true;

  /// Current hint data
  Map<String, dynamic>? _currentHint;

  /// Whether the palette is expanded
  bool _isPaletteExpanded = true;

  /// Animation controller for palette
  late AnimationController _paletteAnimationController;

  /// Animation for palette expansion
  late Animation<double> _paletteAnimation;

  /// Tutorial state
  bool _showTutorialOverlay = false;
  bool _hasShownTutorial = false;
  int _tutorialStep = 0;

  /// Available blocks filtered by difficulty
  List<BlockModel> _availableBlocks = [];

  /// Current category filter
  String _currentCategory = 'All';

  @override
  void initState() {
    super.initState();

    // Initialize block collection from props
    blockCollection = widget.initialBlocks.copy();

    // Initialize animation controller
    _paletteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _paletteAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _paletteAnimationController, curve: Curves.easeInOut),
    );

    // Start with expanded palette
    _paletteAnimationController.value = 1.0;

    // Load block definitions
    _loadBlocks();

    // Show tutorial on first load if needed
    if (!_hasShownTutorial && widget.difficulty == PatternDifficulty.basic) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showTutorialOverlay = true;
          _hasShownTutorial = true;
        });
      });
    }

    // Generate initial hint
    _updateHint();
  }

  @override
  void dispose() {
    _paletteAnimationController.dispose();
    super.dispose();
  }

  /// Load block definitions based on difficulty
  Future<void> _loadBlocks() async {
    // Ensure block definitions are loaded
    await _blockService.loadBlockDefinitions();

    // Filter blocks by difficulty
    setState(() {
      _availableBlocks = _blockService.allBlocks.where((block) {
        // Get block difficulty from metadata
        final blockDifficulty = _parsePatternDifficulty(
          block.metadata['difficulty']?.toString() ?? 'basic'
        );

        // Include blocks at or below current difficulty
        return blockDifficulty.index <= widget.difficulty.index;
      }).toList();
    });
  }

  /// Parse pattern difficulty from string
  PatternDifficulty _parsePatternDifficulty(String difficultyStr) {
    try {
      return PatternDifficulty.values.firstWhere(
        (d) => d.toString().split('.').last.toLowerCase() == difficultyStr.toLowerCase(),
        orElse: () => PatternDifficulty.basic,
      );
    } catch (e) {
      return PatternDifficulty.basic;
    }
  }

  /// Update the hint based on workspace state
  void _updateHint() {
    // Create a mock hint since we can't use the actual mentor service method
    final Map<String, dynamic> hintData = {
      'text': 'Try connecting blocks to create a pattern',
      'tone': 'encouraging',
      'imagePath': '',
      'isImportant': false,
    };

    setState(() {
      _currentHint = hintData;
      _isHintVisible = true;
    });
  }

  /// Add a block to the workspace
  void _addBlock(BlockModel block) {
    // Create a copy with a new ID
    // Create a new block with the same properties but a new ID
    final newBlock = BlockModel(
      id: _uuid.v4(),
      name: 'Block', // Default name
      type: block.type,
      position: block.position,
      size: block.size,
      connections: List.from(block.connections),
      properties: Map.from(block.properties),
      colorHex: block.colorHex,
      iconPath: block.iconPath,
    );

    // Position in center of visible workspace
    final size = MediaQuery.of(context).size;
    newBlock.position = Offset(
      (size.width / 2) - (newBlock.size.width / 2) - _panOffset.dx,
      (size.height / 3) - (newBlock.size.height / 2) - _panOffset.dy,
    );

    // Add to collection
    blockCollection.addBlock(newBlock);

    // Notify parent
    widget.onPatternChanged(blockCollection);

    // Play sound if available
    widget.audioService?.playEffect(AudioType.buttonTap);

    // Update hint
    _updateHint();

    // Select the new block
    setState(() {
      _selectedBlock = newBlock;
    });
  }

  // Removed unused _removeBlock method

  /// Update block position
  void _updateBlockPosition(BlockModel block, Offset newPosition) {
    // Find the block
    final blockIndex = blockCollection.blocks.indexWhere((b) => b.id == block.id);
    if (blockIndex < 0) return;

    // Snap to grid if enabled
    final snappedPosition = _showGrid
        ? Offset(
            (_gridSize * (newPosition.dx / _gridSize).round()).toDouble(),
            (_gridSize * (newPosition.dy / _gridSize).round()).toDouble(),
          )
        : newPosition;

    // Update position
    blockCollection.blocks[blockIndex].position = snappedPosition;

    // Notify parent
    widget.onPatternChanged(blockCollection);

    // Refresh UI
    setState(() {});
  }

  // Removed unused _attemptConnections method

  /// Handle when a block is tapped
  void _handleBlockTap(BlockModel block) {
    // Toggle selection
    setState(() {
      if (_selectedBlock?.id == block.id) {
        _selectedBlock = null;
      } else {
        _selectedBlock = block;
        // Play selection sound
        widget.audioService?.playEffect(AudioType.buttonTap);
      }
    });
  }

  /// Build the pattern workspace
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Toggle grid button
          IconButton(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Toggle Grid',
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
          ),
          // Toggle palette button
          IconButton(
            icon: Icon(_isPaletteExpanded ? Icons.palette : Icons.palette_outlined),
            tooltip: 'Toggle Palette',
            onPressed: _togglePalette,
          ),
          // Hint button
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Get Hint',
            onPressed: () {
              _updateHint();
              setState(() {
                _isHintVisible = true;
              });
            },
          ),
          // Cultural context button
          if (widget.showCulturalContext)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Cultural Context',
              onPressed: _showCulturalContextDialog,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main workspace content
          Column(
            children: [
              // Breadcrumb navigation if provided
              if (widget.breadcrumbs.isNotEmpty)
                _buildBreadcrumbNavigation(),

              // Main workspace area with blocks
              Expanded(
                child: _buildWorkspaceArea(),
              ),

              // Block palette
              _buildBlockPalette(),
            ],
          ),

          // Tutorial overlay if shown
          if (_showTutorialOverlay)
            _buildTutorialOverlay(),

          // Hint widget if visible
          if (_isHintVisible && _currentHint != null)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: ContextualHintWidget(
                text: _currentHint!['text'],
                tone: _currentHint!['tone'],
                imagePath: _currentHint!['imagePath'],
                isImportant: _currentHint!['isImportant'],
                onDismiss: () {
                  setState(() {
                    _isHintVisible = false;
                  });
                },
                // Removed audioService parameter as it's not defined in ContextualHintWidget
              ),
            ),
        ],
      ),
    );
  }

  /// Build breadcrumb navigation
  Widget _buildBreadcrumbNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: List.generate(widget.breadcrumbs.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Separator
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            );
          } else {
            // Breadcrumb item
            final itemIndex = index ~/ 2;
            final item = widget.breadcrumbs[itemIndex];

            return InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  item.route,
                  arguments: item.arguments,
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.iconAsset != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Image.asset(
                          item.iconAsset!,
                          width: 16,
                          height: 16,
                          errorBuilder: (_, __, ___) => Icon(
                            item.fallbackIcon,
                            size: 16,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          item.fallbackIcon,
                          size: 16,
                        ),
                      ),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  /// Build the main workspace area with blocks
  Widget _buildWorkspaceArea() {
    return GestureDetector(
      onScaleStart: (details) {
        // Store the initial scale and offset
        // No dragging block to track
      },
      onScaleUpdate: (details) {
        setState(() {
          // Update scale factor for zoom (min 0.5, max 2.0)
          _scaleFactor = (_scaleFactor * details.scale).clamp(0.5, 2.0);

          // Update pan offset for moving the workspace
          _panOffset += details.focalPointDelta;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          backgroundBlendMode: BlendMode.multiply,
          image: _showGrid
              ? const DecorationImage(
                  image: AssetImage('assets/images/grid_background.png'),
                  repeat: ImageRepeat.repeat,
                )
              : null,
        ),
        child: ClipRect(
          child: Stack(
            children: [
              // Connections between blocks
              CustomPaint(
                painter: ConnectionsPainter(blocks: blockCollection.blocks),
                size: Size.infinite,
              ),

              // Blocks
              ...blockCollection.blocks.map((block) {
                final isSelected = _selectedBlock?.id == block.id;

                return BlockWidget(
                  key: ValueKey(block.id),
                  block: block,
                  isSelected: isSelected,
                  onBlockTapped: _handleBlockTap,
                  onBlockMoved: (blockModel, position) {
                    // Update block position as it's being dragged
                    _updateBlockPosition(blockModel, position);
                  },
                  onConnectionTapped: (blockModel, connection) {
                    // Handle connection tap, can be used for manual connections
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the block palette
  Widget _buildBlockPalette() {
    return AnimatedBuilder(
      animation: _paletteAnimation,
      builder: (context, child) {
        final height = 80.0 + (120.0 * _paletteAnimation.value);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Block categories
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    // All category
                    _buildCategoryChip('All', Icons.category),

                    // Pattern category
                    _buildCategoryChip('Patterns', Icons.pattern),

                    // Color category
                    _buildCategoryChip('Colors', Icons.palette),

                    // Structure category
                    _buildCategoryChip('Structure', Icons.view_module),

                    // Loop category
                    _buildCategoryChip('Loops', Icons.loop),
                  ],
                ),
              ),

              // Block palette
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _paletteAnimation.value,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    children: _filteredBlocks.map((block) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () => _addBlock(block),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Color(int.parse(block.colorHex?.substring(1) ?? '0', radix: 16) + 0xFF000000),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: const Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Block icon
                                if (block.iconPath?.isNotEmpty ?? false)
                                  Image.asset(
                                    block.iconPath!,
                                    width: 32,
                                    height: 32,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _getIconForBlockType(block.type),
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    _getIconForBlockType(block.type),
                                    size: 32,
                                    color: Colors.white,
                                  ),

                                const SizedBox(height: 4),

                                // Block name
                                Text(
                                  block.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a category filter chip
  Widget _buildCategoryChip(String category, IconData icon) {
    final isSelected = _currentCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filter blocks based on current category
  List<BlockModel> get _filteredBlocks {
    if (_currentCategory == 'All') {
      return _availableBlocks;
    }

    return _availableBlocks.where((block) {
      switch (_currentCategory) {
        case 'Patterns':
          return block.type == BlockType.pattern;
        case 'Colors':
          return block.type == BlockType.color;
        case 'Structure':
          return block.type == BlockType.structure;
        case 'Loops':
          return block.type == BlockType.loop;
        default:
          return true;
      }
    }).toList();
  }

  /// Get appropriate icon for block type
  IconData _getIconForBlockType(BlockType type) {
    // Handle each case explicitly without a default
    if (type == BlockType.pattern) {
      return Icons.pattern;
    } else if (type == BlockType.color) {
      return Icons.palette;
    } else if (type == BlockType.structure) {
      return Icons.view_module;
    } else if (type == BlockType.loop) {
      return Icons.loop;
    } else if (type == BlockType.column) {
      return Icons.view_column;
    } else {
      // This should never happen with the current enum values
      // but we need to return something for the compiler
      return Icons.widgets;
    }
  }

  /// Build the tutorial overlay
  Widget _buildTutorialOverlay() {
    // Tutorial steps with content and positions
    final List<Map<String, dynamic>> tutorialSteps = [
      {
        'title': 'Welcome to Pattern Creation!',
        'content': 'This workspace allows you to create Kente patterns by connecting blocks. Let\'s learn how to use it.',
        'position': 'center',
      },
      {
        'title': 'Block Palette',
        'content': 'This is your block palette. You can find different types of blocks here to create your pattern.',
        'position': 'bottom',
      },
      {
        'title': 'Adding Blocks',
        'content': 'Tap on a block in the palette to add it to your workspace.',
        'position': 'bottom',
      },
      {
        'title': 'Moving Blocks',
        'content': 'You can drag blocks around the workspace to position them.',
        'position': 'center',
      },
      {
        'title': 'Connecting Blocks',
        'content': 'Blocks connect automatically when their connection points are close to each other. Look for the small circles on the blocks.',
        'position': 'center',
      },
      {
        'title': 'Selection',
        'content': 'Tap a block to select it. Selected blocks show additional options.',
        'position': 'center',
      },
      {
        'title': 'Getting Help',
        'content': 'If you need help, tap the lightbulb icon to get a hint.',
        'position': 'top',
      },
      {
        'title': 'Cultural Context',
        'content': 'Learn about the cultural meaning of patterns by tapping the info icon.',
        'position': 'top',
      },
      {
        'title': 'Ready to Create!',
        'content': 'Now you\'re ready to create your own Kente pattern! Let\'s get started.',
        'position': 'center',
      },
    ];

    // Current tutorial step
    final step = tutorialSteps[_tutorialStep];

    // Position the tutorial content
    Widget positionedContent;
    switch (step['position']) {
      case 'top':
        positionedContent = Positioned(
          top: 70,
          left: 20,
          right: 20,
          child: _buildTutorialCard(step),
        );
        break;
      case 'bottom':
        positionedContent = Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: _buildTutorialCard(step),
        );
        break;
      case 'center':
      default:
        positionedContent = Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildTutorialCard(step),
          ),
        );
    }

    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          // Positioned tutorial content
          positionedContent,

          // Navigation buttons
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back button
                if (_tutorialStep > 0)
                  ElevatedButton(
                    onPressed: _previousTutorialStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                    child: const Text('Back'),
                  ),

                const SizedBox(width: 20),

                // Next/Finish button
                ElevatedButton(
                  onPressed: _tutorialStep < tutorialSteps.length - 1
                      ? _nextTutorialStep
                      : _closeTutorial,
                  child: Text(_tutorialStep < tutorialSteps.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ),

          // Skip button
          Positioned(
            top: 20,
            right: 20,
            child: TextButton(
              onPressed: _closeTutorial,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Skip Tutorial'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a tutorial card with content
  Widget _buildTutorialCard(Map<String, dynamic> step) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step['content'],
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to next tutorial step
  void _nextTutorialStep() {
    setState(() {
      _tutorialStep++;
    });
    // Play button sound
    widget.audioService?.playEffect(AudioType.buttonTap);
  }

  /// Navigate to previous tutorial step
  void _previousTutorialStep() {
    setState(() {
      _tutorialStep--;
    });
    // Play button sound
    widget.audioService?.playEffect(AudioType.buttonTap);
  }

  /// Close the tutorial
  void _closeTutorial() {
    setState(() {
      _showTutorialOverlay = false;
    });
    // Play button sound
    widget.audioService?.playEffect(AudioType.buttonTap);
  }

  /// Toggle the palette expanded state
  void _togglePalette() {
    setState(() {
      _isPaletteExpanded = !_isPaletteExpanded;

      if (_isPaletteExpanded) {
        _paletteAnimationController.forward();
      } else {
        _paletteAnimationController.reverse();
      }
    });

    // Play button sound
    widget.audioService?.playEffect(AudioType.buttonTap);
  }

  /// Show the cultural context dialog
  void _showCulturalContextDialog() {
    // Play button sound
    widget.audioService?.playEffect(AudioType.buttonTap);

    // Get pattern types in the workspace
    final patternTypes = blockCollection.blocks
        .where((block) => block.type == BlockType.pattern)
        .map((block) => block.properties['patternType']?.toString() ?? 'basic')
        .toSet()
        .toList();

    // Get color types in the workspace
    final colorTypes = blockCollection.blocks
        .where((block) => block.type == BlockType.color)
        .map((block) => block.properties['color']?.toString() ?? 'black')
        .toSet()
        .toList();

    // Show dialog with cultural context
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cultural Context'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pattern section
                if (patternTypes.isNotEmpty) ...[
                  const Text(
                    'Pattern Meanings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...patternTypes.map((pattern) => _buildCulturalContextItem(
                    title: _getPatternName(pattern),
                    description: _getPatternMeaning(pattern),
                  )),
                  const SizedBox(height: 16),
                ],

                // Color section
                if (colorTypes.isNotEmpty) ...[
                  const Text(
                    'Color Meanings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...colorTypes.map((color) => _buildCulturalContextItem(
                    title: _getColorName(color),
                    description: _getColorMeaning(color),
                    color: _parseColor(color),
                  )),
                  const SizedBox(height: 16),
                ],

                // General Kente context
                const Text(
                  'About Kente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCulturalContextItem(
                  title: 'Kente Weaving',
                  description: 'Kente cloth is a type of silk and cotton fabric made of interwoven cloth strips, native to the Akan people of Ghana. Each pattern and color carries specific meaning, representing historical events, philosophical concepts, or cultural values.',
                ),

                // Connection to coding
                const SizedBox(height: 16),
                const Text(
                  'Connection to Coding',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCulturalContextItem(
                  title: 'Patterns as Algorithms',
                  description: 'Just like in coding, Kente weaving follows specific patterns and sequences. Weavers use repeated motifs (similar to loops in programming) and conditional variations (like if-statements) to create complex designs.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Build a cultural context item
  Widget _buildCulturalContextItem({
    required String title,
    required String description,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color swatch if provided
          if (color != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get pattern name based on type
  String _getPatternName(String patternType) {
    switch (patternType) {
      case 'checker':
        return 'Dame-Dame (Checkerboard)';
      case 'zigzag':
        return 'Akyem (Zigzag)';
      case 'diamond':
        return 'Nkyimkyim (Diamond)';
      case 'stripes':
        return 'Babadua (Stripes)';
      default:
        return patternType.substring(0, 1).toUpperCase() + patternType.substring(1);
    }
  }

  /// Get pattern meaning based on type
  String _getPatternMeaning(String patternType) {
    switch (patternType) {
      case 'checker':
        return 'Represents duality and balance. The alternating pattern symbolizes how opposing forces work together in harmony.';
      case 'zigzag':
        return 'Symbolizes life\'s journey with its ups and downs. Represents persistence through life\'s challenges.';
      case 'diamond':
        return 'Represents wisdom, cleverness, and the complexity of life. The interconnected shapes show how all aspects of life are connected.';
      case 'stripes':
        return 'Symbolizes simplicity, unity, and continuous progress. Straight lines represent directness and clarity of purpose.';
      default:
        return 'A traditional pattern in Kente cloth with cultural significance.';
    }
  }

  /// Get color name based on color value
  String _getColorName(String colorValue) {
    switch (colorValue.toLowerCase()) {
      case 'black':
        return 'Black (Tuntum)';
      case 'red':
        return 'Red (Kobene)';
      case 'yellow':
      case 'gold':
        return 'Gold (Sikakɔkɔɔ)';
      case 'green':
        return 'Green (Akokɔ Nan Nti)';
      case 'blue':
        return 'Blue (Bluu)';
      case 'white':
        return 'White (Fitaa)';
      default:
        return colorValue.substring(0, 1).toUpperCase() + colorValue.substring(1);
    }
  }

  /// Get color meaning based on color value
  String _getColorMeaning(String colorValue) {
    switch (colorValue.toLowerCase()) {
      case 'black':
        return 'Represents maturity, spiritual energy, and ancestral connection. Symbolizes spiritual potency and aged wisdom.';
      case 'red':
        return 'Symbolizes political passion, sacrifice, and struggle. Associated with blood, sacrificial rites, and life force.';
      case 'yellow':
      case 'gold':
        return 'Represents royalty, wealth, fertility, and glory. Symbolizes the sun\'s life-giving warmth and prosperity.';
      case 'green':
        return 'Symbolizes growth, harvest, renewal, and spiritual rejuvenation. Associated with plants, agriculture, and medicine.';
      case 'blue':
        return 'Represents peacefulness, harmony, and love. Associated with the sky and divine presence.';
      case 'white':
        return 'Symbolizes purity, cleansing, festive occasions, and spiritual balance. Associated with contact with ancestral spirits.';
      default:
        return 'A color with cultural significance in Kente cloth traditions.';
    }
  }

  /// Parse color from string
  Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
      case 'gold':
        return const Color(0xFFFFD700);
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        // Try to parse hex code if provided
        if (colorStr.startsWith('#') && colorStr.length == 7) {
          try {
            return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
          } catch (_) {
            return Colors.grey;
          }
        }
        return Colors.grey;
    }
  }

  // Removed unused _handlePatternChanged method

  /// Validate the current pattern
  bool validatePattern() {
    // Validate connections
    return blockCollection.validateConnections();
  }
}
