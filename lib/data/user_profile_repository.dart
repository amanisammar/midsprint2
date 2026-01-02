import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository for managing user profile data in Firestore.
class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Fetches user profile data from Firestore.
  /// Returns null if the profile doesn't exist.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Alias for getUserProfile for consistency with requirements.
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    return getUserProfile(uid);
  }

  /// Creates a new user profile in Firestore.
  /// Role is initially empty and will be set later.
  Future<void> createUserProfile(
    String uid,
    String name,
    String email, {
    DateTime? birthDate,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set({
        'name': name,
        'email': email,
        'role': '', // Empty initially, set later in role selection
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Ensures profile exists, creates it if missing.
  Future<void> ensureProfileExists({
    required String uid,
    required String email,
    String? name,
  }) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) {
        await _firestore.collection(_usersCollection).doc(uid).set({
          'name': name ?? '',
          'email': email,
          'role': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error ensuring profile exists: $e');
      rethrow;
    }
  }

  /// Updates the user's role (patient or family).
  Future<void> updateUserRole(String uid, String role) async {
    try {
      // Use set with merge to avoid failures when the document doesn't exist.
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  /// Alias for updateUserRole for consistency with requirements.
  Future<void> updateRole(String uid, String role) async {
    return updateUserRole(uid, role);
  }

  /// Updates the user's name if it's missing or empty.
  Future<void> updateNameIfMissing(String uid, String name) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final currentName = data?['name'] as String?;
        if (currentName == null || currentName.isEmpty) {
          await _firestore.collection(_usersCollection).doc(uid).update({
            'name': name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
      rethrow;
    }
  }

  /// Stream of user profile for real-time updates.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots();
  }

  /// Stream of user profile data (map only) for real-time updates.
  Stream<Map<String, dynamic>?> getUserProfileStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}
