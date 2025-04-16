import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/core/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// A custom painter for rendering Kente-inspired patterns based on block collections.
///
/// This painter transforms block-based code into visual textile patterns,
/// simulating the way Kente cloth is woven with different colors and motifs.
///
/// Optimized for performance with caching and efficient rendering techniques.
class PatternPainter extends CustomPainter {
  /// The block collection to render as a pattern
  final BlockCollection blockCollection;

  /// Whether to show the grid lines
  final bool showGrid;

  /// Grid cell size
  final double gridSize;

  /// Border width for pattern elements
  final double borderWidth;

  /// Scale factor for zooming
  final double scale;

  /// Whether this is a dark theme
  final bool darkMode;

  /// Custom render options
  final Map<String, dynamic>? renderOptions;

  /// Cached pattern analysis result
  Map<String, dynamic>? _cachedPatternInfo;

  /// Cached pattern hash for quick comparison
  int? _patternHash;

  /// Cached rendered image for complex patterns
  ui.Image? _cachedImage;

  /// Whether to use image caching for complex patterns
  final bool useImageCaching;

  /// Creates a pattern painter
  PatternPainter({
    required this.blockCollection,
    this.showGrid = false,
    this.gridSize = 20.0,
    this.borderWidth = 1.0,
    this.scale = 1.0,
    this.darkMode = false,
    this.renderOptions,
    this.useImageCaching = true,
  }) {
    // Calculate pattern hash for quick comparison
    _updatePatternHash();
  }

  /// Updates the pattern hash based on the current block collection
  void _updatePatternHash() {
    final blockIds = blockCollection.blocks.map((b) => b.id).join();
    final blockPositions = blockCollection.blocks.map((b) => '${b.position.dx},${b.position.dy}').join();
    final blockConnections = blockCollection.blocks
        .expand((b) => b.connections)
        .where((c) => c.connectedToId != null)
        .map((c) => '${c.id}-${c.connectedToId}')
        .join();

    _patternHash = Object.hash(blockIds, blockPositions, blockConnections);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Exit early if no blocks to render
    if (blockCollection.blocks.isEmpty) {
      _drawEmptyPattern(canvas, size);
      return;
    }

    // Apply scale transformation
    canvas.save();
    canvas.scale(scale);

    // Draw the grid if needed
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Check if we can use the cached image for complex patterns
    if (useImageCaching && _cachedImage != null && _isComplexPattern()) {
      // Draw the cached image
      final src = Rect.fromLTWH(0, 0, _cachedImage!.width.toDouble(), _cachedImage!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width / scale, size.height / scale);
      canvas.drawImageRect(_cachedImage!, src, dst, Paint());
    } else {
      // First, process and analyze the block collection to determine:
      // 1. What patterns are being created
      // 2. What colors are being used
      // 3. How blocks are connected to each other
      final patternInfo = _getPatternInfo();

      // Then, render the pattern based on the analysis
      _renderPattern(canvas, size, patternInfo);

      // Cache the rendered image for complex patterns
      if (useImageCaching && _isComplexPattern()) {
        _cacheRenderedPattern(size);
      }
    }

    canvas.restore();
  }

  /// Determines if the current pattern is complex enough to warrant caching
  bool _isComplexPattern() {
    // Consider a pattern complex if it has more than 5 blocks or uses complex patterns
    return blockCollection.blocks.length > 5 ||
           blockCollection.blocks.any((b) =>
              b.type == BlockType.pattern &&
              (b.properties['patternType'] == 'diamond' || b.properties['patternType'] == 'zigzag'));
  }

  /// Gets pattern info, using cache if available
  Map<String, dynamic> _getPatternInfo() {
    // Use cached pattern info if available and pattern hasn't changed
    if (_cachedPatternInfo != null) {
      return _cachedPatternInfo!;
    }

    // Analyze the block collection
    _cachedPatternInfo = _analyzeBlockCollection();
    return _cachedPatternInfo!;
  }

  /// Caches the rendered pattern as an image
  Future<void> _cacheRenderedPattern(Size size) async {
    // This would be implemented with a PictureRecorder in a real implementation
    // For now, we'll just mark it as a TODO
    // TODO: Implement pattern caching using PictureRecorder
  }

