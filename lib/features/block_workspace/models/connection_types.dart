// filepath: c:\Users\sowup\dev\weave\lib\models\connection_types.dart

/// Defines the types of connections between blocks in the Kente Codeweaver application
enum ConnectionType {
  /// Input connection - block accepts input from another block
  input,
  
  /// Output connection - block provides output to another block
  output,
  
  /// Bidirectional connection - block can both send and receive
  bidirectional,
}

/// Extension methods for ConnectionType to provide additional functionality
extension ConnectionTypeExtension on ConnectionType {
  /// Get a user-friendly display name for this connection type
  String get displayName {
    switch (this) {
      case ConnectionType.input:
        return 'Input';
      case ConnectionType.output:
        return 'Output';
      case ConnectionType.bidirectional:
        return 'Bidirectional';
    }
  }
  
  /// Check if this connection type is compatible with another connection type
  bool canConnectTo(ConnectionType other) {
    switch (this) {
      case ConnectionType.input:
        return other == ConnectionType.output;
      case ConnectionType.output:
        return other == ConnectionType.input;
      case ConnectionType.bidirectional:
        return true; // Can connect to any type
    }
  }
  
  /// Get the string representation of this connection type
  String toStringValue() {
    return toString().split('.').last;
  }
  
  /// Parse a connection type from string
  static ConnectionType fromString(String value) {
    try {
      return ConnectionType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == value.toLowerCase(),
        orElse: () => ConnectionType.bidirectional,
      );
    } catch (e) {
      return ConnectionType.bidirectional; // Default
    }
  }
}
