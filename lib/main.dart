import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Firebase
import 'firebase_options.dart';

// Auth & state
import 'auth/auth_notifier.dart';
import 'root_gate.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'features/medicines/add_medicine_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using generated configuration.
  // Web and Android are configured via FlutterFire (see lib/firebase_options.dart).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Ensure web keeps the session cached (so users stay signed in across reloads).
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    // As a fallback (e.g., if running on an unsupported desktop platform),
    // try default initialization to avoid crashing.
    await Firebase.initializeApp();
  }

  runApp(const PillCareApp());
}

class PillCareApp extends StatelessWidget {
  const PillCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthNotifier>(
      create: (_) => AuthNotifier(),
      child: MaterialApp(
        title: 'PillCare',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2EC4B6), // teal
            primary: const Color(0xFF2EC4B6),
            secondary: const Color(0xFF4D96FF),
            surface: const Color(0xFFF7F4EF),
          ),

          scaffoldBackgroundColor: const Color(0xFFF7F4EF),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            labelStyle: const TextStyle(color: Color(0xFF2E2E2E)),
            floatingLabelStyle: const TextStyle(color: Color(0xFF2EC4B6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDADADA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2EC4B6), width: 2),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
        ),

        home: const RootGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          SignupScreen.routeName: (_) => const SignupScreen(),
          RoleSelectionScreen.routeName: (_) => const RoleSelectionScreen(),
          '/add-medicine': (_) => const AddMedicineScreen(),
        },
      ),
    );
  }
}
