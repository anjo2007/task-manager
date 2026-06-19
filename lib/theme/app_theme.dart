import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

class AppTheme {
  // Brand Colors
  static const Color creamBg = Color(0xFFFAF8F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color goldPrimary = Color(0xFFC4A26F);
  static const Color goldDark = Color(0xFF9E7E4E);
  static const Color goldLight = Color(0xFFF3EFE9);
  static const Color goldAccent = Color(0xFFDFB77F);
  
  // Secondary Colors
  static const Color textCharcoal = Color(0xFF2F2F2F);
  static const Color textMuted = Color(0xFF7D7A74);
  static const Color borderGoldLight = Color(0xFFEDE8E0);
  
  // Status Colors
  static const Color priorityLow = Color(0xFF9FA89E);       // Soft Sage-grey
  static const Color priorityMedium = Color(0xFFDFB77F);    // Warm Gold
  static const Color priorityHigh = Color(0xFFD48D75);      // Soft Terracotta
  
  static const Color categoryPersonal = Color(0xFF8D9E99);
  static const Color categoryWork = Color(0xFF9CA9B8);
  static const Color categoryWellness = Color(0xFFBCAAA4);
  static const Color categoryShopping = Color(0xFFC8B99D);
  static const Color categoryIdeas = Color(0xFFB2A4C0);
  
  // Soft ambient drop shadows
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: const Color(0xFF9E7E4E).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF9E7E4E).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    )
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: goldPrimary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    )
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBg,
      primaryColor: goldPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldPrimary,
        primary: goldPrimary,
        secondary: goldAccent,
        surface: cardWhite,
        onPrimary: Colors.white,
        onSecondary: textCharcoal,
        error: priorityHigh,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textCharcoal),
        titleTextStyle: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderGoldLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGoldLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGoldLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: goldPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMuted.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: textCharcoal,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: goldPrimary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  // Get color for specific task priority
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return priorityLow;
      case TaskPriority.medium:
        return priorityMedium;
      case TaskPriority.high:
        return priorityHigh;
    }
  }

  // Get color for a category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return categoryPersonal;
      case 'work':
        return categoryWork;
      case 'wellness':
        return categoryWellness;
      case 'shopping':
        return categoryShopping;
      case 'ideas':
        return categoryIdeas;
      default:
        return goldPrimary;
    }
  }

  // Get matching icon for a category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.person_outline;
      case 'work':
        return Icons.work_outline;
      case 'wellness':
        return Icons.spa_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'ideas':
        return Icons.lightbulb_outline;
      default:
        return Icons.done_all;
    }
  }
}
