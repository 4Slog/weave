import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';

/// A custom painter that draws connection lines between blocks
class ConnectionsPainter extends CustomPainter {
  final List<BlockModel> blocks;
  final String? highlightedBlockId;

  ConnectionsPainter({
    required this.blocks,
    this.highlightedBlockId,
  });

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

    // Draw lines between connected blocks
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
    }
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
    // Check if the highlighted block has changed
    if (highlightedBlockId != oldDelegate.highlightedBlockId) {
      return true;
    }

    // Repaint if the blocks have changed
    if (blocks.length != oldDelegate.blocks.length) {
      return true;
    }

    // Check if any block position changed
    for (int i = 0; i < blocks.length; i++) {
      if (i >= oldDelegate.blocks.length) {
        return true;
      }
      if (blocks[i].position != oldDelegate.blocks[i].position) {
        return true;
      }

      // Check if connections changed
      for (int j = 0; j < blocks[i].connections.length; j++) {
        if (j >= oldDelegate.blocks[i].connections.length) {
          return true;
        }
        if (blocks[i].connections[j].connectedToId !=
            oldDelegate.blocks[i].connections[j].connectedToId) {
          return true;
        }
      }
    }

    return false;
  }
}
