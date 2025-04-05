import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';

import 'package:kente_codeweaver/core/utils/service_locator.dart';
import 'package:kente_codeweaver/features/challenges/interfaces/challenge_interface.dart';

/// Screen for the block workspace
class BlockWorkspaceScreen extends StatefulWidget {
  /// Challenge ID
  final String challengeId;

  /// Constructor
  const BlockWorkspaceScreen({
    super.key,
    required this.challengeId,
  });

  @override
  State<BlockWorkspaceScreen> createState() => _BlockWorkspaceScreenState();
}

class _BlockWorkspaceScreenState extends State<BlockWorkspaceScreen> {
  /// Block provider
  late BlockProvider _blockProvider;

  // We'll use the provider directly when needed

  /// Challenge interface
  late ChallengeInterface _challengeInterface;

  /// Selected block ID
  String? _selectedBlockId;

  /// Is loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _blockProvider = Provider.of<BlockProvider>(context, listen: false);

    // Get challenge interface from service locator
    _challengeInterface = ServiceLocator.getService<ChallengeInterface>();

    _initializeWorkspace();
  }

  /// Initialize the workspace
  Future<void> _initializeWorkspace() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get required block types for the challenge
      final requiredBlockTypes = _challengeInterface.getRequiredBlockTypes(widget.challengeId);

      // Prepare the challenge
      await _challengeInterface.prepareChallenge(widget.challengeId, requiredBlockTypes);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize workspace: ${e.toString()}')),
        );
      }
    }
  }

  /// Handle block selection
  void _handleBlockSelection(String blockId) {
    setState(() {
      _selectedBlockId = blockId;
    });
  }

  /// Handle block deletion
  void _handleBlockDeletion(String blockId) {
    _blockProvider.removeBlock(blockId);

    setState(() {
      if (_selectedBlockId == blockId) {
        _selectedBlockId = null;
      }
    });
  }

  /// Handle solution submission
  Future<void> _handleSolutionSubmission() async {
    try {
      // Validate the solution
      final isValid = await _challengeInterface.validateSolution();

      if (mounted) {
        if (isValid) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Challenge completed successfully!')),
          );

          // Navigate back
          Navigator.pop(context, true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Challenge validation failed. Try again.')),
          );
        }
      }
    } catch (e) {
      // Show error message if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to validate solution: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Block Workspace'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // Show hint
              final hint = _challengeInterface.getHint(widget.challengeId);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Hint'),
                  content: Text(hint),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              // Reset challenge
              await _challengeInterface.resetChallenge(widget.challengeId);

              // Reinitialize workspace
              await _initializeWorkspace();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<BlockProvider>(
              builder: (context, blockProvider, _) {
                return Column(
                  children: [
                    // Block palette
                    Container(
                      height: 100,
                      padding: EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: blockProvider.availableBlockTypes.length,
                        itemBuilder: (context, index) {
                          final blockType = blockProvider.availableBlockTypes[index];

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Draggable<String>(
                              data: blockType.toString().split('.').last,
                              feedback: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(179),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    blockType.toString().split('.').last,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    blockType.toString().split('.').last,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Workspace
                    Expanded(
                      child: DragTarget<String>(
                        onAcceptWithDetails: (details) {
                          final blockTypeStr = details.data;
                          // Add block to workspace
                          final newBlockId = blockProvider.addBlockFromType(blockTypeStr);

                          // Select the new block if valid
                          if (newBlockId.isNotEmpty) {
                            _handleBlockSelection(newBlockId);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Stack(
                            children: [
                              // Grid background
                              Container(
                                color: Colors.grey[100],
                                child: CustomPaint(
                                  painter: GridPainter(),
                                  child: Container(),
                                ),
                              ),

                              // Blocks
                              ...blockProvider.blocks.map((block) {
                                return Positioned(
                                  left: block.position.dx,
                                  top: block.position.dy,
                                  child: GestureDetector(
                                    onTap: () => _handleBlockSelection(block.id),
                                    onPanUpdate: (details) {
                                      blockProvider.updateBlockPosition(
                                        block.id,
                                        Offset(
                                          block.position.dx + details.delta.dx,
                                          block.position.dy + details.delta.dy,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _selectedBlockId == block.id
                                            ? Colors.blue[700]
                                            : Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                        border: _selectedBlockId == block.id
                                            ? Border.all(color: Colors.yellow, width: 2)
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          block.type.toString().split('.').last,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),

                    // Properties panel
                    if (_selectedBlockId != null)
                      Container(
                        height: 150,
                        padding: EdgeInsets.all(8),
                        color: Colors.grey[300],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Block Properties',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Block ID: $_selectedBlockId'),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _handleBlockDeletion(_selectedBlockId!),
                                ),
                              ],
                            ),
                            // Add more properties here
                          ],
                        ),
                      ),

                    // Submit button
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _handleSolutionSubmission,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text('Submit Solution'),

                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Grid painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }

    // Draw vertical lines
    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
