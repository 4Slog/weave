
/// Abstract interface for storage strategies.
///
/// This interface defines the contract for different storage implementations
/// (e.g., Hive, SharedPreferences) to ensure consistent behavior across
/// different storage mechanisms.
abstract class StorageStrategy {
  /// Initialize the storage strategy.
  ///
  /// This should be called before any other methods to ensure
  /// the storage mechanism is properly set up.
  Future<void> initialize();

  /// Save data to storage.
  ///
  /// [key] is the unique identifier for the data.
  /// [data] is the data to be saved, which can be a primitive type,
  /// a Map, or a List. Complex objects should be converted to JSON first.
  Future<void> saveData(String key, dynamic data);

  /// Retrieve data from storage.
  ///
  /// [key] is the unique identifier for the data.
  /// Returns the data if found, or null if not found.
  Future<dynamic> getData(String key);

  /// Remove data from storage.
  ///
  /// [key] is the unique identifier for the data to be removed.
  Future<void> removeData(String key);

  /// Get all keys in the storage.
  ///
  /// Returns a list of all keys currently in the storage.
  Future<List<String>> getAllKeys();

  /// Clear all data from the storage.
  Future<void> clear();

  /// Check if the storage strategy is initialized.
  ///
  /// Returns true if the storage is initialized and ready to use.
  bool isInitialized();
}
