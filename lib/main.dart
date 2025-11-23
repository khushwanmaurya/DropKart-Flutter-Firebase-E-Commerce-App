// lib/main.dart
import 'package:dropkart_app/firebase_options.dart';
import 'package:dropkart_app/screens/landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch synchronous Flutter errors and print them to console.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // You can also report to analytics/logging here.
  };

  // Initialize Firebase safely. If it fails, we still start the app but print error.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // Log the firebase init error — useful when running on web without firebase_options configured.
    debugPrint('Firebase initialization error: $e');
    debugPrint('$st');
  }

  // Use runZonedGuarded to catch any uncaught async errors.
  runZonedGuarded(
        () => runApp(const DropkartApp()),
        (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('$stack');
    },
  );
}

class DropkartApp extends StatelessWidget {
  const DropkartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFFF6A00); // warm orange
    final accent = const Color(0xFF00A896); // teal accent

    return MaterialApp(
      title: "Dropkart",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: accent),
        primaryColor: primary,
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),

        // <-- REPLACED: use a compatible CardTheme value for current SDK
      ),
      // Keep routing simple: LandingPage is the current entry point in your project
      home: const LandingPage(),
      // Optional: catch unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Page not found')),
        ),
      ),
    );
  }
}
