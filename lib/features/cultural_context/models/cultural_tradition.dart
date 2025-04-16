import 'package:flutter/material.dart';

/// Represents a cultural tradition that can be integrated into the app
class CulturalTradition {
  /// Unique identifier for this tradition
  final String id;

  /// Display name of the tradition
  final String name;

  /// Region or country of origin
  final String region;

  /// Brief description of the tradition
  final String description;

  /// Longer historical context
  final String historicalContext;

  /// Primary craft or art form
  final String primaryCraft;

  /// List of key cultural elements
  final List<String> keyElements;

  /// List of key cultural values
  final List<String> keyValues;

  /// Path to the icon asset
  final String iconPath;

  /// Primary color associated with this tradition
  final Color primaryColor;

  /// Secondary color associated with this tradition
  final Color secondaryColor;

  /// Paths to asset files containing cultural data
  final Map<String, String> dataFilePaths;

  /// Create a new cultural tradition
  CulturalTradition({
    required this.id,
    required this.name,
    required this.region,
    required this.description,
    required this.historicalContext,
    required this.primaryCraft,
    required this.keyElements,
    required this.keyValues,
    required this.iconPath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.dataFilePaths,
  });

  /// Create a cultural tradition from JSON
  factory CulturalTradition.fromJson(Map<String, dynamic> json) {
    return CulturalTradition(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String,
      description: json['description'] as String,
      historicalContext: json['historicalContext'] as String,
      primaryCraft: json['primaryCraft'] as String,
      keyElements: List<String>.from(json['keyElements'] ?? []),
      keyValues: List<String>.from(json['keyValues'] ?? []),
      iconPath: json['iconPath'] as String,
      primaryColor: Color(int.parse(json['primaryColor'] as String, radix: 16)),
      secondaryColor: Color(int.parse(json['secondaryColor'] as String, radix: 16)),
      dataFilePaths: Map<String, String>.from(json['dataFilePaths'] ?? {}),
    );
  }

  /// Convert this cultural tradition to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'description': description,
      'historicalContext': historicalContext,
      'primaryCraft': primaryCraft,
      'keyElements': keyElements,
      'keyValues': keyValues,
      'iconPath': iconPath,
      'primaryColor': primaryColor.value.toRadixString(16),
      'secondaryColor': secondaryColor.value.toRadixString(16),
      'dataFilePaths': dataFilePaths,
    };
  }
}

/// Represents a cultural element within a tradition
class CulturalElement {
  /// Unique identifier for this element
  final String id;

  /// Display name of the element
  final String name;

  /// English translation or equivalent name
  final String englishName;

  /// Type of element (pattern, symbol, color, etc.)
  final String type;

  /// Brief description of the element
  final String description;

  /// Cultural significance or meaning
  final String culturalSignificance;

  /// Region or tradition this element belongs to
  final String tradition;

  /// Path to the image asset
  final String imagePath;

  /// Related coding concepts
  final List<String> relatedConcepts;

  /// Educational value for teaching coding concepts
  final String educationalValue;

  /// Create a new cultural element
  CulturalElement({
    required this.id,
    required this.name,
    required this.englishName,
    required this.type,
    required this.description,
    required this.culturalSignificance,
    required this.tradition,
    required this.imagePath,
    required this.relatedConcepts,
    required this.educationalValue,
  });

  /// Create a cultural element from JSON
  factory CulturalElement.fromJson(Map<String, dynamic> json) {
    return CulturalElement(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      culturalSignificance: json['culturalSignificance'] as String,
      tradition: json['tradition'] as String,
      imagePath: json['imagePath'] as String,
      relatedConcepts: List<String>.from(json['relatedConcepts'] ?? []),
      educationalValue: json['educationalValue'] as String,
    );
  }

  /// Convert this cultural element to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'type': type,
      'description': description,
      'culturalSignificance': culturalSignificance,
      'tradition': tradition,
      'imagePath': imagePath,
      'relatedConcepts': relatedConcepts,
      'educationalValue': educationalValue,
    };
  }
}
