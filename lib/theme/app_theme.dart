import 'package:flutter/material.dart';

/// Central theming configuration for the Kente Codeweaver application.
/// 
/// This class defines light and dark themes with cultural color symbolism
/// and provides utility methods for theme-aware coloring.
class AppTheme {
  // Primary color palette
  static const Color kentePurple = Color(0xFF6200EA);
  static const Color kenteGold = Color(0xFFFFD700);
  static const Color kenteGreen = Color(0xFF00C853);
  static const Color kenteRed = Color(0xFFD50000);
  static const Color kenteBlack = Color(0xFF212121);
  
  // Secondary colors
  static const Color kenteBlue = Color(0xFF2962FF);
  static const Color kenteTeal = Color(0xFF00BFA5);
  static const Color kenteAmber = Color(0xFFFFAB00);
  static const Color kenteOrange = Color(0xFFFF6D00);
  
  // Background colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkBackground = Color(0xFF121212);
  
  // For cultural context cards
  static const Color culturalCardLight = Color(0xFFFFF8E1);
  static const Color culturalCardDark = Color(0xFF3E2723);
  
  /// Light theme
  static final ThemeData lightTheme = ThemeData(
    // Base properties
    primaryColor: kentePurple,
    colorScheme: ColorScheme.light(
      primary: kentePurple,
      secondary: kenteGold,
      tertiary: kenteGreen,
      error: kenteRed,
      background: lightBackground,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
      brightness: Brightness.light,
    ),
    
    // Background
    scaffoldBackgroundColor: lightBackground,
    
    // Typography
    textTheme: const TextTheme(
      // Display and headlines
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        color: kenteBlack,
        fontWeight: FontWeight.w600,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Roboto',
        color: kenteBlack,
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: kentePurple,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 1,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kentePurple,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kentePurple,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kentePurple,
        side: const BorderSide(color: kentePurple, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: kentePurple,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: kenteRed,
          width: 1,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: 'Roboto',
      ),
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: 'Roboto',
      ),
    ),
    
    // Tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: kentePurple,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
    ),
    
    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: Colors.grey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
    ),
    
    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto',
        fontSize: 12,
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kenteBlack,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        color: kenteBlack,
      ),
    ),
    
    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: kentePurple,
      inactiveTrackColor: Colors.grey[300],
      thumbColor: kentePurple,
      overlayColor: kentePurple.withOpacity(0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    ),
    
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      selectedColor: kentePurple.withOpacity(0.2),
      secondarySelectedColor: kentePurple,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        color: Colors.black87,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        color: kentePurple,
      ),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    
    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kentePurple,
      circularTrackColor: Colors.grey,
      linearTrackColor: Colors.grey,
    ),
  );
  
  /// Dark theme
  static final ThemeData darkTheme = ThemeData(
    // Base properties
    primaryColor: kentePurple,
    colorScheme: ColorScheme.dark(
      primary: kentePurple,
      secondary: kenteGold,
      tertiary: kenteGreen,
      error: kenteRed,
      background: darkBackground,
      surface: const Color(0xFF212121),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    
    // Background
    scaffoldBackgroundColor: darkBackground,
    
    // Typography
    textTheme: const TextTheme(
      // Display and headlines
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white70,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white70,
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kentePurple,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.purpleAccent[100],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.purpleAccent[100],
        side: BorderSide(color: Colors.purpleAccent[100]!, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.purpleAccent[100]!,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: kenteRed,
          width: 1,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF303030),
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: 'Roboto',
      ),
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: 'Roboto',
      ),
    ),
    
    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: Colors.purpleAccent[100],
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
    ),
    
    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple;
        }
        return Colors.transparent;
      }),
      side: BorderSide(color: Colors.grey[700]!),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
    ),
    
    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto',
        fontSize: 12,
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      backgroundColor: const Color(0xFF303030),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        color: Colors.white,
      ),
    ),
    
    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: kentePurple,
      inactiveTrackColor: Colors.grey[700],
      thumbColor: kentePurple,
      overlayColor: kentePurple.withOpacity(0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    ),
    
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple;
        }
        return Colors.grey[300]!;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kentePurple.withOpacity(0.5);
        }
        return Colors.grey[600]!;
      }),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF3A3A3A),
      selectedColor: kentePurple.withOpacity(0.3),
      secondarySelectedColor: kentePurple,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        color: Colors.white,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        color: Colors.purpleAccent[100],
      ),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    
    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF303030),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kentePurple,
      circularTrackColor: Colors.grey,
      linearTrackColor: Colors.grey,
    ),
  );
  
  /// Get success color based on theme brightness
  static Color getSuccessColor(bool darkMode) {
    return darkMode ? kenteGreen.withOpacity(0.8) : kenteGreen;
  }
  
  /// Get error color based on theme brightness
  static Color getErrorColor(bool darkMode) {
    return darkMode ? kenteRed.withOpacity(0.8) : kenteRed;
  }
  
  /// Get warning color based on theme brightness
  static Color getWarningColor(bool darkMode) {
    return darkMode ? kenteAmber.withOpacity(0.8) : kenteAmber;
  }
  
  /// Get info color based on theme brightness
  static Color getInfoColor(bool darkMode) {
    return darkMode ? kenteBlue.withOpacity(0.8) : kenteBlue;
  }
  
  /// Get cultural card background color based on theme brightness
  static Color getCulturalCardColor(bool darkMode) {
    return darkMode ? culturalCardDark : culturalCardLight;
  }
  
  /// Get difficulty level color
  static Color getDifficultyColor(int level, {bool darkMode = false}) {
    switch (level) {
      case 1:
        return darkMode ? Colors.green[400]! : Colors.green;
      case 2:
        return darkMode ? Colors.lightGreen[400]! : Colors.lightGreen;
      case 3:
        return darkMode ? Colors.amber[400]! : Colors.amber;
      case 4:
        return darkMode ? Colors.orange[300]! : Colors.orange;
      case 5:
        return darkMode ? Colors.red[300]! : Colors.red;
      default:
        return darkMode ? Colors.blue[400]! : Colors.blue;
    }
  }
  
  /// Get a color that represents a specific cultural element
  static Color getCulturalElementColor(String elementName, {bool darkMode = false}) {
    // This maps cultural elements to appropriate colors
    // Colors are selected based on traditional Kente color meanings
    
    switch (elementName.toLowerCase()) {
      case 'wisdom':
      case 'knowledge':
        return darkMode ? Colors.indigo[300]! : Colors.indigo;
        
      case 'wealth':
      case 'royalty':
      case 'status':
        return darkMode ? kenteGold.withOpacity(0.8) : kenteGold;
        
      case 'energy':
      case 'power':
      case 'strength':
        return darkMode ? kenteRed.withOpacity(0.8) : kenteRed;
        
      case 'growth':
      case 'harmony':
      case 'agriculture':
        return darkMode ? kenteGreen.withOpacity(0.8) : kenteGreen;
        
      case 'spirituality':
      case 'secrets':
      case 'mystery':
        return darkMode ? Colors.deepPurple[300]! : Colors.deepPurple;
        
      case 'healing':
      case 'health':
      case 'rejuvenation':
        return darkMode ? Colors.lightGreen[300]! : Colors.lightGreen;
        
      case 'mourning':
      case 'maturity':
      case 'ancients':
        return darkMode ? Colors.grey[700]! : kenteBlack;
        
      case 'sky':
      case 'peace':
      case 'devotion':
        return darkMode ? Colors.blue[300]! : Colors.blue;
        
      case 'fertility':
      case 'abundance':
      case 'prosperity':
        return darkMode ? Colors.yellow[300]! : Colors.yellow[700]!;
        
      case 'earth':
      case 'ground':
      case 'clay':
        return darkMode ? Colors.brown[300]! : Colors.brown;
        
      default:
        return darkMode ? kentePurple.withOpacity(0.8) : kentePurple;
    }
  }
}