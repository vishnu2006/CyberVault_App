import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_navigator.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/login_screen.dart';
import 'screens/set_password_screen.dart';
import 'screens/vault_home_screen.dart';
import 'screens/vault_home_fake_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/document_view_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Portrait-only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const CyberFestVaultApp());
}

class CyberFestVaultApp extends StatelessWidget {
  const CyberFestVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CyberFest Vault',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AuthGateScreen.routeName,
      onGenerateRoute: (settings) {
        if (settings.name == DocumentViewScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => DocumentViewScreen(
                documentId: args['documentId'] as String,
                documentName: args['documentName'] as String,
                mimeType: args['mimeType'] as String,
                blobBase64: args['blobBase64'] as String?,
                blobHashBase64: args['blobHashBase64'] as String?,
              ),
            );
          }
        }
        return null;
      },
      routes: {
        AuthGateScreen.routeName: (context) => const AuthGateScreen(),
        SetPasswordScreen.routeName: (context) => const SetPasswordScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        VaultHomeScreen.routeName: (context) => const VaultHomeScreen(),
        VaultHomeFakeScreen.routeName: (context) => const VaultHomeFakeScreen(),
        UploadScreen.routeName: (context) => const UploadScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    // Premium dark theme colors
    const background = Color(0xFF0F172A); // Deep navy/black
    const surface = Color(0xFF111827); // Slightly lighter dark
    const cardColor = Color(0xFF1E293B); // Card background
    const primary = Color(0xFF22C55E); // Secure green
    const secondary = Color(0xFF3B82F6); // Trust blue
    const onSurface = Color(0xFFE5E7EB); // Light gray/white text
    const onBackground = Color(0xFFE5E7EB); // Light gray/white text

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        onSurface: onSurface,
        onBackground: onBackground,
        error: Color(0xFFEF4444),
        onError: Color(0xFFFFFFFF),
      ),

      // Modern AppBar with minimal elevation
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: onSurface,
          size: 24,
        ),
      ),

      // Premium cards with rounded corners and soft shadows
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Modern elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 4,
          shadowColor: primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Clean input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: TextStyle(color: onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Floating action buttons with glow effect
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        extendedTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Clean typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: onSurface,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.25,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 16,
        shadowColor: Colors.black.withOpacity(0.4),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: onSurface.withOpacity(0.1),
        thickness: 1,
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }
}
