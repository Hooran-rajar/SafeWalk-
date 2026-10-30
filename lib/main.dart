import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  if (AppConfig.firebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
    }
  }

  runApp(SafeWalkApp(firebaseReady: firebaseReady));
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  static const Color emerald = Color(0xFF087F6E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeWalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: emerald,
          primary: emerald,
          secondary: const Color(0xFFBDEFE3),
          surface: const Color(0xFFF8FCFB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FAF8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5FAF8),
          foregroundColor: Color(0xFF143A34),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCEAE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCEAE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: emerald, width: 1.5),
          ),
        ),
      ),
      home: firebaseReady
          ? const AuthGate()
          : const LoginScreen(firebaseReady: false),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          return const HomeScreen(firebaseReady: true);
        }
        return const LoginScreen(firebaseReady: true);
      },
    );
  }
}
