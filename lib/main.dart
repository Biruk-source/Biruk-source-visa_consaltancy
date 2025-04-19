import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/app_strings.dart'; // Your strings file
import 'providers/locale_provider.dart'; // Your LocaleProvider
import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/visa_application.dart';
import 'screens/visa_application_form_screen.dart';
// Assuming AuthWrapper might use it indirectly

// Screen imports
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile.dart';
import 'screens/Setting.dart'; // Consider renaming Setting.dart -> settings_screen.dart

import 'screens/visa_recommendations_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Consider an error screen if Firebase init fails
  }
  runApp(
    // Wrap the entire app with the ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(), // Create the provider instance
      child: const MyApp(),
    ),
  );
}

// MyApp no longer needs to be stateful for locale, provider handles it
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume the LocaleProvider to get the current locale
    // This rebuilds MaterialApp when locale changes
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Get the correct TextTheme based on the current locale from provider
    final currentStrings = AppLocalizations.getStrings(localeProvider.locale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visa Consultancy',

      // --- Localization Setup ---
      locale: localeProvider.locale, // Get locale from Provider
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('am', '')],
      // --- End Localization Setup ---

      // Apply the correct TextTheme based on the current language
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Set the TextTheme for the ENTIRE app based on locale
        textTheme: currentStrings.textTheme.apply(
          bodyColor: Colors.black87, // Default text color for light theme
          displayColor: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        // ... other light theme settings ...
        appBarTheme: const AppBarTheme(
          elevation: 1,
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          iconTheme: IconThemeData(color: Colors.teal),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: Colors.teal, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.teal,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      // Example dark theme applying appropriate text theme
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFF011015),
        // Set the TextTheme for the ENTIRE dark theme
        textTheme: currentStrings.textTheme.apply(
          bodyColor: Colors.white70, // Default text color for dark theme
          displayColor: Colors.white,
        ),
        // Add other dark theme overrides as needed
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          // In darkTheme -> appBarTheme -> titleTextStyle:
          titleTextStyle: currentStrings.textTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.dark, // Example: Start in dark mode

      home: const SplashScreen(), // Keep entry point
      routes: {
        // Your routes
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/setting': (context) => const SettingScreen(), // Ensure correct path
        '/visa_progress': (context) => const VisaApplicationsScreen(),
        '/recommendations': (context) => VisaRecommendationsScreen(),
        '/visa_form': (context) => const VisaApplicationFormScreen(),
      },
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: Text(
                      AppLocalizations.getStrings(
                        localeProvider.locale,
                      ).errorGeneric,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}

// --- KEEP SplashScreen ---
class SplashScreen extends StatefulWidget {
  // ... (SplashScreen code remains the same) ...
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/globe.png', // Make sure this asset exists
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal.withOpacity(0.3),
                        ),
                        child: const Icon(
                          Icons.public,
                          size: 80,
                          color: Colors.tealAccent,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Visa & Education Consultancy', // This is fine not localized for splash maybe
                  style: GoogleFonts.poppins(
                    // Use a specific font if desired
                    fontSize: 26, // Adjusted size slightly
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3), // Simpler shadow
                        blurRadius: 6,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- KEEP AuthWrapper ---
class AuthWrapper extends StatelessWidget {
  // ... (AuthWrapper code remains the same) ...
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Authentication Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        // Navigate based on auth state
        return snapshot.hasData
            ? const HomeScreen()
            : const WelcomeScreen(); // Maybe go to Welcome first now? Or keep LoginScreen? Decide flow.
        // ^^^ CHANGE THIS ^^^ : Decide if unauthenticated users see Welcome or Login first.
      },
    );
  }
}
