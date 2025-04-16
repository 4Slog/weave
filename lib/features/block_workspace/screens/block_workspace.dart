import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';
import 'package:kente_codeweaver/features/block_workspace/models/challenge.dart';
import 'package:kente_codeweaver/features/block_workspace/painters/grid_painter.dart';
import 'package:kente_codeweaver/features/block_workspace/painters/connections_painter.dart';
import 'package:kente_codeweaver/features/block_workspace/services/challenge_service.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/block_workspace/widgets/block_widget.dart';
// Removed unused import: story_mentor_service.dart
import 'package:uuid/uuid.dart';

/// An enhanced workspace for creating and manipulating code blocks with improved
/// validation, feedback, and adaptive learning integration.
///
/// This workspace allows users to drag and drop blocks to create patterns
/// and solve challenges. It includes AI-driven adaptive learning features,
/// contextual hints, and sophisticated feedback mechanisms.
class BlockWorkspaceEnhanced extends StatefulWidget {
  /// The current story context
  final String storyContext;

  /// The coding concept being taught
  final String codingConcept;

  /// The user ID
  final String userId;

  /// The challenge ID if this workspace is part of a challenge
  final String? challengeId;

  /// The difficulty level of the challenge
  final double difficulty;

  /// Whether to show real-time validation feedback
  final bool showRealtimeValidation;

  /// Callback when a solution is accepted
  final VoidCallback? onSolutionAccepted;

  const BlockWorkspaceEnhanced({
    super.key,
    this.storyContext = 'Kente pattern creation',
    this.codingConcept = 'patterns',
    this.userId = 'default',
    this.challengeId,
    this.difficulty = 1.0,
    this.showRealtimeValidation = true,
    this.onSolutionAccepted,
  });

  @override
  State<BlockWorkspaceEnhanced> createState() => _BlockWorkspaceEnhancedState();
}

class _BlockWorkspaceEnhancedState extends State<BlockWorkspaceEnhanced> with TickerProviderStateMixin {
  // Removed unused Uuid and EnhancedStoryMentorService
  final double _gridSize = 20.0; // Size of grid cells
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  final ChallengeService _challengeService = ChallengeService();
  final StorageService _storageService = StorageService();

  bool _showingHint = false;
  String _feedback = '';
  bool _showFeedback = false;
  BlockModel? _selectedBlock;

  // Challenge data
  Challenge? _currentChallenge;

  // Validation state
  bool _isValid = false;
  List<String> _validationIssues = [];

  // Animation controllers
  late AnimationController _feedbackAnimationController;
  late AnimationController _validationAnimationController;

  // Timer for auto-saving
  Timer? _autoSaveTimer;

  // Timer for tracking time spent
  DateTime? _startTime;
  // Removed unused _timeSpentSeconds
  Timer? _timeTrackingTimer;

  // User skill level
  SkillLevel _userSkillLevel = SkillLevel.novice;

  // Hint level (1-3, higher means more detailed hints)
  // Removed unused _hintLevel

  // Colors for different block types
  final Map<BlockType, Color> _blockColors = {
    BlockType.pattern: Colors.deepPurple,
    BlockType.color: Colors.amber,
    BlockType.structure: Colors.cyan,
    BlockType.loop: Colors.orange,
    BlockType.column: Colors.teal,
  };

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _validationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize services and load data
    _initializeData();

    // Start time tracking
    _startTimeTracking();

