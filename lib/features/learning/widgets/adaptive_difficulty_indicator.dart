import 'package:flutter/material.dart';

/// A widget that displays the current difficulty level
class AdaptiveDifficultyIndicator extends StatelessWidget {
  /// The current difficulty level (1-5)
  final int difficultyLevel;
  
  /// Create an adaptive difficulty indicator
  const AdaptiveDifficultyIndicator({
    Key? key,
    required this.difficultyLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            return Container(
              width: 12,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: level <= difficultyLevel
                    ? _getDifficultyColor(level)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Difficulty: ${_getDifficultyLabel(difficultyLevel)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getDifficultyLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }
}
