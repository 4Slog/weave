import 'storage_strategy.dart';

/// Base interface for all repositories.
/// 
/// This interface defines the common contract for all repositories
/// to ensure consistent behavior across different data domains.
abstract class BaseRepository {
  /// Initialize the repository.
  /// 
  /// This should be called before any other methods to ensure
  /// the underlying storage is properly set up.
  Future<void> initialize();
  
  /// Get the storage strategy used by this repository.
  /// 
  /// This allows access to the underlying storage mechanism
  /// for advanced operations if needed.
  StorageStrategy get storage;
}
