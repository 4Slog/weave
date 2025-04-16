import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_progression_service.dart';

/// A card that displays cultural elements related to a coding concept
class CulturalLearningCard extends StatelessWidget {
  /// The coding concept being taught
  final String conceptId;
  
  /// The user ID
  final String userId;
  
  /// The cultural elements to display
  final Map<String, dynamic>? culturalElements;
  
  /// Callback when the user wants to learn more
  final VoidCallback? onLearnMore;
  
  /// Cultural data service
  final CulturalDataService _culturalDataService = CulturalDataService();
  
  /// Cultural progression service
  final CulturalProgressionService _progressionService = CulturalProgressionService();
  
  /// Create a new cultural learning card
  CulturalLearningCard({
    Key? key,
    required this.conceptId,
    required this.userId,
    this.culturalElements,
    this.onLearnMore,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCulturalElements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cultural Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to load cultural information.',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (onLearnMore != null)
                    TextButton(
                      onPressed: onLearnMore,
                      child: const Text('Learn More'),
                    ),
                ],
              ),
            ),
          );
        }
        
        final elements = snapshot.data!;
        final pattern = elements['pattern'] as Map<String, dynamic>?;
        final symbol = elements['symbol'] as Map<String, dynamic>?;
        final color = elements['color'] as Map<String, dynamic>?;
        final culturalConnection = elements['culturalConnection'] as String? ?? 
                                  'No cultural connection available.';
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cultural Connection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  culturalConnection,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(),
                
                // Pattern section
                if (pattern != null && pattern.isNotEmpty) ...[
                  _buildCulturalElementSection(
                    title: 'Pattern: ${pattern['name'] ?? 'Unknown'}',
                    description: pattern['description'] ?? 'No description available.',
                    significance: pattern['culturalSignificance'] ?? 'No significance information available.',
                    imagePath: pattern['imagePath'] ?? 'assets/images/cultural/pattern_placeholder.png',
                  ),
                  const Divider(),
                ],
                
                // Symbol section
                if (symbol != null && symbol.isNotEmpty) ...[
                  _buildCulturalElementSection(
                    title: 'Symbol: ${symbol['name'] ?? 'Unknown'}',
                    description: symbol['description'] ?? 'No description available.',
                    significance: symbol['culturalSignificance'] ?? 'No significance information available.',
                    imagePath: symbol['imagePath'] ?? 'assets/images/cultural/symbol_placeholder.png',
                  ),
                  const Divider(),
                ],
                
                // Color section
                if (color != null && color.isNotEmpty) ...[
                  _buildCulturalElementSection(
                    title: 'Color: ${color['name'] ?? 'Unknown'}',
                    description: color['description'] ?? 'No description available.',
                    significance: color['culturalMeaning'] ?? 'No significance information available.',
                    imagePath: color['imagePath'] ?? 'assets/images/cultural/color_placeholder.png',
                    colorHex: color['hexCode'] as String?,
                  ),
                  const Divider(),
                ],
                
                // Learn more button
                if (onLearnMore != null)
                  Center(
                    child: ElevatedButton(
                      onPressed: onLearnMore,
                      child: const Text('Learn More About Cultural Connections'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Build a section for a cultural element
  Widget _buildCulturalElementSection({
    required String title,
    required String description,
    required String significance,
    required String imagePath,
    String? colorHex,
  }) {
    // Parse color hex if provided
    Color? color;
    if (colorHex != null && colorHex.startsWith('#') && colorHex.length == 7) {
      try {
        color = Color(int.parse(colorHex.substring(1), radix: 16) | 0xFF000000);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or color swatch
            if (color != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            else
              Image.asset(
                imagePath,
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cultural Significance: $significance',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Get cultural elements for the concept
  Future<Map<String, dynamic>> _getCulturalElements() async {
    // If cultural elements are provided, use them
    if (culturalElements != null && culturalElements!.isNotEmpty) {
      return culturalElements!;
    }
    
    // Otherwise, get them from the service
    return await _progressionService.getCulturalElementsForConcept(
      userId,
      conceptId,
    );
  }
}

/// A factory for creating different types of cultural learning cards
class CulturalLearningCardFactory {
  /// Create a card for a specific concept
  static Widget forConcept({
    required String conceptId,
    required String userId,
    Map<String, dynamic>? culturalElements,
    VoidCallback? onLearnMore,
  }) {
    return CulturalLearningCard(
      conceptId: conceptId,
      userId: userId,
      culturalElements: culturalElements,
      onLearnMore: onLearnMore,
    );
  }
  
  /// Create a card for a challenge
  static Widget forChallenge({
    required Map<String, dynamic> challengeData,
    required String userId,
    VoidCallback? onLearnMore,
  }) {
    final conceptId = challengeData['conceptId'] as String? ?? 'variables';
    final culturalElements = challengeData['culturalElements'] as Map<String, dynamic>?;
    
    return CulturalLearningCard(
      conceptId: conceptId,
      userId: userId,
      culturalElements: culturalElements,
      onLearnMore: onLearnMore,
    );
  }
  
  /// Create a card for a learning path item
  static Widget forLearningPathItem({
    required String userId,
    required String conceptId,
    required List<Map<String, dynamic>> culturalElements,
    String? culturalConnection,
    VoidCallback? onLearnMore,
  }) {
    // Convert the list of cultural elements to the expected format
    final Map<String, dynamic> elements = {};
    
    for (final element in culturalElements) {
      final type = element['type'] as String? ?? 'unknown';
      elements[type] = element;
    }
    
    if (culturalConnection != null && culturalConnection.isNotEmpty) {
      elements['culturalConnection'] = culturalConnection;
    }
    
    return CulturalLearningCard(
      conceptId: conceptId,
      userId: userId,
      culturalElements: elements,
      onLearnMore: onLearnMore,
    );
  }
}
