import 'package:flutter/material.dart';

/// A simple chart widget for displaying analytics data
class AnalyticsChart extends StatelessWidget {
  /// The data to display
  final List<Map<String, dynamic>> data;
  
  /// The height of the chart
  final double height;
  
  /// The color of the bars or lines
  final Color color;
  
  /// The type of chart
  final ChartType type;
  
  /// Create an analytics chart
  const AnalyticsChart({
    Key? key,
    required this.data,
    this.height = 200,
    this.color = Colors.blue,
    this.type = ChartType.bar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }
    
    return SizedBox(
      height: height,
      child: type == ChartType.bar
          ? _buildBarChart()
          : _buildLineChart(),
    );
  }
  
  Widget _buildBarChart() {
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final item in data) {
      final value = _getValue(item);
      if (value > maxValue) {
        maxValue = value;
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final value = _getValue(item);
        final label = _getLabel(item);
        
        // Calculate bar height as a percentage of the maximum value
        final percentage = maxValue > 0 ? value / maxValue : 0;
        final barHeight = percentage * (height - 40); // Leave space for labels
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildLineChart() {
    return CustomPaint(
      size: Size.infinite,
      painter: LineChartPainter(
        data: data,
        color: color,
      ),
    );
  }
  
  double _getValue(Map<String, dynamic> item) {
    // Try to find a numeric value in the item
    for (final entry in item.entries) {
      if (entry.value is num) {
        return (entry.value as num).toDouble();
      }
    }
    return 0.0;
  }
  
  String _getLabel(Map<String, dynamic> item) {
    // Try to find a string value in the item for the label
    for (final entry in item.entries) {
      if (entry.value is String) {
        return entry.value as String;
      }
    }
    return '';
  }
}

/// The type of chart to display
enum ChartType {
  /// A bar chart
  bar,
  
  /// A line chart
  line,
}

/// A custom painter for drawing line charts
class LineChartPainter extends CustomPainter {
  /// The data to display
  final List<Map<String, dynamic>> data;
  
  /// The color of the line
  final Color color;
  
  /// Create a line chart painter
  LineChartPainter({
    required this.data,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final item in data) {
      for (final entry in item.entries) {
        if (entry.value is num && (entry.value as num).toDouble() > maxValue) {
          maxValue = (entry.value as num).toDouble();
        }
      }
    }
    
    // Draw the line
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double value = 0;
      
      // Find the numeric value
      for (final entry in item.entries) {
        if (entry.value is num) {
          value = (entry.value as num).toDouble();
          break;
        }
      }
      
      // Calculate position
      final x = i * (size.width / (data.length - 1));
      final y = size.height - (value / maxValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Draw dots at each data point
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw labels
    final textStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 10,
    );
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      String label = '';
      
      // Find the string value for the label
      for (final entry in item.entries) {
        if (entry.value is String) {
          label = entry.value as String;
          break;
        }
      }
      
      if (label.isNotEmpty) {
        final x = i * (size.width / (data.length - 1));
        final textSpan = TextSpan(
          text: label,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // Center the text under the data point
        final textX = x - (textPainter.width / 2);
        final textY = size.height + 4;
        
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
