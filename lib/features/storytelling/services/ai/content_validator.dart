import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';

/// Service for validating AI-generated content
///
/// This service provides methods to validate the structure, quality,
/// and educational value of AI-generated content.
class ContentValidator {
  /// Validate a story response from the AI
  ///
  /// Parameters:
  /// - `responseText`: The raw response text from the AI
  /// - `requiredFields`: List of fields that must be present in the response
  /// - `learningConcepts`: Learning concepts that should be covered
  ///
  /// Returns a validation result with the extracted JSON and any errors
  static ValidationResult validateStoryResponse({
    required String responseText,
    required List<String> requiredFields,
    required List<String> learningConcepts,
  }) {
    // Extract JSON from the response
    final jsonStr = _extractJsonFromText(responseText);

    // Check if JSON is valid
    try {
      final Map<String, dynamic> storyData = jsonDecode(jsonStr);

      // Check for required fields
      final List<String> missingFields = [];
      for (final field in requiredFields) {
        if (!storyData.containsKey(field) || storyData[field] == null || storyData[field].toString().isEmpty) {
          missingFields.add(field);
        }
      }

      // Check content length
      final bool contentTooShort = storyData.containsKey('content') &&
          storyData['content'].toString().split(' ').length < 100;

      // Check for learning concepts in content
      final bool conceptsCovered = _checkConceptsCoverage(
        storyData['content']?.toString() ?? '',
        learningConcepts,
      );

      // Create validation result
      return ValidationResult(
        isValid: missingFields.isEmpty && !contentTooShort && conceptsCovered,
        extractedJson: storyData,
        errors: [
          if (missingFields.isNotEmpty) 'Missing required fields: ${missingFields.join(', ')}',
          if (contentTooShort) 'Content is too short',
          if (!conceptsCovered) 'Not all learning concepts are covered',
        ],
      );
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      return ValidationResult(
        isValid: false,
        extractedJson: null,
        errors: ['Invalid JSON format: $e'],
      );
    }
  }

  /// Validate story branches response from the AI
  ///
  /// Parameters:
  /// - `responseText`: The raw response text from the AI
  /// - `requiredFields`: List of fields that must be present in each branch
  /// - `expectedCount`: Expected number of branches
  ///
  /// Returns a validation result with the extracted JSON and any errors
  static ValidationResult validateBranchesResponse({
    required String responseText,
    required List<String> requiredFields,
    required int expectedCount,
  }) {
    // Extract JSON from the response
    final jsonStr = _extractJsonFromText(responseText);

    // Check if JSON is valid
    try {
      final List<dynamic> branchesData = jsonDecode(jsonStr);

      // Check branch count
      final bool correctCount = branchesData.length == expectedCount;

      // Check for required fields in each branch
      final List<String> missingFields = [];
      for (int i = 0; i < branchesData.length; i++) {
        final branch = branchesData[i];
        if (branch is! Map<String, dynamic>) {
          missingFields.add('Branch $i is not a valid object');
          continue;
        }

        for (final field in requiredFields) {
          if (!branch.containsKey(field) || branch[field] == null || branch[field].toString().isEmpty) {
            missingFields.add('Branch $i missing field: $field');
          }
        }
      }

      // Create validation result
      return ValidationResult(
        isValid: correctCount && missingFields.isEmpty,
        extractedJson: branchesData,
        errors: [
          if (!correctCount) 'Expected $expectedCount branches, got ${branchesData.length}',
          ...missingFields,
        ],
      );
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      return ValidationResult(
        isValid: false,
        extractedJson: null,
        errors: ['Invalid JSON format: $e'],
      );
    }
  }

  /// Validate a story continuation response from the AI
  ///
  /// Parameters:
  /// - `responseText`: The raw response text from the AI
  /// - `requiredFields`: List of fields that must be present in the response
  /// - `learningConcepts`: Learning concepts that should be covered
  ///
  /// Returns a validation result with the extracted JSON and any errors
  static ValidationResult validateContinuationResponse({
    required String responseText,
    required List<String> requiredFields,
    required List<String> learningConcepts,
  }) {
    // This is similar to validateStoryResponse but with specific checks for continuations
    return validateStoryResponse(
      responseText: responseText,
      requiredFields: requiredFields,
      learningConcepts: learningConcepts,
    );
  }