    // Set up auto-save timer (every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSaveWorkspace();
    });
  }

  @override
  void dispose() {
    _feedbackAnimationController.dispose();
    _validationAnimationController.dispose();
    _autoSaveTimer?.cancel();
    _timeTrackingTimer?.cancel();
    super.dispose();
  }

  /// Initialize user data, challenge, and skill level
  Future<void> _initializeData() async {
    try {
      // Initialize learning service
      await _learningService.initialize();

      // Initialize challenge service
      await _challengeService.initialize();

      // Get user skill level
      _userSkillLevel = await _learningService.getUserSkillLevel(widget.userId);

      // Hint level is adjusted based on skill level
      // Removed reference to unused method

      // Set available block types based on skill level
      _setAvailableBlockTypes();

      // Load challenge if we have a challenge ID
      if (widget.challengeId != null) {
        _currentChallenge = await _challengeService.getChallengeById(widget.challengeId!);

        // If we have a challenge, set available block types based on challenge
        if (_currentChallenge != null) {
          _setAvailableBlockTypesFromChallenge(_currentChallenge!);
        }

        // Try to load saved state for this challenge
        _loadSavedState();
      }

      // Perform initial validation
      if (widget.showRealtimeValidation) {
        _validateWorkspace(showFeedback: false);
      }
    } catch (e) {
      debugPrint('Error initializing BlockWorkspaceEnhanced: $e');
    }
  }

  /// Start tracking time spent in the workspace
  void _startTimeTracking() {
    _startTime = DateTime.now();

    // Update time spent every second
    _timeTrackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        final now = DateTime.now();
        // Track time spent for analytics (removed unused variable)
        final timeSpentSeconds = now.difference(_startTime!).inSeconds;
        debugPrint('Time spent: $timeSpentSeconds seconds');
      }
    });
  }

  // Removed unused method _getHintLevelForSkillLevel

  /// Helper method to close dialog and show save confirmation
  /// This avoids BuildContext usage across async gaps
  void _closeDialogAndShowSaveConfirmation(String name) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "$name" saved successfully'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Helper method to show load template dialog
  /// This avoids BuildContext usage across async gaps
  void _showLoadTemplateDialog(String template, String name) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Load'),
        content: Text('Loading template "$name" will replace your current workspace. Continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear current workspace and load template
              blockProvider.clearBlocks();

              // Parse the JSON string into a Map
              final Map<String, dynamic> workspaceData = jsonDecode(template.toString());
              blockProvider.importWorkspace(workspaceData);

              // Close both dialogs
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "$name" loaded successfully'),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Validate workspace if real-time validation is enabled
              if (widget.showRealtimeValidation) {
                _validateWorkspace(showFeedback: false);
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  /// Set available block types based on user skill level
  void _setAvailableBlockTypes() {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    List<BlockType> availableTypes = [];

    // Always include basic block types
    availableTypes.add(BlockType.pattern);
    availableTypes.add(BlockType.color);

    // Add more complex types based on skill level
    switch (_userSkillLevel) {
      case SkillLevel.novice:
        // Just the basics
        break;
      case SkillLevel.beginner:
        availableTypes.add(BlockType.loop);
        break;
      case SkillLevel.intermediate:
        availableTypes.add(BlockType.loop);
        availableTypes.add(BlockType.structure);
        break;
      case SkillLevel.advanced:
        // All block types
        availableTypes.add(BlockType.loop);
        availableTypes.add(BlockType.structure);
        availableTypes.add(BlockType.column);
        break;
    }

    blockProvider.setAvailableBlockTypes(availableTypes);
  }

  /// Set available block types based on challenge requirements
  void _setAvailableBlockTypesFromChallenge(Challenge challenge) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    List<BlockType> availableTypes = [];

    // Add required block types from challenge
    for (final typeStr in challenge.requiredBlockTypes) {
      final blockType = _parseBlockType(typeStr);
      if (blockType != null) {
        availableTypes.add(blockType);
      }
    }

    // Add some additional block types based on difficulty
    if (challenge.difficulty >= 2.0) {
      if (!availableTypes.contains(BlockType.loop)) {
        availableTypes.add(BlockType.loop);
      }
    }

    if (challenge.difficulty >= 3.0) {
      if (!availableTypes.contains(BlockType.structure)) {
        availableTypes.add(BlockType.structure);
      }
    }

    if (challenge.difficulty >= 4.0) {
      if (!availableTypes.contains(BlockType.column)) {
        availableTypes.add(BlockType.column);
      }
    }

    // Always ensure pattern and color blocks are available
    if (!availableTypes.contains(BlockType.pattern)) {
      availableTypes.add(BlockType.pattern);
    }

    if (!availableTypes.contains(BlockType.color)) {
      availableTypes.add(BlockType.color);
    }

    blockProvider.setAvailableBlockTypes(availableTypes);
  }

  /// Load saved state for the current challenge
  Future<void> _loadSavedState() async {
    if (widget.challengeId == null) return;

    try {
      final blockProvider = Provider.of<BlockProvider>(context, listen: false);
      final savedState = await _storageService.getSetting(
        'workspace_${widget.userId}_${widget.challengeId}'
      );

      if (savedState != null) {
        // Parse the JSON string into a Map
        final Map<String, dynamic> workspaceData = jsonDecode(savedState.toString());
        blockProvider.importWorkspace(workspaceData);
      }
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  /// Auto-save the current workspace state
  Future<void> _autoSaveWorkspace() async {
    if (widget.challengeId == null) return;

    try {
      final blockProvider = Provider.of<BlockProvider>(context, listen: false);
      final workspace = blockProvider.exportWorkspace();

      // Convert workspace to JSON string
      final workspaceJson = jsonEncode(workspace);

      await _storageService.saveSetting(
        'workspace_${widget.userId}_${widget.challengeId}',
        workspaceJson
      );
    } catch (e) {
      debugPrint('Error auto-saving workspace: $e');
    }
  }

  /// Save the workspace manually
  Future<void> _saveWorkspace() async {
    if (widget.challengeId == null) {
      // If no challenge ID, show a dialog to save as a template
      _showSaveTemplateDialog();
      return;
    }

    try {
      final blockProvider = Provider.of<BlockProvider>(context, listen: false);
      final workspace = blockProvider.exportWorkspace();

      // Convert workspace to JSON string
      final workspaceJson = jsonEncode(workspace);

      await _storageService.saveSetting(
        'workspace_${widget.userId}_${widget.challengeId}',
        workspaceJson
      );

      // Show a snackbar to confirm save
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workspace saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving workspace: $e');

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workspace: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show dialog to save workspace as a template
  void _showSaveTemplateDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this template:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              // Save template
              final blockProvider = Provider.of<BlockProvider>(context, listen: false);
              final workspace = blockProvider.exportWorkspace();

              // Convert workspace to JSON string
              final workspaceJson = jsonEncode(workspace);

              await _storageService.saveSetting(
                'template_${name.replaceAll(' ', '_')}',
                workspaceJson
              );

              // Close dialog and show confirmation
              if (!mounted) return;
              _closeDialogAndShowSaveConfirmation(name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to load a template
  void _showTemplateDialog() async {
    try {
      // Get all template keys
      final allKeys = await _storageService.getAllKeys();
      final templateKeys = allKeys.where((key) => key.startsWith('template_')).toList();

      if (templateKeys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved templates found'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show dialog with template list
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Load Template'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templateKeys.length,
              itemBuilder: (context, index) {
                final key = templateKeys[index];
                final name = key.replaceAll('template_', '').replaceAll('_', ' ');

                return ListTile(
                  title: Text(name),
                  onTap: () async {
                    // Load template
                    final template = await _storageService.getSetting(key);
                    if (template != null) {
                      // Show load template dialog
                      if (!mounted) return;
                      _showLoadTemplateDialog(template, name);

                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading templates: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show confirmation dialog for clearing the workspace
  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Workspace'),
        content: const Text('Are you sure you want to clear the workspace? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Clear workspace
              Provider.of<BlockProvider>(context, listen: false).clearBlocks();

              // Clear selected block
              setState(() {
                _selectedBlock = null;
              });

              // Close dialog
              Navigator.of(context).pop();

              // Validate workspace if real-time validation is enabled
              if (widget.showRealtimeValidation) {
                _validateWorkspace(showFeedback: false);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentChallenge?.title ?? 'Block Workspace'),
        actions: [
          // Clear workspace button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear workspace',
            onPressed: () {
              _showClearConfirmationDialog();
            },
          ),
          // Validate button
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Validate solution',
            onPressed: () => _validateWorkspace(showFeedback: true),
          ),
          // Hint button
          IconButton(
            icon: Icon(_showingHint ? Icons.lightbulb : Icons.lightbulb_outline),
            tooltip: 'Show/hide hints',
            onPressed: () {
              setState(() {
                _showingHint = !_showingHint;
              });
            },
          ),
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save workspace',
            onPressed: _saveWorkspace,
          ),
          // Load template button
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load template',
            onPressed: _showTemplateDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Challenge description
          if (_currentChallenge != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withAlpha(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentChallenge!.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildRequirementChip(
                        'Required blocks: ${_currentChallenge!.requiredBlockTypes.join(", ")}',
                        Icons.category,
                      ),
                      _buildRequirementChip(
                        'Min connections: ${_currentChallenge!.minConnections}',
                        Icons.link,
                      ),
                      if (_currentChallenge!.maxBlocks != null)
                        _buildRequirementChip(
                          'Max blocks: ${_currentChallenge!.maxBlocks}',
                          Icons.grid_view,
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Hint area
          if (_showingHint)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildHintWidget(),
            ),

          // Validation feedback area
          if (_showFeedback)
            AnimatedBuilder(
              animation: _feedbackAnimationController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isValid ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isValid ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isValid ? Colors.green : Colors.orange).withAlpha(76),
                        blurRadius: 4 * _feedbackAnimationController.value,
                        spreadRadius: 2 * _feedbackAnimationController.value,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isValid ? Icons.check_circle : Icons.info,
                            color: _isValid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isValid ? Colors.green : Colors.orange,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _showFeedback = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_feedback),
                      if (!_isValid && _validationIssues.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Issues to fix:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...List.generate(_validationIssues.length, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_right, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(_validationIssues[index])),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

          // Block palette
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Consumer<BlockProvider>(
              builder: (context, blockProvider, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(10),
                  itemCount: blockProvider.availableBlockTypes.length,
                  itemBuilder: (context, index) {
                    final blockType = blockProvider.availableBlockTypes[index];
                    return _buildPaletteItem(blockType);
                  },
                );
              },
            ),
          ),

          // Workspace area
          Expanded(
            child: Stack(
              children: [
                // Grid background
                CustomPaint(
                  painter: GridPainter(gridSize: _gridSize),
                  size: Size.infinite,
                ),

                // Validation overlay
                if (widget.showRealtimeValidation)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _validationAnimationController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isValid
                                ? Colors.green.withAlpha((127 * _validationAnimationController.value).round())
                                : Colors.orange.withAlpha((127 * _validationAnimationController.value).round()),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Blocks
                Consumer<BlockProvider>(
                  builder: (context, blockProvider, child) {
                    return Stack(
                      children: blockProvider.blocks.map((block) {
                        return BlockWidget(
                          key: ValueKey(block.id),
                          block: block,
                          isSelected: _selectedBlock?.id == block.id,
                          onBlockTapped: _handleBlockTap,
                          onBlockMoved: (blockModel, offset) {
                            // Snap to grid
                            final snappedOffset = Offset(
                              (offset.dx / _gridSize).round() * _gridSize,
                              (offset.dy / _gridSize).round() * _gridSize,
                            );
                            blockProvider.updateBlockPosition(block.id, snappedOffset);

                            // Validate workspace if real-time validation is enabled
                            if (widget.showRealtimeValidation) {
                              _validateWorkspace(showFeedback: false);
                            }
                          },
                          onConnectionTapped: (blockModel, connection) {
                            _handleConnectionTap(blockModel, connection);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                // Connection lines
                Consumer<BlockProvider>(
                  builder: (context, blockProvider, child) {
                    return CustomPaint(
                      painter: ConnectionsPainter(
                        blocks: blockProvider.blocks,
                        highlightedBlockId: _selectedBlock?.id,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Drop area for the entire workspace
                DragTarget<Map<String, dynamic>>(
                  builder: (context, candidateItems, rejectedItems) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    );
                  },
                  onAcceptWithDetails: (DragTargetDetails<Map<String, dynamic>> details) {
                    _handleDrop(details.data, details.offset);
                  },
                ),
              ],
            ),
          ),

          // Properties panel for selected block
          if (_selectedBlock != null)
            _buildPropertiesPanel(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build a requirement chip for the challenge description
  Widget _buildRequirementChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200),
      ),
    );
  }

  /// Build the floating action button
  Widget? _buildFloatingActionButton() {
    // Only show FAB for challenges
    if (_currentChallenge == null) return null;

    return FloatingActionButton.extended(
      onPressed: () => _submitSolution(),
      label: const Text('Submit Solution'),
      icon: const Icon(Icons.send),
      backgroundColor: Colors.green,
    );
  }

  /// Build a palette item for dragging new blocks
  Widget _buildPaletteItem(BlockType blockType) {
    final blockColor = _blockColors[blockType] ?? Colors.grey;
    final String blockName = _getDisplayNameForBlockType(blockType);

    // Create a draggable item for the palette
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Draggable<Map<String, dynamic>>(
        // Use map instead of BlockModel for draggable data
        data: {
          'isNew': true,
          'type': blockType.toString(),
          'name': blockName,
        },
        feedback: Material(
          elevation: 4.0,
          child: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: Text(
              blockName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildBlockTypeItem(blockType, blockName, blockColor),
        ),
        child: _buildBlockTypeItem(blockType, blockName, blockColor),
      ),
    );
  }

  /// Build a block type item for the palette
  Widget _buildBlockTypeItem(BlockType blockType, String blockName, Color blockColor) {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: Text(
        blockName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Get a display name for a block type
  String _getDisplayNameForBlockType(BlockType blockType) {
    switch (blockType) {
      case BlockType.pattern:
        return 'Pattern';
      case BlockType.color:
        return 'Color';
      case BlockType.structure:
        return 'Structure';
      case BlockType.loop:
        return 'Loop';
      case BlockType.column:
        return 'Column';
    }
  }

  /// Handle a block being tapped
  void _handleBlockTap(BlockModel block) {
    setState(() {
      // Toggle selection if tapping the same block
      if (_selectedBlock?.id == block.id) {
        _selectedBlock = null;
      } else {
        _selectedBlock = block;
      }
    });
  }

  /// Handle a connection point being tapped
  void _handleConnectionTap(BlockModel block, BlockConnection connection) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);

    // Try to connect with any previously selected connection
    if (blockProvider.tryConnect(block.id, connection.id)) {
      // Connection successful
      setState(() {
        _selectedBlock = null;
      });

      // Validate workspace if real-time validation is enabled
      if (widget.showRealtimeValidation) {
        _validateWorkspace(showFeedback: false);
      }
    } else {
      // Select this connection for future connection attempts
      setState(() {
        _selectedBlock = block;
      });
    }
  }

  /// Handle a block being dropped onto the workspace
  void _handleDrop(Map<String, dynamic> data, Offset offset) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);

    // Snap to grid
    final snappedOffset = Offset(
      (offset.dx / _gridSize).round() * _gridSize,
      (offset.dy / _gridSize).round() * _gridSize,
    );

    // Create a new block at the dropped position
    if (data.containsKey('blockType')) {
      final blockType = data['blockType'] as BlockType;
      final newBlock = BlockModel(
        id: const Uuid().v4(),
        name: _getDisplayNameForBlockType(blockType),
        type: blockType,
        position: snappedOffset,
        size: const Size(100, 60),
        connections: _createDefaultConnectionsForType(blockType),
        properties: {},
      );

      blockProvider.addBlock(newBlock);

      // Validate workspace if real-time validation is enabled
      if (widget.showRealtimeValidation) {
        _validateWorkspace(showFeedback: false);
      }
    }
  }

  /// Create default connection points for a block type
  List<BlockConnection> _createDefaultConnectionsForType(BlockType blockType) {
    final List<BlockConnection> connections = [];

    // Add default input connection at the top
    connections.add(BlockConnection(
      id: const Uuid().v4(),
      name: 'Input',
      type: ConnectionType.input,
      position: const Offset(50, 0), // Top center
    ));

    // Add default output connection at the bottom
    connections.add(BlockConnection(
      id: const Uuid().v4(),
      name: 'Output',
      type: ConnectionType.output,
      position: const Offset(50, 60), // Bottom center
    ));

    // Add type-specific connections
    switch (blockType) {
      case BlockType.pattern:
        // Add side connections for pattern blocks
        connections.add(BlockConnection(
          id: const Uuid().v4(),
          name: 'Left',
          type: ConnectionType.bidirectional,
          position: const Offset(0, 30), // Left center
        ));
        connections.add(BlockConnection(
          id: const Uuid().v4(),
          name: 'Right',
          type: ConnectionType.bidirectional,
          position: const Offset(100, 30), // Right center
        ));
        break;
      case BlockType.loop:
        // Add extra output for loop blocks
        connections.add(BlockConnection(
          id: const Uuid().v4(),
          name: 'Loop Body',
          type: ConnectionType.output,
          position: const Offset(75, 30), // Right side
        ));
        break;
      default:
        // No additional connections for other types
        break;
    }

    return connections;
  }

  /// Validate the current workspace
  void _validateWorkspace({bool showFeedback = true}) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    final List<String> issues = [];
    bool isValid = true;

    // Check if there are any blocks
    if (blockProvider.blocks.isEmpty) {
      issues.add('Workspace is empty. Add some blocks to create a pattern.');
      isValid = false;
    }

    // Check for disconnected blocks
    for (final block in blockProvider.blocks) {
      bool isConnected = false;

      // Check if any connection is connected
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          isConnected = true;
          break;
        }
      }

      // Skip start blocks which don't need to be connected
      if (!isConnected && block.type != BlockType.pattern) {
        issues.add('${block.name} (${block.id.substring(0, 4)}) is not connected to any other block.');
        isValid = false;
      }
    }

    // Check for specific challenge requirements if a challenge is active
    if (_currentChallenge != null) {
      // Check for required block types
      for (final requiredType in _currentChallenge!.requiredBlockTypes) {
        final blockType = _parseBlockType(requiredType);
        if (blockType != null) {
          bool hasRequiredType = blockProvider.blocks.any((b) => b.type == blockType);
          if (!hasRequiredType) {
            issues.add('Challenge requires a ${_getDisplayNameForBlockType(blockType)} block.');
            isValid = false;
          }
        }
      }
    }

    // Update state with validation results
    setState(() {
      _isValid = isValid;
      _validationIssues = issues;

      if (showFeedback) {
        _showFeedback = true;
        _feedback = isValid
          ? 'Great job! Your pattern looks good.'
          : 'There are some issues with your pattern:\n${issues.join('\n')}';

        // Start feedback animation
        _feedbackAnimationController.forward(from: 0.0);
      }
    });
  }

  /// Parse a string into a BlockType
  BlockType? _parseBlockType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'pattern':
        return BlockType.pattern;
      case 'color':
        return BlockType.color;
      case 'structure':
        return BlockType.structure;
      case 'loop':
        return BlockType.loop;
      case 'column':
        return BlockType.column;
      default:
        // Try to parse from enum value
        try {
          return BlockType.values.firstWhere(
            (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
          );
        } catch (e) {
          return null;
        }
    }
  }

  /// Build the hint widget
  Widget _buildHintWidget() {
    if (_currentChallenge == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No active challenge. Create a pattern freely!'),
        ),
      );
    }

    // Get hint based on user skill level and hint level
    String hintText = '';

    if (_userSkillLevel == SkillLevel.novice) {
      hintText = 'Try using the ${_getDisplayNameForBlockType(BlockType.pattern)} block as your starting point. ';
      hintText += 'You can connect other blocks to it to create a pattern.';
    } else if (_userSkillLevel == SkillLevel.intermediate) {
      hintText = 'Consider how different blocks can be combined to create more complex patterns. ';
      hintText += 'Remember that each block type has a specific purpose in your design.';
    } else {
      hintText = 'Think about the cultural significance of your pattern. ';
      hintText += 'How can you use the available blocks to express meaning through your design?';
    }

    return Card(
      color: Colors.amber.withValues(red: 255, green: 248, blue: 225, alpha: 1.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hint',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(hintText),
            if (_currentChallenge != null && _currentChallenge!.requiredBlockTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Required Blocks:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: _currentChallenge!.requiredBlockTypes.map((typeStr) {
                  final blockType = _parseBlockType(typeStr);
                  if (blockType != null) {
                    return Chip(
                      label: Text(_getDisplayNameForBlockType(blockType)),
                      backgroundColor: _blockColors[blockType] ?? Colors.grey,
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the properties panel for the selected block
  Widget _buildPropertiesPanel() {
    if (_selectedBlock == null) return const SizedBox.shrink();

    final blockProvider = Provider.of<BlockProvider>(context, listen: false);

    return Positioned(
      right: 16,
      top: 80,
      width: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedBlock!.name} Properties',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedBlock = null;
                      });
                    },
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Position controls
              const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('X:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _selectedBlock!.position.dx,
                      min: 0,
                      max: 800,
                      divisions: 80,
                      label: _selectedBlock!.position.dx.round().toString(),
                      onChanged: (value) {
                        final newPosition = Offset(value, _selectedBlock!.position.dy);
                        blockProvider.updateBlockPosition(_selectedBlock!.id, newPosition);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(_selectedBlock!.position.dx.round().toString()),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Y:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _selectedBlock!.position.dy,
                      min: 0,
                      max: 600,
                      divisions: 60,
                      label: _selectedBlock!.position.dy.round().toString(),
                      onChanged: (value) {
                        final newPosition = Offset(_selectedBlock!.position.dx, value);
                        blockProvider.updateBlockPosition(_selectedBlock!.id, newPosition);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(_selectedBlock!.position.dy.round().toString()),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Type-specific properties
              if (_selectedBlock!.type == BlockType.pattern) ..._buildPatternProperties(),
              if (_selectedBlock!.type == BlockType.color) ..._buildColorProperties(),
              if (_selectedBlock!.type == BlockType.loop) ..._buildLoopProperties(),

              const SizedBox(height: 16),

              // Delete button
              ElevatedButton.icon(
                onPressed: () {
                  blockProvider.removeBlock(_selectedBlock!.id);
                  setState(() {
                    _selectedBlock = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Delete Block'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build properties specific to pattern blocks
  List<Widget> _buildPatternProperties() {
    return [
      const Text('Pattern Properties', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Pattern Type',
          border: OutlineInputBorder(),
        ),
        value: _selectedBlock!.properties['patternType'] ?? 'kente',
        items: const [
          DropdownMenuItem(value: 'kente', child: Text('Kente')),
          DropdownMenuItem(value: 'adinkra', child: Text('Adinkra')),
          DropdownMenuItem(value: 'mud_cloth', child: Text('Mud Cloth')),
        ],
        onChanged: (value) {
          if (value != null) {
            final blockProvider = Provider.of<BlockProvider>(context, listen: false);
            final updatedProperties = Map<String, dynamic>.from(_selectedBlock!.properties);
            updatedProperties['patternType'] = value;
            blockProvider.updateBlockProperties(_selectedBlock!.id, updatedProperties);
          }
        },
      ),
    ];
  }

  /// Build properties specific to color blocks
  List<Widget> _buildColorProperties() {
    final Color currentColor = _parseColor(_selectedBlock!.properties['color'] ?? '#FF0000');

    return [
      const Text('Color Properties', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _colorToHex(currentColor),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    ];
  }

  /// Build properties specific to loop blocks
  List<Widget> _buildLoopProperties() {
    return [
      const Text('Loop Properties', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Iterations',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        initialValue: _selectedBlock!.properties['iterations']?.toString() ?? '3',
        onChanged: (value) {
          final blockProvider = Provider.of<BlockProvider>(context, listen: false);
          final updatedProperties = Map<String, dynamic>.from(_selectedBlock!.properties);
          updatedProperties['iterations'] = int.tryParse(value) ?? 3;
          blockProvider.updateBlockProperties(_selectedBlock!.id, updatedProperties);
        },
      ),
    ];
  }

  /// Parse a color from a hex string
  Color _parseColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Convert a color to a hex string
  String _colorToHex(Color color) {
    final int a = (color.a * 255).round();
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();
    final int argb = (a << 24) | (r << 16) | (g << 8) | b;
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Submit the current solution for evaluation
  void _submitSolution() {
    // First validate the workspace
    _validateWorkspace(showFeedback: true);

    if (!_isValid) {
      // Show error message if workspace is not valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the issues with your solution before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // We don't need to export the workspace here, just validate it

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Evaluating your solution...'),
          ],
        ),
      ),
    );

    // Simulate evaluation delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Solution Accepted!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text('Great job! Your solution has been accepted.'),
                const SizedBox(height: 8),
                Text('You\'ve completed the "${_currentChallenge?.title ?? 'Pattern'}" challenge.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  // Navigate back to the story screen
                  if (widget.onSolutionAccepted != null) {
                    widget.onSolutionAccepted!();
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    });
  }
}

