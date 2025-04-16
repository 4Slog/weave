
/// Represents a user's progression through cultural elements
class CulturalProgression {
  /// User ID
  final String userId;
  
  /// Map of pattern IDs to exposure count
  final Map<String, int> patternExposure;
  
  /// Map of symbol IDs to exposure count
  final Map<String, int> symbolExposure;
  
  /// Map of color IDs to exposure count
  final Map<String, int> colorExposure;
  
  /// Map of region IDs to exposure count
  final Map<String, int> regionExposure;
  
  /// Map of concept IDs to cultural elements used to teach them
  final Map<String, List<String>> conceptTeachingHistory;
  
  /// When this progression was last updated
  final DateTime lastUpdated;
  
  /// Create a new cultural progression
  CulturalProgression({
    required this.userId,
    this.patternExposure = const {},
    this.symbolExposure = const {},
    this.colorExposure = const {},
    this.regionExposure = const {},
    this.conceptTeachingHistory = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Create a cultural progression from JSON
  factory CulturalProgression.fromJson(Map<String, dynamic> json) {
    return CulturalProgression(
      userId: json['userId'] as String,
      patternExposure: Map<String, int>.from(json['patternExposure'] ?? {}),
      symbolExposure: Map<String, int>.from(json['symbolExposure'] ?? {}),
      colorExposure: Map<String, int>.from(json['colorExposure'] ?? {}),
      regionExposure: Map<String, int>.from(json['regionExposure'] ?? {}),
      conceptTeachingHistory: (json['conceptTeachingHistory'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ) ?? {},
      lastUpdated: json['lastUpdated'] != null 
        ? DateTime.parse(json['lastUpdated']) 
        : DateTime.now(),
    );
  }
  
  /// Convert this cultural progression to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'patternExposure': patternExposure,
      'symbolExposure': symbolExposure,
      'colorExposure': colorExposure,
      'regionExposure': regionExposure,
      'conceptTeachingHistory': conceptTeachingHistory,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Record exposure to a pattern
  CulturalProgression recordPatternExposure(String patternId) {
    final newPatternExposure = Map<String, int>.from(patternExposure);
    newPatternExposure[patternId] = (newPatternExposure[patternId] ?? 0) + 1;
    
    return CulturalProgression(
      userId: userId,
      patternExposure: newPatternExposure,
      symbolExposure: symbolExposure,
      colorExposure: colorExposure,
      regionExposure: regionExposure,
      conceptTeachingHistory: conceptTeachingHistory,
    );
  }
  
  /// Record exposure to a symbol
  CulturalProgression recordSymbolExposure(String symbolId) {
    final newSymbolExposure = Map<String, int>.from(symbolExposure);
    newSymbolExposure[symbolId] = (newSymbolExposure[symbolId] ?? 0) + 1;
    
    return CulturalProgression(
      userId: userId,
      patternExposure: patternExposure,
      symbolExposure: newSymbolExposure,
      colorExposure: colorExposure,
      regionExposure: regionExposure,
      conceptTeachingHistory: conceptTeachingHistory,
    );
  }
  
  /// Record exposure to a color
  CulturalProgression recordColorExposure(String colorId) {
    final newColorExposure = Map<String, int>.from(colorExposure);
    newColorExposure[colorId] = (newColorExposure[colorId] ?? 0) + 1;
    
    return CulturalProgression(
      userId: userId,
      patternExposure: patternExposure,
      symbolExposure: symbolExposure,
      colorExposure: newColorExposure,
      regionExposure: regionExposure,
      conceptTeachingHistory: conceptTeachingHistory,
    );
  }
  
  /// Record exposure to a region
  CulturalProgression recordRegionExposure(String regionId) {
    final newRegionExposure = Map<String, int>.from(regionExposure);
    newRegionExposure[regionId] = (newRegionExposure[regionId] ?? 0) + 1;
    
    return CulturalProgression(
      userId: userId,
      patternExposure: patternExposure,
      symbolExposure: symbolExposure,
      colorExposure: colorExposure,
      regionExposure: newRegionExposure,
      conceptTeachingHistory: conceptTeachingHistory,
    );
  }
  
  /// Record teaching a concept with a cultural element
  CulturalProgression recordConceptTeaching(String conceptId, String elementId) {
    final newConceptTeachingHistory = Map<String, List<String>>.from(conceptTeachingHistory);
    
    if (newConceptTeachingHistory.containsKey(conceptId)) {
      final history = List<String>.from(newConceptTeachingHistory[conceptId]!);
      history.add(elementId);
      newConceptTeachingHistory[conceptId] = history;
    } else {
      newConceptTeachingHistory[conceptId] = [elementId];
    }
    
    return CulturalProgression(
      userId: userId,
      patternExposure: patternExposure,
      symbolExposure: symbolExposure,
      colorExposure: colorExposure,
      regionExposure: regionExposure,
      conceptTeachingHistory: newConceptTeachingHistory,
    );
  }
  
  /// Get the least exposed pattern
  String? getLeastExposedPattern(List<String> availablePatterns) {
    if (availablePatterns.isEmpty) return null;
    
    // Sort available patterns by exposure count (ascending)
    final sortedPatterns = List<String>.from(availablePatterns);
    sortedPatterns.sort((a, b) => 
      (patternExposure[a] ?? 0).compareTo(patternExposure[b] ?? 0));
    
    return sortedPatterns.first;
  }
  
  /// Get the least exposed symbol
  String? getLeastExposedSymbol(List<String> availableSymbols) {
    if (availableSymbols.isEmpty) return null;
    
    // Sort available symbols by exposure count (ascending)
    final sortedSymbols = List<String>.from(availableSymbols);
    sortedSymbols.sort((a, b) => 
      (symbolExposure[a] ?? 0).compareTo(symbolExposure[b] ?? 0));
    
    return sortedSymbols.first;
  }
  
  /// Get the least exposed color
  String? getLeastExposedColor(List<String> availableColors) {
    if (availableColors.isEmpty) return null;
    
    // Sort available colors by exposure count (ascending)
    final sortedColors = List<String>.from(availableColors);
    sortedColors.sort((a, b) => 
      (colorExposure[a] ?? 0).compareTo(colorExposure[b] ?? 0));
    
    return sortedColors.first;
  }
  
  /// Get the least exposed region
  String? getLeastExposedRegion(List<String> availableRegions) {
    if (availableRegions.isEmpty) return null;
    
    // Sort available regions by exposure count (ascending)
    final sortedRegions = List<String>.from(availableRegions);
    sortedRegions.sort((a, b) => 
      (regionExposure[a] ?? 0).compareTo(regionExposure[b] ?? 0));
    
    return sortedRegions.first;
  }
  
  /// Get a cultural element that hasn't been used to teach a concept
  String? getNovelElementForConcept(String conceptId, List<String> availableElements) {
    if (availableElements.isEmpty) return null;
    
    // Get elements that have been used to teach this concept
    final usedElements = conceptTeachingHistory[conceptId] ?? [];
    
    // Find elements that haven't been used yet
    final unusedElements = availableElements.where((element) => 
      !usedElements.contains(element)).toList();
    
    if (unusedElements.isEmpty) {
      // If all elements have been used, return the least recently used one
      final sortedElements = List<String>.from(availableElements);
      sortedElements.sort((a, b) {
        final aIndex = usedElements.lastIndexOf(a);
        final bIndex = usedElements.lastIndexOf(b);
        
        // If an element isn't in the list, it should come first
        if (aIndex == -1) return -1;
        if (bIndex == -1) return 1;
        
        // Otherwise, sort by index (earlier index means it was used longer ago)
        return aIndex.compareTo(bIndex);
      });
      
      return sortedElements.first;
    }
    
    return unusedElements.first;
  }
  
  /// Get the total cultural exposure count
  int getTotalExposureCount() {
    int total = 0;
    
    patternExposure.forEach((_, count) => total += count);
    symbolExposure.forEach((_, count) => total += count);
    colorExposure.forEach((_, count) => total += count);
    regionExposure.forEach((_, count) => total += count);
    
    return total;
  }
  
  /// Get the cultural diversity score (0.0 to 1.0)
  double getCulturalDiversityScore() {
    final totalElements = patternExposure.length + 
                          symbolExposure.length + 
                          colorExposure.length + 
                          regionExposure.length;
    
    if (totalElements == 0) return 0.0;
    
    final totalExposure = getTotalExposureCount();
    if (totalExposure == 0) return 0.0;
    
    // Calculate how evenly distributed the exposure is
    // A perfect score would be if all elements have the same exposure count
    final idealExposurePerElement = totalExposure / totalElements;
    
    double totalDeviation = 0.0;
    
    patternExposure.forEach((_, count) {
      totalDeviation += (count - idealExposurePerElement).abs();
    });
    
    symbolExposure.forEach((_, count) {
      totalDeviation += (count - idealExposurePerElement).abs();
    });
    
    colorExposure.forEach((_, count) {
      totalDeviation += (count - idealExposurePerElement).abs();
    });
    
    regionExposure.forEach((_, count) {
      totalDeviation += (count - idealExposurePerElement).abs();
    });
    
    // Normalize the deviation to a 0.0 to 1.0 scale
    // The maximum possible deviation would be 2 * (totalExposure - idealExposurePerElement)
    final maxDeviation = 2 * totalExposure * (1.0 - 1.0 / totalElements);
    
    if (maxDeviation == 0.0) return 1.0;
    
    // Invert the score so that higher is better
    return 1.0 - (totalDeviation / maxDeviation);
  }
}
