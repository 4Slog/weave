import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';

/// Widget for displaying detailed narrative choices with cultural styling
class DetailedNarrativeChoiceWidget extends StatelessWidget {
  /// The branches to display
  final List<StoryBranchModel> branches;
  
  /// Callback when a branch is selected
  final Function(StoryBranchModel) onBranchSelected;
  
  /// Constructor
  const DetailedNarrativeChoiceWidget({
    super.key,
    required this.branches,
    required this.onBranchSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your path:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...branches.map((branch) => _buildBranchOption(context, branch)).toList(),
        ],
      ),
    );
  }
  
  /// Build a branch option
  Widget _buildBranchOption(BuildContext context, StoryBranchModel branch) {
    return GestureDetector(
      onTap: () => onBranchSelected(branch),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                branch.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
