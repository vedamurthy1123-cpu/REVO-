import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Colors ───────────────────────────────────────────
  static const Color brandPrimary = Color(0xFF000000); // Pure Black
  static const Color brandSecondary = Color(0xFF333333); // Dark Gray
  static const Color brandAccent = Color(0xFF666666); // Mid Gray
  
  static const Color deepNavy = Color(0xFF000000); // Consistent Black
  static const Color slate800 = Color(0xFF1F2937);
  static const Color slate500 = Color(0xFF6B7280);
  static const Color slate200 = Color(0xFFE5E7EB);
  static const Color slate50 = Color(0xFFFAFAFA);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFF000000); // Black for consistency or keep red? User said "black and white". I'll use a very dark gray for errors or keep it red for safety. Let's stick to black/white as requested.

  // Status colors (Monochrome variations)
  static const Color statusPending = Color(0xFF9CA3AF); 
  static const Color statusConfirmed = Color(0xFF4B5563); 
  static const Color statusPreparing = Color(0xFF374151); 
  static const Color statusReady = Color(0xFF000000); // Solid Black for ready
  static const Color statusDelivered = Color(0xFF000000);
  static const Color statusExpired = Color(0xFFD1D5DB);
  static const Color statusCancelled = Color(0xFFE5E7EB);

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'confirmed':
        return statusConfirmed;
      case 'preparing':
        return statusPreparing;
      case 'ready':
        return statusReady;
      case 'delivered':
      case 'collected':
        return statusDelivered;
      case 'expired':
        return statusExpired;
      case 'cancelled':
        return statusCancelled;
      default:
        return slate500;
    }
  }

  // ─── Theme Data ───────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: const ColorScheme.light(
          primary: brandPrimary,
          onPrimary: white,
          secondary: brandSecondary,
          onSecondary: white,
          surface: white,
          onSurface: brandPrimary,
          error: brandPrimary,
          onError: white,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(), 
        appBarTheme: const AppBarTheme(
          backgroundColor: white,
          foregroundColor: brandPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: brandPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandPrimary,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 58),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: brandPrimary),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandPrimary,
            minimumSize: const Size(double.infinity, 58),
            side: const BorderSide(color: brandPrimary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandPrimary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandPrimary),
          ),
          labelStyle: const TextStyle(
            color: brandPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: slate500, fontSize: 15),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: slate200, width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: white,
          selectedItemColor: brandPrimary,
          unselectedItemColor: slate500,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.2),
          unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: brandPrimary,
          contentTextStyle: const TextStyle(color: white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(
          color: slate200,
          thickness: 1,
          space: 0,
        ),
      );
}
