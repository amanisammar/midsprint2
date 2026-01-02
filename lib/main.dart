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
import 'theme/theme_controller.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(create: (_) => AuthNotifier()),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'PillCare',
            debugShowCheckedModeBanner: false,
            theme: themeController.theme,
            home: const RootGate(),
            routes: {
              '/login': (_) => const LoginScreen(),
              SignupScreen.routeName: (_) => const SignupScreen(),
              RoleSelectionScreen.routeName: (_) => const RoleSelectionScreen(),
              '/add-medicine': (_) => const AddMedicineScreen(),
            },
          );
        },
      ),
    );
  }
}
