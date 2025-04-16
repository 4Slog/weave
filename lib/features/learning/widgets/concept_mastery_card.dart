import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/learning/models/concept_mastery.dart';
import 'package:kente_codeweaver/features/learning/providers/adaptive_learning_provider.dart';

/// A card that displays a concept and its mastery level
class ConceptMasteryCard extends StatefulWidget {
  /// The concept ID
  final String conceptId;
  
  /// The user ID
  final String userId;
  
  /// Create a concept mastery card
  const ConceptMasteryCard({
    Key? key,
    required this.conceptId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ConceptMasteryCard> createState() => _ConceptMasteryCardState();
}

class _ConceptMasteryCardState extends State<ConceptMasteryCard> {
  ConceptMastery? _conceptMastery;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadConceptMastery();
  }
  
  Future<void> _loadConceptMastery() async {
    final provider = Provider.of<AdaptiveLearningProvider>(context, listen: false);
    
    try {
      final mastery = await provider.getConceptMastery(widget.conceptId);
      
      if (mounted) {
        setState(() {
          _conceptMastery = mastery;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 180,
        height: 160,
        child: Card(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Get concept name from ID (in a real app, you'd have a mapping or service)
    final conceptName = _getConceptName(widget.conceptId);
    
    return SizedBox(
      width: 180,
      height: 160,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conceptName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (_conceptMastery != null) ...[
                _buildMasteryIndicator(_conceptMastery!),
                const SizedBox(height: 8),
                Text(
                  'Last practiced: ${_formatDate(_conceptMastery!.lastPracticed)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Demonstrations: ${_conceptMastery!.demonstrations.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                const Text('Not started yet'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to a challenge for this concept
                    // This would be implemented in a real app
                  },
                  child: const Text('Start Learning'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMasteryIndicator(ConceptMastery mastery) {
    final proficiency = mastery.proficiency;
    
    Color color;
    String label;
    
    if (proficiency >= 0.8) {
      color = Colors.green;
      label = 'Mastered';
    } else if (proficiency >= 0.5) {
      color = Colors.amber;
      label = 'Practicing';
    } else if (proficiency > 0) {
      color = Colors.orange;
      label = 'Learning';
    } else {
      color = Colors.grey;
      label = 'Not Started';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: proficiency,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '$label (${(proficiency * 100).round()}%)',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  String _getConceptName(String conceptId) {
    // In a real app, this would come from a service or database
    final conceptNames = {
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'arrays': 'Arrays',
      'objects': 'Objects',
      'classes': 'Classes',
      'inheritance': 'Inheritance',
      'recursion': 'Recursion',
      'algorithms': 'Algorithms',
      'data_structures': 'Data Structures',
      'pattern_design': 'Pattern Design',
      'sequence': 'Sequences',
      'logic': 'Logic',
      'debugging': 'Debugging',
    };
    
    return conceptNames[conceptId] ?? 'Unknown Concept';
  }
}
