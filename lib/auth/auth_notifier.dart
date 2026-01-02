import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/user_profile_repository.dart';
import 'auth_status.dart';

/// AuthNotifier manages Firebase authentication state and provides
/// observable auth status and user info to the app via Provider.
class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileRepository _profileRepo = UserProfileRepository();

  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _lastErrorMessage;

  String? get lastErrorMessage => _lastErrorMessage;

  AuthNotifier() {
    // Prime status/user from any cached session so the UI doesn't hang on loading
    // if authStateChanges takes time to emit (or fails).
    try {
      _user = _auth.currentUser;
      _status = _user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading currentUser: $e');
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }

    // Listen to auth state changes and update status accordingly.
    // Start at `uninitialized` until the first event arrives.
    _auth.authStateChanges().listen(
      (User? firebaseUser) async {
        if (firebaseUser == null) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }

        _user = firebaseUser;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Proactively ensure Firestore profile exists for authenticated users.
        // This prevents role updates from failing if the profile document is missing.
        final email = firebaseUser.email;
        if (email != null && email.isNotEmpty) {
          try {
            await _profileRepo.ensureProfileExists(
              uid: firebaseUser.uid,
              email: email,
              name: '',
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('ensureProfileExists error: $e');
            }
          }
        }
      },
      onError: (error) {
        _lastErrorMessage = 'Unable to establish auth session.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        if (kDebugMode) {
          debugPrint('authStateChanges error: $error');
        }
      },
    );
  }

  User? get user => _user;
  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Attempts to sign in with email and password.
  /// Returns true on success, false on failure.
  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Optimistically update local state so UI navigates immediately;
      // authStateChanges listener will keep it in sync afterward.
      _user = _auth.currentUser;
      _status = AuthStatus.authenticated;
      notifyListeners();

      // authStateChanges listener will update status & user.
      _lastErrorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage = _friendlyAuthMessage(e);
      if (kDebugMode) {
        debugPrint('signIn error: ${e.code} ${e.message}');
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _lastErrorMessage = 'Unexpected error during sign in';
      if (kDebugMode) {
        debugPrint('signIn error: $e');
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Attempts to sign up with email and password.
  /// Creates a user profile in Firestore on success.
  /// Returns true on success, false on failure.
  Future<bool> signUp(
    String name,
    String email,
    String password, {
    required DateTime birthDate,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Optimistic local state update to drive navigation immediately.
      _user = userCredential.user;
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Create user profile in Firestore
      if (userCredential.user != null) {
        try {
          await _profileRepo.createUserProfile(
            userCredential.user!.uid,
            name,
            email,
            birthDate: birthDate,
          );
        } catch (e) {
          // If Firestore write fails, sign up technically succeeded but profile creation did not.
          // Record a friendly message and allow RootGate/ensureProfileExists to recover.
          _lastErrorMessage =
              'Account created, but failed to save profile. Please try again.';
          if (kDebugMode) {
            debugPrint('createUserProfile error: $e');
          }
        }
      }

      // authStateChanges listener will update status & user.
      _lastErrorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage = _friendlyAuthMessage(e);
      if (kDebugMode) {
        debugPrint('signUp error: ${e.code} ${e.message}');
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _lastErrorMessage = 'Unexpected error during sign up';
      if (kDebugMode) {
        debugPrint('signUp error: $e');
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user.
  /// Immediate logout effect: flip status first so UI updates instantly,
  /// then call Firebase signOut to complete the operation.
  Future<void> signOut() async {
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();

    await _auth.signOut();
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      case 'weak-password':
        return 'The password is too weak (min 6 characters).';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  /// Gets user profile from Firestore.
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;
    return await _profileRepo.getUserProfile(_user!.uid);
  }

  /// Updates user role in Firestore.
  Future<void> updateUserRole(String role) async {
    if (_user == null) return;
    await _profileRepo.updateUserRole(_user!.uid, role);
  }

  /// Sends a password reset email to the specified email address.
  /// Returns true on success, false on failure.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _lastErrorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage = _friendlyAuthMessage(e);
      if (kDebugMode) {
        debugPrint('sendPasswordResetEmail error: ${e.code} ${e.message}');
      }
      return false;
    } catch (e) {
      _lastErrorMessage = 'Failed to send password reset email.';
      if (kDebugMode) {
        debugPrint('sendPasswordResetEmail error: $e');
      }
      return false;
    }
  }
}
