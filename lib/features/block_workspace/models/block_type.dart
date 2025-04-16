// No imports needed

/// Defines the different types of blocks available in the application
/// as specified in the technical implementation guide.
///
/// Each block type corresponds to specific coding concepts and educational outcomes.
enum BlockType {
  /// Pattern blocks represent specific Kente weaving patterns
  pattern,

  /// Color blocks define the color properties of the pattern
  color,

  /// Structure blocks determine how patterns are arranged
  structure,

  /// Loop blocks represent repeated patterns in Kente weaving
  loop,

  /// Column blocks represent vertical sections in the pattern
  column,
}

/// Extension methods for BlockType to provide additional functionality
extension BlockTypeExtension on BlockType {
  /// Get a user-friendly display name for this block type
  String get displayName {
    switch (this) {
      case BlockType.pattern:
        return 'Pattern Block';
      case BlockType.color:
        return 'Color Block';
      case BlockType.structure:
        return 'Structure Block';
      case BlockType.loop:
        return 'Loop Block';
      case BlockType.column:
        return 'Column Block';
    }
  }

  /// Get a short description of what this block type does
  String get description {
    switch (this) {
      case BlockType.pattern:
        return 'Creates a specific Kente weaving pattern';
      case BlockType.color:
        return 'Defines colors used in the pattern';
      case BlockType.structure:
        return 'Determines how patterns are arranged';
      case BlockType.loop:
        return 'Repeats patterns multiple times';
      case BlockType.column:
        return 'Creates vertical sections in the pattern';
    }
  }

  /// Get the primary coding concept associated with this block type
  String get codingConcept {
    switch (this) {
      case BlockType.pattern:
        return 'sequences';
      case BlockType.color:
        return 'variables';
      case BlockType.structure:
        return 'program_structure';
      case BlockType.loop:
        return 'loops';
      case BlockType.column:
        return 'arrays';
    }
  }

  /// Get a detailed educational description of the coding concept
  String get educationalDescription {
    switch (this) {
      case BlockType.pattern:
        return 'Pattern blocks teach sequences - the fundamental programming concept of executing instructions in order. In coding, sequences are the basic building blocks that form algorithms.';
      case BlockType.color:
        return 'Color blocks teach variables - containers that store information that can be reused throughout a program. Variables are essential for making dynamic and flexible programs.';
      case BlockType.structure:
        return 'Structure blocks teach program structure - how different parts of code are organized and relate to each other. Good structure makes programs easier to understand and maintain.';
      case BlockType.loop:
        return 'Loop blocks teach iteration - repeating a set of instructions multiple times. Loops are powerful tools that help programmers avoid writing repetitive code and create efficient programs.';
      case BlockType.column:
        return 'Column blocks teach arrays - collections of related values stored together. Arrays allow programmers to work with groups of data efficiently and are fundamental to data structures.';
    }
  }

  /// Get related coding concepts that can be learned with this block type
  List<String> get relatedConcepts {
    switch (this) {
      case BlockType.pattern:
        return ['algorithms', 'procedures', 'execution_order'];
      case BlockType.color:
        return ['data_types', 'assignment', 'constants'];
      case BlockType.structure:
        return ['functions', 'modules', 'organization'];
      case BlockType.loop:
        return ['iteration', 'repetition', 'efficiency'];
      case BlockType.column:
        return ['data_structures', 'collections', 'indexing'];
    }
  }

  /// Get the difficulty level of this block type (1-5)
  int get difficultyLevel {
    switch (this) {
      case BlockType.pattern:
        return 1; // Easiest
      case BlockType.color:
        return 1;
      case BlockType.structure:
        return 3;
      case BlockType.loop:
        return 4;
      case BlockType.column:
        return 5; // Most difficult
    }
  }

  /// Check if this block type can connect to another block type
  bool canConnectTo(BlockType other) {
    // Define connection rules based on block types
    switch (this) {
      case BlockType.pattern:
        return other == BlockType.color || other == BlockType.structure;
      case BlockType.color:
        return other == BlockType.pattern || other == BlockType.loop;
      case BlockType.structure:
        return other == BlockType.pattern || other == BlockType.column;
      case BlockType.loop:
        return other == BlockType.pattern || other == BlockType.color;
      case BlockType.column:
        return other == BlockType.structure;
    }
  }
}
