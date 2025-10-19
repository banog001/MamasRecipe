import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebaseOption.dart'; // your Firebase web options
import 'adminLogin.dart'; // login page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Prevent duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const LoginPage(),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color backgroundColor = Color(0xFF121212); // Deep charcoal
    const Color surfaceColor = Color(0xFF1E1E1E); // Slightly lighter
    const Color primaryColor = Color(0xFF0D63F5); // Vibrant blue
    const Color textColor = Colors.white;
    const Color hintColor = Color(0xFFAAAAAA); // Subtle grey
    const Color dividerColor = Color(0xFF2A2A2A); // Divider lines
    const Color errorColor = Color(0xFFCF6679);
    const String fontFamily = 'PlusJakartaSans';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // --- PRIMARY COLORS ---
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // --- COLOR SCHEME ---
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textColor,
        onSecondary: textColor,
        onSurface: textColor,
        onError: textColor,
      ),

      // --- APP BAR STYLING ---
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),

      // --- CARD STYLING ---
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),

      // --- INPUT DECORATION ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: hintColor,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: hintColor,
          fontSize: 14,
        ),
        prefixIconColor: hintColor,
        suffixIconColor: hintColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      // --- BUTTON STYLING ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- DIVIDER STYLING ---
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 16,
      ),

      // --- TEXT STYLING ---
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displayMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displaySmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineSmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        titleSmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: hintColor,
        ),
        bodyLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
        bodyMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
        bodySmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: hintColor,
        ),
        labelLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),

      // --- ICON STYLING ---
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // --- FLOATING ACTION BUTTON ---
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // --- BOTTOM NAVIGATION ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: hintColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // --- DIALOG STYLING ---
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: textColor,
        ),
      ),

      // --- SNACKBAR STYLING ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: textColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
    );
  }
}
