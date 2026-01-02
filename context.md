# PillCare Project Context

## Overview
- Flutter medication management app using Firebase Auth + Cloud Firestore and Provider for state; Material 3 theme with teal palette. Entry point `lib/main.dart` initializes Firebase and mounts `PillCareApp`.
- Platforms: standard Flutter scaffolding for Android/iOS/web/macos/windows/linux. Android has `android/app/google-services.json`; `lib/firebase_options.dart` is a placeholder requiring `flutterfire configure` to supply real keys.
- User roles are stored in Firestore profiles (`users` collection) and drive navigation (patient vs family member).

## Dependencies & Tooling
- Dart/Flutter: sdk ^3.9.2.
- Packages: `firebase_core` 2.32.0, `firebase_auth` 4.16.0, `cloud_firestore` 4.1.0, `provider` 6.0.0, `cupertino_icons` 1.0.8; dev: `flutter_lints` 5.0.0.
- Linting: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` defaults; no custom rules.
- Tests: `test/widget_test.dart` is empty.

## App Startup & Routing (lib/main.dart)
- Calls `WidgetsFlutterBinding.ensureInitialized()` then `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` with debug prints before/after.
- Wraps `MaterialApp` in `ChangeNotifierProvider<AuthNotifier>`.
- Theme: Material 3, seed color #2EC4B6 (teal), background #F7F4EF, styled inputs and elevated buttons.
- Home: `RootGate` decides screen based on auth/profile. Routes: `/login`, `SignupScreen.routeName` (`/signup`), `RoleSelectionScreen.routeName` (`/role-selection`), `/add-medicine` -> `AddMedicineScreen`.

## Auth Flow
- `auth_status.dart`: enum {uninitialized, authenticating, authenticated, unauthenticated}.
- `auth_notifier.dart`: wraps `FirebaseAuth`. Listens to `authStateChanges` to set status and user; ensures Firestore profile exists via `UserProfileRepository.ensureProfileExists` when a user logs in. Methods: `signIn`, `signUp` (creates profile with empty role), `signOut` (optimistically sets status unauthenticated), `getUserProfile`, `updateUserRole`. Friendly error messages stored in `lastErrorMessage`.
- `UserProfileRepository` (lib/data/user_profile_repository.dart): Firestore collection `users` with fields {name, email, role, createdAt, updatedAt}. Functions to `getUserProfile`/`getProfile`, `createUserProfile`, `ensureProfileExists`, `updateUserRole`/`updateRole` (merge), `updateNameIfMissing`, and realtime streams (`watchProfile`, `getUserProfileStream`).

## Screen Flow
- `RootGate` (main.dart):
  - Shows loading while auth is uninitialized/authenticating.
  - Unauthenticated -> `LoginScreen`.
  - Authenticated -> stream user profile; ensures profile doc exists (using email) when missing. If profile missing or `role` empty -> `RoleSelectionScreen`; otherwise -> `HomeScreen(role, name)`. Retry button on stream error.
- `LoginScreen` (lib/screens/auth/login_screen.dart): email/password fields, calls `AuthNotifier.signIn`, shows snackbar on failure, navigation to signup via `MaterialPageRoute`. Background blob decor; tries to load `assets/images/pillcare_logo.png` (pubspec assets not declared, so may fall back to icon).
- `SignupScreen` (lib/screens/auth/signup_screen.dart): collects name/email/password, validates required and password length >=6, calls `AuthNotifier.signUp`, shows errors via snackbar, pops on success (RootGate handles navigation). Busy state when auth is authenticating.
- `RoleSelectionScreen` (lib/screens/onboarding/role_selection_screen.dart): choose `patient` or `family`, uses `PillLogoAnimated`, updates role via `AuthNotifier.updateUserRole`, continue button disabled until selection; background blobs.
- `HomeScreen` (lib/screens/home/home_screen.dart): shows greeting with role badge and email, logout icon triggers `AuthNotifier.signOut` + snackbar; settings icon placeholder; no navigation to medicines yet.
- `AddMedicineScreen` (lib/features/medicines/add_medicine_screen.dart): RTL layout with Hebrew labels currently mojibake; collects name, dosage, notes; selectable times (morning/noon/evening/night) with colored icons; submit button placeholder (“Firebase logic later”). Route `/add-medicine` registered but not linked from UI.

## Services & Data
- `MedicineService` (lib/features/medicines/medicine_service.dart): `addMedicine` writes to Firestore `users/{uid}/medicines` with fields {name, dose, times, notes, createdAt: Timestamp.now()}; throws if no logged-in user. Not yet used by UI.
- `firebase_options.dart`: generated placeholder; REPLACE_* values for web/android/ios/macos; `isConfigured` helper checks whether placeholders were replaced.

## UI Components
- `PillLogo`/`PillLogoAnimated` (lib/widgets/pill_logo.dart): custom drawn capsule with optional halo/badge and simple scale/opacity animation; used on role selection screen.

## Assets & Styling Notes
- Theme colors teal + pastel backgrounds; scaffold background #F7F4EF.
- Asset reference `assets/images/pillcare_logo.png` not listed in `pubspec.yaml`; add under `flutter.assets` if needed.
- Comments/labels in `AddMedicineScreen` contain non-ASCII mojibake; likely intended Hebrew strings.

## Platform/Config Files
- Android: `android/app/google-services.json` present (not summarized here to avoid exposing keys). iOS/macOS entitlements and default Runner files untouched. No custom platform code beyond Flutter templates.

## Gaps/TODOs for future agents
- Configure Firebase via `flutterfire configure` (update `lib/firebase_options.dart`, ensure Android/iOS configs align).
- Wire `AddMedicineScreen` to `MedicineService.addMedicine` and expose navigation from Home; fix Hebrew text encoding/localization.
- Declare required assets (e.g., pillcare logo) in `pubspec.yaml`.
- Add tests and richer error handling; consider settings/profile editing and medicine list UI.