  /// Draw an empty pattern with help text
  void _drawEmptyPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = darkMode ? Colors.grey[700]! : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Add blocks to create a pattern',
        style: TextStyle(
          color: darkMode ? Colors.white70 : Colors.grey[700]!,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  /// Draw grid lines
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = darkMode ? Colors.grey[800]! : Colors.grey[300]!
      ..strokeWidth = 0.5;

    // Calculate grid dimensions
    final horizontalLines = (size.height / (gridSize / scale)).ceil();
    final verticalLines = (size.width / (gridSize / scale)).ceil();

    // Draw horizontal lines
    for (int i = 0; i <= horizontalLines; i++) {
      final y = i * (gridSize / scale);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width / scale, y),
        paint,
      );
    }

    // Draw vertical lines
    for (int i = 0; i <= verticalLines; i++) {
      final x = i * (gridSize / scale);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height / scale),
        paint,
      );
    }
  }

  /// Analyze the block collection to determine pattern structure
  Map<String, dynamic> _analyzeBlockCollection() {
    // Results to return
    final Map<String, dynamic> result = {
      'patterns': <String>[],
      'colors': <String>[],
      'loopFactors': <String, int>{},
      'mainStructureType': 'horizontal', // Or 'vertical', 'grid'
      'blocks': <String, Map<String, dynamic>>{},
      'connections': <Map<String, String>>[],
    };

    // Helper to add block info to result
    void addBlockInfo(BlockModel block) {
      result['blocks'][block.id] = {
        'type': block.type.toString().split('.').last,
        'position': {'x': block.position.dx, 'y': block.position.dy},
        'properties': Map<String, dynamic>.from(block.properties),
      };

      // Collect pattern types
      if (block.type == BlockType.pattern &&
          block.properties['patternType'] != null) {
        result['patterns'].add(block.properties['patternType'].toString());
      }

      // Collect colors
      if (block.type == BlockType.color &&
          block.properties['color'] != null) {
        result['colors'].add(block.properties['color'].toString());
      }

      // Collect loop factors
      if (block.type == BlockType.loop &&
          block.properties['count'] != null) {
        final String loopId = block.id;
        final int count = int.tryParse(block.properties['count'].toString()) ?? 3;
        result['loopFactors'][loopId] = count;
      }
    }

    // Add all blocks to the result
    for (final block in blockCollection.blocks) {
      addBlockInfo(block);
    }

    // Process connections
    for (final block in blockCollection.blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null && connection.connectedToPointId != null) {
          // Only add connection once (to avoid duplicates)
          final otherBlock = blockCollection.findBlockById(connection.connectedToId!);
          if (otherBlock != null && block.id.compareTo(otherBlock.id) < 0) {
            result['connections'].add({
              'sourceId': block.id,
              'sourceType': block.type.toString().split('.').last,
              'targetId': otherBlock.id,
              'targetType': otherBlock.type.toString().split('.').last,
            });
          }
        }
      }
    }

    // Determine main structure type based on block arrangements
    result['mainStructureType'] = _determineStructureType();

    return result;
  }

  /// Determine the overall structure type based on block arrangements
  String _determineStructureType() {
    // Count blocks by type
    int patternCount = 0;
    int loopCount = 0;
    int colorCount = 0;
    int structureCount = 0;

    for (final block in blockCollection.blocks) {
      switch (block.type) {
        case BlockType.pattern:
          patternCount++;
          break;
        case BlockType.loop:
          loopCount++;
          break;
        case BlockType.color:
          colorCount++;
          break;
        case BlockType.structure:
        case BlockType.column:
          structureCount++;
          break;
        default:
          break;
      }
    }

    // Look at block positions to determine layout
    bool isHorizontal = true;
    bool isVertical = true;
    bool isGrid = false;

    // Check for horizontal alignment
    if (blockCollection.blocks.length >= 2) {
      final blocks = blockCollection.blocks;
      final sortedByY = List<BlockModel>.from(blocks)
        ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

      // If blocks are roughly at same Y position, they're horizontal
      isHorizontal = (sortedByY.last.position.dy - sortedByY.first.position.dy) < gridSize * 2;

      // Check for vertical alignment
      final sortedByX = List<BlockModel>.from(blocks)
        ..sort((a, b) => a.position.dx.compareTo(b.position.dx));

      // If blocks are roughly at same X position, they're vertical
      isVertical = (sortedByX.last.position.dx - sortedByX.first.position.dx) < gridSize * 2;

      // Check for grid pattern
      isGrid = !isHorizontal && !isVertical && loopCount > 0;
    }

    // Determine structure type
    if (isGrid) {
      return 'grid';
    } else if (isVertical) {
      return 'vertical';
    } else {
      return 'horizontal'; // Default
    }
  }

  /// Render the pattern based on analysis results
  void _renderPattern(Canvas canvas, Size size, Map<String, dynamic> patternInfo) {
    final String structureType = patternInfo['mainStructureType'];
    final List<String> colors = List<String>.from(patternInfo['colors']);
    final List<String> patterns = List<String>.from(patternInfo['patterns']);

    // Use default colors if none specified
    if (colors.isEmpty) {
      colors.add('black');
      colors.add('gold');
    }

    // Use default pattern if none specified
    if (patterns.isEmpty) {
      patterns.add('checker');
    }

    // Determine pattern area
    final Rect patternArea = _calculatePatternArea(size);

    // Render based on structure type
    switch (structureType) {
      case 'horizontal':
        _renderHorizontalPattern(canvas, patternArea, patterns, colors, patternInfo);
        break;
      case 'vertical':
        _renderVerticalPattern(canvas, patternArea, patterns, colors, patternInfo);
        break;
      case 'grid':
        _renderGridPattern(canvas, patternArea, patterns, colors, patternInfo);
        break;
      default:
        _renderDefaultPattern(canvas, patternArea, patterns, colors);
        break;
    }
  }

  /// Calculate the area to render the pattern
  Rect _calculatePatternArea(Size size) {
    final margin = 20.0; // Margin from edges

    return Rect.fromLTWH(
      margin,
      margin,
      (size.width / scale) - (margin * 2),
      (size.height / scale) - (margin * 2),
    );
  }

  /// Render a horizontal pattern (stripes across)
  void _renderHorizontalPattern(
    Canvas canvas,
    Rect area,
    List<String> patterns,
    List<String> colors,
    Map<String, dynamic> patternInfo,
  ) {
    final double stripeHeight = math.min(area.height / 5, 40);
    final int stripeCount = (area.height / stripeHeight).floor();
    final double actualStripeHeight = area.height / stripeCount;

    // Determine repetition factor from loops
    final loopFactors = patternInfo['loopFactors'] as Map<String, int>;
    final int repetitionFactor = loopFactors.isEmpty ? 1 : loopFactors.values.fold(0, (a, b) => a + b) ~/ loopFactors.length;

    // Pattern functions
    final patternFunctions = {
      'checker': (Canvas c, Rect r, Color color1, Color color2) => _drawCheckerPattern(c, r, color1, color2),
      'zigzag': (Canvas c, Rect r, Color color1, Color color2) => _drawZigzagPattern(c, r, color1, color2),
      'diamond': (Canvas c, Rect r, Color color1, Color color2) => _drawDiamondPattern(c, r, color1, color2),
      'stripes': (Canvas c, Rect r, Color color1, Color color2) => _drawStripesPattern(c, r, color1, color2),
      'dots': (Canvas c, Rect r, Color color1, Color color2) => _drawDotsPattern(c, r, color1, color2),
    };

    // Draw each stripe with a pattern
    for (int i = 0; i < stripeCount; i++) {
      final patternType = patterns[i % patterns.length];
      final color1 = _parseColor(colors[i % colors.length]);
      final color2 = _parseColor(colors[(i + 1) % colors.length]);

      final stripeRect = Rect.fromLTWH(
        area.left,
        area.top + (i * actualStripeHeight),
        area.width,
        actualStripeHeight,
      );

      // Determine if this stripe should be repeated (based on loops)
      final isRepeated = i % repetitionFactor == 0;

      // Draw base stripe
      final Paint stripePaint = Paint()
        ..color = color1.withAlpha(25)
        ..style = PaintingStyle.fill;

      canvas.drawRect(stripeRect, stripePaint);

      // Apply pattern
      if (patternFunctions.containsKey(patternType)) {
        patternFunctions[patternType]!(canvas, stripeRect, color1, color2);
      } else {
        // Default to checker pattern
        _drawCheckerPattern(canvas, stripeRect, color1, color2);
      }

      // Draw stripe border
      final Paint borderPaint = Paint()
        ..color = darkMode ? Colors.grey[700]! : Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;

      canvas.drawRect(stripeRect, borderPaint);

      // Indicate repetition
      if (isRepeated && i > 0) {
        _drawRepetitionIndicator(canvas, stripeRect);
      }
    }
  }

  /// Render a vertical pattern (columns)
  void _renderVerticalPattern(
    Canvas canvas,
    Rect area,
    List<String> patterns,
    List<String> colors,
    Map<String, dynamic> patternInfo,
  ) {
    final double stripeWidth = math.min(area.width / 5, 40);
    final int stripeCount = (area.width / stripeWidth).floor();
    final double actualStripeWidth = area.width / stripeCount;

    // Determine repetition factor from loops
    final loopFactors = patternInfo['loopFactors'] as Map<String, int>;
    final int repetitionFactor = loopFactors.isEmpty ? 1 : loopFactors.values.fold(0, (a, b) => a + b) ~/ loopFactors.length;

    // Pattern functions
    final patternFunctions = {
      'checker': (Canvas c, Rect r, Color color1, Color color2) => _drawCheckerPattern(c, r, color1, color2, vertical: true),
      'zigzag': (Canvas c, Rect r, Color color1, Color color2) => _drawZigzagPattern(c, r, color1, color2, vertical: true),
      'diamond': (Canvas c, Rect r, Color color1, Color color2) => _drawDiamondPattern(c, r, color1, color2),
      'stripes': (Canvas c, Rect r, Color color1, Color color2) => _drawStripesPattern(c, r, color1, color2, vertical: true),
      'dots': (Canvas c, Rect r, Color color1, Color color2) => _drawDotsPattern(c, r, color1, color2),
    };

    // Draw each stripe with a pattern
    for (int i = 0; i < stripeCount; i++) {
      final patternType = patterns[i % patterns.length];
      final color1 = _parseColor(colors[i % colors.length]);
      final color2 = _parseColor(colors[(i + 1) % colors.length]);

      final stripeRect = Rect.fromLTWH(
        area.left + (i * actualStripeWidth),
        area.top,
        actualStripeWidth,
        area.height,
      );

      // Determine if this stripe should be repeated (based on loops)
      final isRepeated = i % repetitionFactor == 0;

      // Draw base stripe
      final Paint stripePaint = Paint()
        ..color = color1.withAlpha(25)
        ..style = PaintingStyle.fill;

      canvas.drawRect(stripeRect, stripePaint);

      // Apply pattern
      if (patternFunctions.containsKey(patternType)) {
        patternFunctions[patternType]!(canvas, stripeRect, color1, color2);
      } else {
        // Default to checker pattern
        _drawCheckerPattern(canvas, stripeRect, color1, color2, vertical: true);
      }

      // Draw stripe border
      final Paint borderPaint = Paint()
        ..color = darkMode ? Colors.grey[700]! : Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;

      canvas.drawRect(stripeRect, borderPaint);

      // Indicate repetition
      if (isRepeated && i > 0) {
        _drawRepetitionIndicator(canvas, stripeRect, vertical: true);
      }
    }
  }

  /// Render a grid pattern
  void _renderGridPattern(
    Canvas canvas,
    Rect area,
    List<String> patterns,
    List<String> colors,
    Map<String, dynamic> patternInfo,
  ) {
    final int cellSize = math.min(area.width, area.height) ~/ 8;
    final int rowCount = (area.height / cellSize).floor();
    final int colCount = (area.width / cellSize).floor();

    // Determine repetition factors from loops
    final loopFactors = patternInfo['loopFactors'] as Map<String, int>;
    final int rowRepeat = loopFactors.isEmpty ? 2 : loopFactors.values.fold(1, (a, b) => a * b);
    final int colRepeat = loopFactors.isEmpty ? 2 : loopFactors.values.fold(1, (a, b) => a * b);

    // Pattern functions
    final patternFunctions = {
      'checker': (Canvas c, Rect r, Color color1, Color color2) => _drawCheckerCell(c, r, color1, color2),
      'zigzag': (Canvas c, Rect r, Color color1, Color color2) => _drawZigzagCell(c, r, color1, color2),
      'diamond': (Canvas c, Rect r, Color color1, Color color2) => _drawDiamondCell(c, r, color1, color2),
      'stripes': (Canvas c, Rect r, Color color1, Color color2) => _drawStripesCell(c, r, color1, color2),
      'dots': (Canvas c, Rect r, Color color1, Color color2) => _drawDotsCell(c, r, color1, color2),
    };

    // Draw each cell with a pattern
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final patternType = patterns[(row + col) % patterns.length];
        final color1 = _parseColor(colors[row % colors.length]);
        final color2 = _parseColor(colors[col % colors.length]);

        final cellRect = Rect.fromLTWH(
          area.left + (col * cellSize),
          area.top + (row * cellSize),
          cellSize.toDouble(),
          cellSize.toDouble(),
        );

        // Determine if this cell should be highlighted (based on loops)
        final isRepeated = (row % rowRepeat == 0) && (col % colRepeat == 0);

        // Draw base cell
        final Paint cellPaint = Paint()
          ..color = color1.withAlpha(25)
          ..style = PaintingStyle.fill;

        canvas.drawRect(cellRect, cellPaint);

        // Apply pattern to cell
        if (patternFunctions.containsKey(patternType)) {
          patternFunctions[patternType]!(canvas, cellRect, color1, color2);
        } else {
          // Default to checker pattern
          _drawCheckerCell(canvas, cellRect, color1, color2);
        }

        // Draw cell border
        final Paint borderPaint = Paint()
          ..color = darkMode ? Colors.grey[700]! : Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

        canvas.drawRect(cellRect, borderPaint);

        // Indicate repetition
        if (isRepeated && (row > 0 || col > 0)) {
          _drawRepetitionIndicator(canvas, cellRect, isCell: true);
        }
      }
    }
  }

  /// Render a default pattern if structure can't be determined
  void _renderDefaultPattern(
    Canvas canvas,
    Rect area,
    List<String> patterns,
    List<String> colors,
  ) {
    final String patternType = patterns.isNotEmpty ? patterns.first : 'checker';
    final Color color1 = _parseColor(colors.isNotEmpty ? colors.first : 'black');
    final Color color2 = _parseColor(colors.length > 1 ? colors[1] : 'gold');

    // Draw base rectangle
    final Paint basePaint = Paint()
      ..color = color1.withAlpha(25)
      ..style = PaintingStyle.fill;

    canvas.drawRect(area, basePaint);

    // Apply pattern
    switch (patternType) {
      case 'checker':
        _drawCheckerPattern(canvas, area, color1, color2);
        break;
      case 'zigzag':
        _drawZigzagPattern(canvas, area, color1, color2);
        break;
      case 'diamond':
        _drawDiamondPattern(canvas, area, color1, color2);
        break;
      case 'stripes':
        _drawStripesPattern(canvas, area, color1, color2);
        break;
      case 'dots':
        _drawDotsPattern(canvas, area, color1, color2);
        break;
      default:
        _drawCheckerPattern(canvas, area, color1, color2);
        break;
    }

    // Draw border
    final Paint borderPaint = Paint()
      ..color = darkMode ? Colors.grey[700]! : Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRect(area, borderPaint);
  }

  /// Draw a checker pattern
  void _drawCheckerPattern(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2,
    {bool vertical = false}
  ) {
    final double cellSize = math.min(rect.width, rect.height) / 8;
    final int rowCount = (rect.height / cellSize).ceil();
    final int colCount = (rect.width / cellSize).ceil();

    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final Color cellColor = (row + col) % 2 == 0 ? color1 : color2;
        final Paint paint = Paint()
          ..color = cellColor
          ..style = PaintingStyle.fill;

        final cellRect = Rect.fromLTWH(
          rect.left + (col * cellSize),
          rect.top + (row * cellSize),
          cellSize,
          cellSize,
        );

        canvas.drawRect(cellRect, paint);
      }
    }
  }

  /// Draw a zigzag pattern
  void _drawZigzagPattern(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2,
    {bool vertical = false}
  ) {
    final double segmentSize = math.min(rect.width, rect.height) / 10;
    final Paint paint = Paint()
      ..color = color1
      ..style = PaintingStyle.stroke
      ..strokeWidth = segmentSize / 2;

    final Path path = Path();

    if (!vertical) {
      // Horizontal zigzag
      int segments = (rect.width / segmentSize).ceil();
      double startY = rect.top + rect.height / 2;

      path.moveTo(rect.left, startY);

      for (int i = 0; i < segments; i++) {
        final x1 = rect.left + (i * segmentSize);
        final x2 = rect.left + ((i + 1) * segmentSize);

        if (i % 2 == 0) {
          path.lineTo(x2, startY - segmentSize);
        } else {
          path.lineTo(x2, startY + segmentSize);
        }
      }
    } else {
      // Vertical zigzag
      int segments = (rect.height / segmentSize).ceil();
      double startX = rect.left + rect.width / 2;

      path.moveTo(startX, rect.top);

      for (int i = 0; i < segments; i++) {
        final y1 = rect.top + (i * segmentSize);
        final y2 = rect.top + ((i + 1) * segmentSize);

        if (i % 2 == 0) {
          path.lineTo(startX - segmentSize, y2);
        } else {
          path.lineTo(startX + segmentSize, y2);
        }
      }
    }

    canvas.drawPath(path, paint);

    // Draw second zigzag in alternate color
    paint.color = color2;

    final Path path2 = Path();

    if (!vertical) {
      // Horizontal zigzag (offset)
      int segments = (rect.width / segmentSize).ceil();
      double startY = rect.top + rect.height / 2 + segmentSize * 2;

      path2.moveTo(rect.left, startY);

      for (int i = 0; i < segments; i++) {
        final x1 = rect.left + (i * segmentSize);
        final x2 = rect.left + ((i + 1) * segmentSize);

        if (i % 2 == 0) {
          path2.lineTo(x2, startY - segmentSize);
        } else {
          path2.lineTo(x2, startY + segmentSize);
        }
      }
    } else {
      // Vertical zigzag (offset)
      int segments = (rect.height / segmentSize).ceil();
      double startX = rect.left + rect.width / 2 + segmentSize * 2;

      path2.moveTo(startX, rect.top);

      for (int i = 0; i < segments; i++) {
        final y1 = rect.top + (i * segmentSize);
        final y2 = rect.top + ((i + 1) * segmentSize);

        if (i % 2 == 0) {
          path2.lineTo(startX - segmentSize, y2);
        } else {
          path2.lineTo(startX + segmentSize, y2);
        }
      }
    }

    canvas.drawPath(path2, paint);
  }

  /// Draw a diamond pattern
  void _drawDiamondPattern(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final double size = math.min(rect.width, rect.height) / 4;
    final int rowCount = (rect.height / size).ceil();
    final int colCount = (rect.width / size).ceil();

    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final centerX = rect.left + (col + 0.5) * size;
        final centerY = rect.top + (row + 0.5) * size;

        final path = Path();
        path.moveTo(centerX, centerY - size / 2); // Top
        path.lineTo(centerX + size / 2, centerY); // Right
        path.lineTo(centerX, centerY + size / 2); // Bottom
        path.lineTo(centerX - size / 2, centerY); // Left
        path.close();

        final Paint paint = (row + col) % 2 == 0 ? paint1 : paint2;
        canvas.drawPath(path, paint);
      }
    }
  }

  /// Draw a stripes pattern
  void _drawStripesPattern(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2,
    {bool vertical = false}
  ) {
    final double stripeWidth = math.min(rect.width, rect.height) / 10;
    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    if (!vertical) {
      // Horizontal stripes
      final int stripeCount = (rect.height / stripeWidth).ceil();

      for (int i = 0; i < stripeCount; i++) {
        final Paint paint = i % 2 == 0 ? paint1 : paint2;
        final stripeRect = Rect.fromLTWH(
          rect.left,
          rect.top + (i * stripeWidth),
          rect.width,
          stripeWidth,
        );

        canvas.drawRect(stripeRect, paint);
      }
    } else {
      // Vertical stripes
      final int stripeCount = (rect.width / stripeWidth).ceil();

      for (int i = 0; i < stripeCount; i++) {
        final Paint paint = i % 2 == 0 ? paint1 : paint2;
        final stripeRect = Rect.fromLTWH(
          rect.left + (i * stripeWidth),
          rect.top,
          stripeWidth,
          rect.height,
        );

        canvas.drawRect(stripeRect, paint);
      }
    }
  }

  /// Draw a dots pattern
  void _drawDotsPattern(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final double cellSize = math.min(rect.width, rect.height) / 6;
    final int rowCount = (rect.height / cellSize).ceil();
    final int colCount = (rect.width / cellSize).ceil();

    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final centerX = rect.left + (col + 0.5) * cellSize;
        final centerY = rect.top + (row + 0.5) * cellSize;

        // Switch colors in a checkerboard pattern
        final Paint paint = (row + col) % 2 == 0 ? paint1 : paint2;

        // Draw a dot
        canvas.drawCircle(
          Offset(centerX, centerY),
          cellSize / 4,
          paint,
        );
      }
    }
  }

  /// Draw a repetition indicator to show loop effects
  void _drawRepetitionIndicator(
    Canvas canvas,
    Rect rect,
    {bool vertical = false, bool isCell = false}
  ) {
    final Paint paint = Paint()
      ..color = Colors.white.withAlpha(127)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double size = isCell ?
      math.min(rect.width, rect.height) * 0.3 :
      math.min(rect.width, rect.height) * 0.15;

    final double centerX = rect.left + rect.width / 2;
    final double centerY = rect.top + rect.height / 2;

    final double arrowSize = size * 0.5;

    if (isCell) {
      // For grid cells, draw a rotating arrow
      final path = Path();

      // Draw circle
      canvas.drawCircle(
        Offset(centerX, centerY),
        size,
        paint,
      );

      // Draw arrow head
      path.moveTo(centerX + size, centerY);
      path.lineTo(centerX + size - arrowSize, centerY - arrowSize / 2);
      path.lineTo(centerX + size - arrowSize, centerY + arrowSize / 2);
      path.close();

      // Draw the arrow path
      canvas.drawPath(path, paint);

      // Draw arc
      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size * 2,
        height: size * 2,
      );

      canvas.drawArc(
        rect,
        0,
        math.pi * 1.5,
        false,
        paint,
      );
    } else if (vertical) {
      // For vertical stripes, draw vertical arrows
      final arrowPath = Path();

      // Starting point at bottom
      arrowPath.moveTo(centerX, rect.bottom - size);

      // Arrow to top
      arrowPath.lineTo(centerX, rect.top + size);

      // Arrow head
      arrowPath.moveTo(centerX, rect.top + size);
      arrowPath.lineTo(centerX - arrowSize / 2, rect.top + size + arrowSize);
      arrowPath.moveTo(centerX, rect.top + size);
      arrowPath.lineTo(centerX + arrowSize / 2, rect.top + size + arrowSize);

      canvas.drawPath(arrowPath, paint);
    } else {
      // For horizontal stripes, draw horizontal arrows
      final arrowPath = Path();

      // Starting point at left
      arrowPath.moveTo(rect.left + size, centerY);

      // Arrow to right
      arrowPath.lineTo(rect.right - size, centerY);

      // Arrow head
      arrowPath.moveTo(rect.right - size, centerY);
      arrowPath.lineTo(rect.right - size - arrowSize, centerY - arrowSize / 2);
      arrowPath.moveTo(rect.right - size, centerY);
      arrowPath.lineTo(rect.right - size - arrowSize, centerY + arrowSize / 2);

      canvas.drawPath(arrowPath, paint);
    }
  }

  /// Draw pattern in a grid cell - checker variant
  void _drawCheckerCell(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final double quadrantSize = rect.width / 2;

    final List<Rect> quadrants = [
      // Top left
      Rect.fromLTWH(rect.left, rect.top, quadrantSize, quadrantSize),
      // Top right
      Rect.fromLTWH(rect.left + quadrantSize, rect.top, quadrantSize, quadrantSize),
      // Bottom left
      Rect.fromLTWH(rect.left, rect.top + quadrantSize, quadrantSize, quadrantSize),
      // Bottom right
      Rect.fromLTWH(rect.left + quadrantSize, rect.top + quadrantSize, quadrantSize, quadrantSize),
    ];

    // Fill quadrants with alternating colors
    canvas.drawRect(quadrants[0], Paint()..color = color1);
    canvas.drawRect(quadrants[1], Paint()..color = color2);
    canvas.drawRect(quadrants[2], Paint()..color = color2);
    canvas.drawRect(quadrants[3], Paint()..color = color1);
  }

  /// Draw pattern in a grid cell - zigzag variant
  void _drawZigzagCell(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final Paint paint = Paint()
      ..color = color1
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width / 8;

    final Path zigzagPath = Path();

    // Create zigzag pattern
    zigzagPath.moveTo(rect.left, rect.top + rect.height / 2);
    zigzagPath.lineTo(rect.left + rect.width / 4, rect.top + rect.height / 4);
    zigzagPath.lineTo(rect.left + rect.width / 2, rect.top + rect.height / 2);
    zigzagPath.lineTo(rect.left + rect.width * 3 / 4, rect.top + rect.height * 3 / 4);
    zigzagPath.lineTo(rect.right, rect.top + rect.height / 2);

    canvas.drawPath(zigzagPath, paint);

    // Draw second zigzag in alternate color
    paint.color = color2;

    final Path zigzagPath2 = Path();
    zigzagPath2.moveTo(rect.left, rect.top + rect.height * 3 / 4);
    zigzagPath2.lineTo(rect.left + rect.width / 4, rect.top + rect.height);
    zigzagPath2.lineTo(rect.left + rect.width / 2, rect.top + rect.height * 3 / 4);
    zigzagPath2.lineTo(rect.left + rect.width * 3 / 4, rect.top + rect.height / 2);
    zigzagPath2.lineTo(rect.right, rect.top + rect.height * 3 / 4);

    canvas.drawPath(zigzagPath2, paint);
  }

  /// Draw pattern in a grid cell - diamond variant
  void _drawDiamondCell(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    // Outer diamond (color1)
    final Path outerDiamond = Path();
    final double centerX = rect.left + rect.width / 2;
    final double centerY = rect.top + rect.height / 2;

    outerDiamond.moveTo(centerX, rect.top);
    outerDiamond.lineTo(rect.right, centerY);
    outerDiamond.lineTo(centerX, rect.bottom);
    outerDiamond.lineTo(rect.left, centerY);
    outerDiamond.close();

    canvas.drawPath(outerDiamond, paint1);

    // Inner diamond (color2)
    final Path innerDiamond = Path();
    final double innerSize = rect.width / 3;

    innerDiamond.moveTo(centerX, centerY - innerSize);
    innerDiamond.lineTo(centerX + innerSize, centerY);
    innerDiamond.lineTo(centerX, centerY + innerSize);
    innerDiamond.lineTo(centerX - innerSize, centerY);
    innerDiamond.close();

    canvas.drawPath(innerDiamond, paint2);
  }

  /// Draw pattern in a grid cell - stripes variant
  void _drawStripesCell(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final double stripeWidth = rect.width / 5;

    for (int i = 0; i < 5; i++) {
      final Paint paint = Paint();
      paint.color = i % 2 == 0 ? color1 : color2;

      final Rect stripeRect = Rect.fromLTWH(
        rect.left + (i * stripeWidth),
        rect.top,
        stripeWidth,
        rect.height,
      );

      canvas.drawRect(stripeRect, paint);
    }
  }

  /// Draw pattern in a grid cell - dots variant
  void _drawDotsCell(
    Canvas canvas,
    Rect rect,
    Color color1,
    Color color2
  ) {
    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    final double dotRadius = rect.width / 10;
    final double spacing = rect.width / 5;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final double x = rect.left + spacing + (col * spacing);
        final double y = rect.top + spacing + (row * spacing);

        // Alternate colors in a checkerboard pattern
        final Paint paint = (row + col) % 2 == 0 ? paint1 : paint2;

        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  /// Parse a color from its string representation
  Color _parseColor(String colorStr) {
    // Handle hex color codes
    if (colorStr.startsWith('#')) {
      try {
        return Color(int.parse('0xFF${colorStr.substring(1)}'));
      } catch (e) {
        return Colors.black;
      }
    }

    // Handle named colors
    switch (colorStr.toLowerCase()) {
      case 'black':
        return AppTheme.kenteBlack;
      case 'gold':
        return AppTheme.kenteGold;
      case 'purple':
        return AppTheme.kentePurple;
      case 'green':
        return AppTheme.kenteGreen;
      case 'red':
        return AppTheme.kenteRed;
      case 'white':
        return Colors.white;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.black;
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) {
    // Quick check using pattern hash
    if (_patternHash != oldDelegate._patternHash) {
      return true;
    }

    // Check other properties that affect rendering
    if (oldDelegate.showGrid != showGrid ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.scale != scale ||
        oldDelegate.darkMode != darkMode) {
      return true;
    }

    // Check if render options changed
    if (renderOptions != oldDelegate.renderOptions) {
      // If both are null, they're equal
      if (renderOptions == null && oldDelegate.renderOptions == null) {
        return false;
      }

      // If one is null but not the other, they're different
      if (renderOptions == null || oldDelegate.renderOptions == null) {
        return true;
      }

      // Compare render options maps
      if (renderOptions!.length != oldDelegate.renderOptions!.length) {
        return true;
      }

      // Check each key-value pair
      for (final key in renderOptions!.keys) {
        if (!oldDelegate.renderOptions!.containsKey(key) ||
            renderOptions![key] != oldDelegate.renderOptions![key]) {
          return true;
        }
      }
    }

    // No changes detected
    return false;
  }
}
