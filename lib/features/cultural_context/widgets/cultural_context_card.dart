import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart';

/// Factory class for creating different types of cultural information cards
class KenteCulturalCards {
  /// Create a card showing color meanings
  static Widget colorMeanings({Function? onLearnMore}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CulturalDataService().getAllColors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const CulturalContextCard(
            title: 'Color Meanings',
            description: 'Unable to load color meanings.',
          );
        }

        final colors = snapshot.data ?? [];

        return CulturalContextCard(
          title: 'Kente Color Meanings',
          description: 'In Kente weaving, each color carries symbolic meaning and cultural significance:',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: colors.map((color) {
              // Extract color data
              final name = color['name'] ?? '';
              final englishName = color['englishName'] ?? '';
              final meaning = color['culturalMeaning'] ?? '';
              final hexCode = color['hexCode'] ?? '#000000';

              // Create color value
              Color colorValue;
              try {
                colorValue = Color(int.parse(hexCode.substring(1), radix: 16) + 0xFF000000);
              } catch (e) {
                colorValue = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color swatch
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    // Color info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name ($englishName)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(meaning),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          onLearnMore: onLearnMore,
        );
      },
    );
  }

  /// Create a card showing pattern meanings
  static Widget patternMeanings({Function? onLearnMore}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CulturalDataService().getAllPatterns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const CulturalContextCard(
            title: 'Pattern Meanings',
            description: 'Unable to load pattern meanings.',
          );
        }

        final patterns = snapshot.data ?? [];

        return CulturalContextCard(
          title: 'Kente Pattern Meanings',
          description: 'Each pattern in Kente cloth tells a story and carries cultural significance:',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: patterns.map((pattern) {
              // Extract pattern data
              final name = pattern['name'] ?? '';
              final englishName = pattern['englishName'] ?? '';
              final significance = pattern['culturalSignificance'] ?? '';
              final region = pattern['region'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name ($englishName)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (region.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Region: $region',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(significance),
                  ],
                ),
              );
            }).toList(),
          ),
          onLearnMore: onLearnMore,
        );
      },
    );
  }

  /// Create a card showing historical context
  static Widget historicalContext({Function? onLearnMore}) {
    return CulturalContextCard(
      title: 'Kente Weaving History',
      description: 'The rich tradition of Kente cloth weaving has deep historical significance in Ghanaian culture.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoricalSection(
            title: 'Origins',
            content: 'Kente originated in the Ashanti Kingdom in what is now Ghana in the 17th century. According to legend, two friends learned the art of weaving by observing a spider weaving its web. They created a cloth that would later become known as Kente.',
          ),
          _buildHistoricalSection(
            title: 'Royal Beginnings',
            content: 'Initially, Kente was worn exclusively by royalty and spiritual leaders for special ceremonies. It was considered sacred and carried spiritual significance. The Asantehene (king) had exclusive rights to certain patterns.',
          ),
          _buildHistoricalSection(
            title: 'Evolution',
            content: 'Over time, Kente evolved from simple designs to complex patterns with specific names and meanings. The spread of weaving knowledge allowed more people to learn the craft, though the finest pieces remained reserved for important occasions.',
          ),
          _buildHistoricalSection(
            title: 'Modern Significance',
            content: 'Today, Kente is recognized worldwide as a symbol of African heritage and identity. It has transcended its Ghanaian origins to become a pan-African symbol, especially significant in celebrations of achievement and cultural pride.',
          ),
        ],
      ),
      onLearnMore: onLearnMore,
      imagePath: 'assets/images/cultural/kente_weaving_history.png',
    );
  }

  /// Create a card showing modern significance
  static Widget modernSignificance({Function? onLearnMore}) {
    return CulturalContextCard(
      title: 'Kente in Modern Society',
      description: 'Kente cloth continues to hold great cultural significance while finding new expressions in contemporary life.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoricalSection(
            title: 'Global Recognition',
            content: 'Kente has gained international recognition as a symbol of African cultural identity and heritage. It appears in fashion, art, and educational contexts worldwide.',
          ),
          _buildHistoricalSection(
            title: 'Celebrations and Achievements',
            content: 'In many African American communities, Kente stoles are worn during graduation ceremonies to honor African heritage and symbolize academic achievement.',
          ),
          _buildHistoricalSection(
            title: 'Digital Preservation',
            content: 'Modern technology helps document and preserve traditional Kente patterns and techniques, ensuring this cultural knowledge continues for future generations.',
          ),
          _buildHistoricalSection(
            title: 'Coding Connection',
            content: 'The mathematical precision and pattern-based structure of Kente weaving shares similarities with coding concepts like sequences, loops, and conditionals - demonstrating how traditional crafts can connect to modern technological skills.',
          ),
        ],
      ),
      onLearnMore: onLearnMore,
      imagePath: 'assets/images/cultural/kente_modern_usage.png',
    );
  }

  /// Create a card showing coding connections
  static Widget codingConnections({Function? onLearnMore}) {
    return CulturalContextCard(
      title: 'Kente & Coding: Connected Concepts',
      description: 'The traditional craft of Kente weaving shares surprising similarities with modern coding concepts.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoricalSection(
            title: 'Patterns as Algorithms',
            content: 'Kente weavers follow specific sequences of steps (algorithms) to create patterns, just as programmers write algorithms to solve problems.',
          ),
          _buildHistoricalSection(
            title: 'Loops in Weaving',
            content: 'Repeated patterns in Kente cloth are similar to loops in programming - a set of instructions repeated multiple times to create structure.',
          ),
          _buildHistoricalSection(
            title: 'Conditional Logic',
            content: 'Weavers make decisions based on the current state of the pattern, similar to conditional statements (if/then logic) in coding.',
          ),
          _buildHistoricalSection(
            title: 'Variables',
            content: 'Different colors in Kente function like variables in programming, with each color representing a different value or meaning that can be woven into the pattern.',
          ),
        ],
      ),
      onLearnMore: onLearnMore,
      imagePath: 'assets/images/cultural/kente_coding_connection.png',
    );
  }

  /// Build a historical section with title and content
  static Widget _buildHistoricalSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}

/// A reusable card for displaying cultural context information
class CulturalContextCard extends StatelessWidget {
  /// Title of the card
  final String title;

  /// Description text
  final String description;

  /// Optional custom content widget
  final Widget? content;

  /// Optional image path
  final String? imagePath;

  /// Optional region information
  final String? region;

  /// Optional asset key for identification
  final String? assetKey;

  /// Optional callback for learn more button
  final Function? onLearnMore;

  /// Create a cultural context card
  const CulturalContextCard({
    super.key,
    required this.title,
    required this.description,
    this.content,
    this.imagePath,
    this.region,
    this.assetKey,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with title and region
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (region != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Region: $region',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Asset icon if provided
                if (assetKey != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/images/icons/$assetKey.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // Image if provided
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Custom content
                if (content != null) content!,

                // Learn more button if callback provided
                if (onLearnMore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => onLearnMore!(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Learn More'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
