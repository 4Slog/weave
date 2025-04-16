import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;

/// Singleton service for Gemini AI API access
///
/// This service ensures that Gemini is initialized only once
/// and provides a shared instance for all services that need it.
class GeminiService {
  // Singleton instance
  static final GeminiService _instance = GeminiService._internal();

  // Factory constructor
  factory GeminiService() => _instance;

  // Private constructor
  GeminiService._internal();

  // Gemini instance
  late final gemini.Gemini _gemini;

  // Initialization state
  bool _isInitialized = false;

  // Getter for the Gemini instance
  gemini.Gemini get instance {
    if (!_isInitialized) {
      throw Exception('GeminiService not initialized. Call initialize() first.');
    }
    return _gemini;
  }

  // Getter for initialization state
  bool get isInitialized => _isInitialized;

  // Getter for online state
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Initialize the Gemini service
  ///
  /// This should be called once at app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Special handling for web platform
    if (kIsWeb) {
      debugPrint('Running in web environment, using offline mode for GeminiService');
      _isOnline = false;
      _isInitialized = true;
      return;
    }

    try {
      // Get API key from environment variables
      final String? apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('Warning: GEMINI_API_KEY not found, using offline mode');
        _isOnline = false;
        _isInitialized = true;
        return;
      }

      // Initialize Gemini with the API key
      gemini.Gemini.init(apiKey: apiKey);
      _gemini = gemini.Gemini.instance;

      // Check connectivity by making a simple API call
      await checkConnectivity();

      _isInitialized = true;
      debugPrint('GeminiService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize GeminiService: $e');
      // Set to initialized but offline mode instead of throwing
      _isOnline = false;
      _isInitialized = true;
    }
  }

  /// Check connectivity by making a simple API call
  Future<bool> checkConnectivity() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      // Try a simple API call to check connectivity
      final response = await _gemini.prompt(parts: [gemini.Part.text("Hello")]);

      _isOnline = response != null;
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      return false;
    }
  }
}
