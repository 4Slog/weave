import 'package:flutter/material.dart';

/// Custom painter for drawing a grid in the block workspace
class GridPainter extends CustomPainter {
  /// Size of each grid cell
  final double gridSize;
  
  /// Color of the grid lines
  final Color gridColor;
  
  /// Constructor
  GridPainter({
    required this.gridSize,
    this.gridColor = const Color(0xFFEEEEEE),
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    
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
  
  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize || 
           oldDelegate.gridColor != gridColor;
  }
}
