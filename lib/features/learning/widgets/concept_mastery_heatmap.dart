import 'package:flutter/material.dart';

/// A heatmap visualization of concept mastery
class ConceptMasteryHeatmap extends StatelessWidget {
  /// The user ID
  final String userId;
  
  /// Map of concept IDs to proficiency values (0.0 to 1.0)
  final Map<String, double> skillProficiency;
  
  /// Create a concept mastery heatmap
  const ConceptMasteryHeatmap({
    Key? key,
    required this.userId,
    required this.skillProficiency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (skillProficiency.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No concept mastery data available yet.'),
        ),
      );
    }
    
    // Group concepts by category
    final groupedConcepts = _groupConceptsByCategory();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedConcepts.entries.map((entry) {
            final category = entry.key;
            final concepts = entry.value;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: concepts.map((conceptId) {
                    final proficiency = skillProficiency[conceptId] ?? 0.0;
                    return _buildConceptTile(conceptId, proficiency);
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildConceptTile(String conceptId, double proficiency) {
    final color = _getProficiencyColor(proficiency);
    final conceptName = _getConceptName(conceptId);
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                conceptName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${(proficiency * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getProficiencyColor(double proficiency) {
    if (proficiency >= 0.8) {
      return Colors.green[700]!;
    } else if (proficiency >= 0.6) {
      return Colors.green[500]!;
    } else if (proficiency >= 0.4) {
      return Colors.amber[700]!;
    } else if (proficiency >= 0.2) {
      return Colors.orange[700]!;
    } else {
      return Colors.red[700]!;
    }
  }
  
  Map<String, List<String>> _groupConceptsByCategory() {
    final result = <String, List<String>>{};
    
    for (final conceptId in skillProficiency.keys) {
      final category = _getConceptCategory(conceptId);
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(conceptId);
    }
    
    return result;
  }
  
  String _getConceptCategory(String conceptId) {
    // In a real app, this would come from a service or database
    final conceptCategories = {
      'loops': 'Control Flow',
      'conditionals': 'Control Flow',
      'variables': 'Basics',
      'functions': 'Functions',
      'arrays': 'Data Structures',
      'objects': 'Data Structures',
      'classes': 'Object-Oriented',
      'inheritance': 'Object-Oriented',
      'recursion': 'Advanced',
      'algorithms': 'Advanced',
      'data_structures': 'Data Structures',
      'pattern_design': 'Patterns',
      'sequence': 'Basics',
      'logic': 'Basics',
      'debugging': 'Tools',
    };
    
    return conceptCategories[conceptId] ?? 'Other';
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
    
    return conceptNames[conceptId] ?? 'Unknown';
  }
}
