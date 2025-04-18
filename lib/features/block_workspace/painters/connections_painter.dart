import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';

/// A custom painter that draws connection lines between blocks
///
/// Optimized for performance with efficient rendering and caching.
class ConnectionsPainter extends CustomPainter {
  /// The blocks to draw connections for
  final List<BlockModel> blocks;

  /// ID of the currently highlighted block
  final String? highlightedBlockId;

  /// Cached connection data for quick access
  final Map<String, Map<String, dynamic>> _connectionCache = {};

  /// Hash of the current block configuration for quick comparison
  int? _blocksHash;

  /// Creates a connections painter
  ConnectionsPainter({
    required this.blocks,
    this.highlightedBlockId,
  }) {
    // Calculate blocks hash for quick comparison
    _updateBlocksHash();
  }

  /// Updates the blocks hash based on the current blocks
  void _updateBlocksHash() {
    final blockIds = blocks.map((b) => b.id).join();
    final blockPositions = blocks.map((b) => '${b.position.dx},${b.position.dy}').join();
    final blockConnections = blocks
        .expand((b) => b.connections)
        .where((c) => c.connectedToId != null)
        .map((c) => '${c.id}-${c.connectedToId}')
        .join();

    _blocksHash = Object.hash(blockIds, blockPositions, blockConnections);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint style for connections
    final regularPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Get all valid connections
    final connections = _getValidConnections();

    // Draw all connections
    for (final connection in connections) {
      final startPoint = connection['startPoint'] as Offset;
      final endPoint = connection['endPoint'] as Offset;
      final isHighlighted = connection['isHighlighted'] as bool;

      // Draw the connection line with appropriate paint
      canvas.drawLine(startPoint, endPoint, isHighlighted ? highlightPaint : regularPaint);

      // Draw a small dot at the midpoint to enhance visibility
      final midPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        (startPoint.dy + endPoint.dy) / 2,
      );

      canvas.drawCircle(
        midPoint,
        3,
        Paint()..color = Colors.black45,
      );

      // Draw direction indicator (small triangle)
      _drawDirectionIndicator(canvas, startPoint, endPoint);
    }
  }

  /// Gets all valid connections between blocks
  List<Map<String, dynamic>> _getValidConnections() {
    // Create a cache key based on blocks hash and highlighted block
    final cacheKey = '${_blocksHash}_$highlightedBlockId';

    // Check if we have cached connection data
    if (_connectionCache.containsKey(cacheKey)) {
      return _connectionCache[cacheKey]!['connections'] as List<Map<String, dynamic>>;
    }

    // Calculate all valid connections
    final List<Map<String, dynamic>> connections = [];

    for (var block in blocks) {
      for (var conn in block.connections) {
        if (conn.connectedToId != null) {
          // Find the connected block
          BlockModel? connectedBlock;
          try {
            connectedBlock = blocks.firstWhere((b) => b.id == conn.connectedToId);
          } catch (e) {
            continue; // Skip if connected block not found
          }

          // Find the corresponding connection point on the connected block
          BlockConnection? targetConn;
          try {
            targetConn = connectedBlock.connections.firstWhere(
              (c) => c.connectedToId == block.id
            );
          } catch (e) {
            continue; // Skip if paired connection not found
          }

          // Calculate start and end points
          final startPoint = Offset(
            block.position.dx + conn.position.dx,
            block.position.dy + conn.position.dy,
          );

          final endPoint = Offset(
            connectedBlock.position.dx + targetConn.position.dx,
            connectedBlock.position.dy + targetConn.position.dy,
          );

          // Determine if this connection should be highlighted
          final bool isHighlighted = highlightedBlockId != null &&
                                    (block.id == highlightedBlockId ||
                                     connectedBlock.id == highlightedBlockId);

          // Add connection data to the list
          connections.add({
            'startPoint': startPoint,
            'endPoint': endPoint,
            'isHighlighted': isHighlighted,
            'sourceBlockId': block.id,
            'targetBlockId': connectedBlock.id,
          });
        }
      }
    }

    // Cache the connection data
    _connectionCache[cacheKey] = {
      'connections': connections,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return connections;
  }

  /// Draws a small triangle indicating connection direction
  void _drawDirectionIndicator(Canvas canvas, Offset start, Offset end) {
    // Calculate direction vector
    final directionVector = end - start;
    final length = directionVector.distance;

    // Position indicator at 70% of the way from start to end
    final indicatorPosition = start + directionVector * 0.7;

    // Calculate perpendicular vector for triangle base
    final normalized = directionVector / length;
    final perpendicular = Offset(-normalized.dy, normalized.dx) * 4;

    // Calculate triangle points
    final point1 = indicatorPosition + normalized * 6;
    final point2 = indicatorPosition - perpendicular - normalized * 2;
    final point3 = indicatorPosition + perpendicular - normalized * 2;

    // Draw filled triangle
    final path = Path()
      ..moveTo(point1.dx, point1.dy)
      ..lineTo(point2.dx, point2.dy)
      ..lineTo(point3.dx, point3.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill
    );
  }

  @override
  bool shouldRepaint(ConnectionsPainter oldDelegate) {
    // Quick check using blocks hash
    if (_blocksHash != oldDelegate._blocksHash) {
      return true;
    }

    // Check if the highlighted block has changed
    if (highlightedBlockId != oldDelegate.highlightedBlockId) {
      return true;
    }

    // No changes detected
    return false;
  }
}
