import 'package:flutter/material.dart';

/// A card that displays a learning metric
class LearningMetricsCard extends StatelessWidget {
  /// The title of the metric
  final String title;
  
  /// The value of the metric
  final String value;
  
  /// The icon to display
  final IconData icon;
  
  /// The color of the card
  final Color color;
  
  /// Create a learning metrics card
  const LearningMetricsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
