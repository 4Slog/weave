import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

/// A widget that displays the user's progress on a learning path
class LearningPathProgress extends StatelessWidget {
  /// The learning path
  final LearningPath learningPath;
  
  /// The user's progress
  final UserProgress? userProgress;
  
  /// Create a learning path progress widget
  const LearningPathProgress({
    Key? key,
    required this.learningPath,
    this.userProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Learning Journey',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${_getCompletedItemsCount()}/${learningPath.items.length} completed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: learningPath.items.length,
            itemBuilder: (context, index) {
              final item = learningPath.items[index];
              return _buildPathItem(context, item, index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPathItem(BuildContext context, LearningPathItem item, int index) {
    final isCompleted = _isItemCompleted(item);
    final isInProgress = _isItemInProgress(item);
    final isLocked = _isItemLocked(item);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        color: isCompleted
            ? Colors.green[50]
            : isInProgress
                ? Colors.blue[50]
                : isLocked
                    ? Colors.grey[100]
                    : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isInProgress
                              ? Colors.blue
                              : isLocked
                                  ? Colors.grey
                                  : Colors.orange,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : isLocked
                              ? const Icon(Icons.lock, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
                        color: isLocked ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isLocked ? Colors.grey : Colors.black54,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Est. time: ${item.estimatedTimeMinutes} min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (isCompleted)
                _buildStatusChip('Completed', Colors.green)
              else if (isInProgress)
                _buildStatusChip('In Progress', Colors.blue)
              else if (isLocked)
                _buildStatusChip('Locked', Colors.grey)
              else
                _buildStatusChip('Ready', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  bool _isItemCompleted(LearningPathItem item) {
    if (userProgress == null) return false;
    return userProgress!.isConceptMastered(item.concept);
  }
  
  bool _isItemInProgress(LearningPathItem item) {
    if (userProgress == null) return false;
    return userProgress!.isConceptInProgress(item.concept);
  }
  
  bool _isItemLocked(LearningPathItem item) {
    if (userProgress == null) return false;
    
    // Check if all prerequisites are mastered
    for (final prerequisite in item.prerequisites) {
      if (!userProgress!.isConceptMastered(prerequisite)) {
        return true;
      }
    }
    
    return false;
  }
  
  int _getCompletedItemsCount() {
    if (userProgress == null) return 0;
    
    int count = 0;
    for (final item in learningPath.items) {
      if (userProgress!.isConceptMastered(item.concept)) {
        count++;
      }
    }
    
    return count;
  }
}
