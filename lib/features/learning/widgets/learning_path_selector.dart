import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';

/// A widget for selecting a learning path type
class LearningPathSelector extends StatelessWidget {
  /// The currently selected learning path type
  final LearningPathType selectedPathType;
  
  /// Callback when a path type is selected
  final Function(LearningPathType) onPathSelected;
  
  /// Create a learning path selector
  const LearningPathSelector({
    Key? key,
    required this.selectedPathType,
    required this.onPathSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Learning Path',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPathOption(
              context,
              LearningPathType.logicBased,
              'Logic Explorer',
              'Structured learning focused on logical reasoning',
              Icons.psychology,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildPathOption(
              context,
              LearningPathType.creativityBased,
              'Creative Weaver',
              'Open-ended learning focused on creative expression',
              Icons.palette,
              Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildPathOption(
              context,
              LearningPathType.challengeBased,
              'Challenge Seeker',
              'Mastery through increasingly difficult challenges',
              Icons.fitness_center,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPathOption(
    BuildContext context,
    LearningPathType pathType,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedPathType == pathType;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onPathSelected(pathType),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