  /// Validate a challenge response from the AI
  ///
  /// Parameters:
  /// - `responseText`: The raw response text from the AI
  /// - `requiredFields`: List of fields that must be present in the response
  /// - `learningConcepts`: Learning concepts that should be covered
  ///
  /// Returns a validation result with the extracted JSON and any errors
  static ValidationResult validateChallengeResponse({
    required String responseText,
    required List<String> requiredFields,
    required List<String> learningConcepts,
  }) {
    // Extract JSON from the response
    final jsonStr = _extractJsonFromText(responseText);

    // Check if JSON is valid
    try {
      final Map<String, dynamic> challengeData = jsonDecode(jsonStr);

      // Check for required fields
      final List<String> missingFields = [];
      for (final field in requiredFields) {
        if (!challengeData.containsKey(field) || challengeData[field] == null) {
          missingFields.add(field);
        }
      }

      // Check for valid difficulty
      final bool validDifficulty = challengeData.containsKey('difficulty') &&
          challengeData['difficulty'] is int &&
          (challengeData['difficulty'] as int) >= 1 &&
          (challengeData['difficulty'] as int) <= 5;

      // Check for valid block types
      final bool validBlockTypes = challengeData.containsKey('availableBlockTypes') &&
          challengeData['availableBlockTypes'] is List &&
          (challengeData['availableBlockTypes'] as List).isNotEmpty;

      // Create validation result
      return ValidationResult(
        isValid: missingFields.isEmpty && validDifficulty && validBlockTypes,
        extractedJson: challengeData,
        errors: [
          if (missingFields.isNotEmpty) 'Missing required fields: ${missingFields.join(', ')}',
          if (!validDifficulty) 'Invalid difficulty level',
          if (!validBlockTypes) 'Invalid block types',
        ],
      );
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      return ValidationResult(
        isValid: false,
        extractedJson: null,
        errors: ['Invalid JSON format: $e'],
      );
    }
  }

  /// Check if a story model is valid
  ///
  /// Parameters:
  /// - `story`: The story model to validate
  /// - `learningConcepts`: Learning concepts that should be covered
  ///
  /// Returns true if the story is valid, false otherwise
  static bool validateStoryModel(StoryModel story, List<String> learningConcepts) {
    // Check if story has content
    if (story.content.isEmpty) {
      return false;
    }

    // Check if story has a title
    if (story.title.isEmpty) {
      return false;
    }

    // Check if story has learning concepts
    if (story.learningConcepts.isEmpty) {
      return false;
    }

    // Check if story covers the required learning concepts
    final storyText = story.content.map((block) => block.text).join(' ');
    return _checkConceptsCoverage(storyText, learningConcepts);
  }

  /// Check if a story branch model is valid
  ///
  /// Parameters:
  /// - `branch`: The story branch model to validate
  /// - `learningConcepts`: Learning concepts that should be covered
  ///
  /// Returns true if the branch is valid, false otherwise
  static bool validateStoryBranchModel(StoryBranchModel branch, List<String> learningConcepts) {
    // Check if branch has content
    if (branch.content.isEmpty) {
      return false;
    }

    // Check if branch has a description
    if (branch.description.isEmpty) {
      return false;
    }

    // Check if branch has a target story ID
    if (branch.targetStoryId.isEmpty) {
      return false;
    }

    // Check if branch has learning concepts
    if (branch.learningConcepts.isEmpty) {
      return false;
    }

    // Check if branch covers the required learning concepts
    return _checkConceptsCoverage(branch.content, learningConcepts);
  }

  /// Extract JSON from text that might contain markdown or other formatting
  static String _extractJsonFromText(String text) {
    // Look for JSON content in the text
    final jsonRegex = RegExp(r'({[\s\S]*}|\[[\s\S]*\])');
    final match = jsonRegex.firstMatch(text);

    if (match != null) {
      return match.group(0) ?? '';
    }

    // If no JSON found, return the original text
    return text;
  }

  /// Check if the content covers the required learning concepts
  static bool _checkConceptsCoverage(String content, List<String> learningConcepts) {
    final contentLower = content.toLowerCase();

    // Check if each concept is mentioned in the content
    for (final concept in learningConcepts) {
      // Check for the concept itself and related terms
      final conceptTerms = _getConceptRelatedTerms(concept);

      // If none of the related terms are found, the concept is not covered
      if (!conceptTerms.any((term) => contentLower.contains(term.toLowerCase()))) {
        return false;
      }
    }

    return true;
  }

  /// Get terms related to a learning concept
  static List<String> _getConceptRelatedTerms(String concept) {
    switch (concept.toLowerCase()) {
      case 'sequences':
        return ['sequence', 'order', 'step', 'first', 'next', 'then', 'after', 'before'];
      case 'loops':
        return ['loop', 'repeat', 'again', 'iteration', 'cycle', 'pattern', 'multiple times'];
      case 'conditionals':
        return ['conditional', 'if', 'else', 'when', 'choose', 'decision', 'choice'];
      case 'variables':
        return ['variable', 'value', 'store', 'change', 'different', 'name', 'represent'];
      case 'functions':
        return ['function', 'method', 'procedure', 'routine', 'reuse', 'call'];
      case 'algorithms':
        return ['algorithm', 'process', 'steps', 'solution', 'procedure', 'method'];
      default:
        return [concept];
    }
  }
}

/// Result of content validation
class ValidationResult {
  /// Whether the content is valid
  final bool isValid;

  /// Extracted JSON data
  final dynamic extractedJson;

  /// List of validation errors
  final List<String> errors;

  /// Create a validation result
  ValidationResult({
    required this.isValid,
    required this.extractedJson,
    required this.errors,
  });
}
