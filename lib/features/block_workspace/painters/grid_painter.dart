import 'package:flutter/material.dart';

/// Custom painter for drawing a grid in the block workspace
///
/// Optimized for performance with efficient rendering techniques.
class GridPainter extends CustomPainter {
  /// Size of each grid cell
  final double gridSize;

  /// Color of the grid lines
  final Color gridColor;

  /// Whether to use optimized rendering
  final bool useOptimizedRendering;

  /// Constructor
  GridPainter({
    required this.gridSize,
    this.gridColor = const Color(0xFFEEEEEE),
    this.useOptimizedRendering = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    if (useOptimizedRendering) {
      _drawOptimizedGrid(canvas, size, paint);
    } else {
      _drawStandardGrid(canvas, size, paint);
    }
  }

  /// Draw grid using standard approach (line by line)
  void _drawStandardGrid(Canvas canvas, Size size, Paint paint) {
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  /// Draw grid using optimized approach (batched paths)
  void _drawOptimizedGrid(Canvas canvas, Size size, Paint paint) {
    // Create paths for vertical and horizontal lines
    final Path verticalPath = Path();
    final Path horizontalPath = Path();

    // Calculate visible grid area
    final int startX = 0;
    final int endX = (size.width / gridSize).ceil();
    final int startY = 0;
    final int endY = (size.height / gridSize).ceil();

    // Add vertical lines to path
    for (int i = startX; i <= endX; i++) {
      final double x = i * gridSize;
      verticalPath.moveTo(x, 0);
      verticalPath.lineTo(x, size.height);
    }

    // Add horizontal lines to path
    for (int i = startY; i <= endY; i++) {
      final double y = i * gridSize;
      horizontalPath.moveTo(0, y);
      horizontalPath.lineTo(size.width, y);
    }

    // Draw both paths at once
    canvas.drawPath(verticalPath, paint);
    canvas.drawPath(horizontalPath, paint);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
           oldDelegate.gridColor != gridColor ||
           oldDelegate.useOptimizedRendering != useOptimizedRendering;
  }
}
