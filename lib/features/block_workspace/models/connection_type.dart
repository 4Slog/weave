/// Enum representing the type of connection between blocks
enum ConnectionType {
  /// Top connection
  top,

  /// Bottom connection
  bottom,

  /// Left connection
  left,

  /// Right connection
  right,

  /// Center connection
  center,

  /// Input connection
  input,

  /// Output connection
  output,
}

/// Extension methods for ConnectionType
extension ConnectionTypeExtension on ConnectionType {
  /// Get the opposite connection type
  ConnectionType get opposite {
    switch (this) {
      case ConnectionType.top:
        return ConnectionType.bottom;
      case ConnectionType.bottom:
        return ConnectionType.top;
      case ConnectionType.left:
        return ConnectionType.right;
      case ConnectionType.right:
        return ConnectionType.left;
      case ConnectionType.center:
        return ConnectionType.center;
      case ConnectionType.input:
        return ConnectionType.output;
      case ConnectionType.output:
        return ConnectionType.input;
    }
  }

  /// Check if this connection type is horizontal
  bool get isHorizontal => this == ConnectionType.left || this == ConnectionType.right;

  /// Check if this connection type is vertical
  bool get isVertical => this == ConnectionType.top || this == ConnectionType.bottom;
}
