import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';
import '../models/dose_log.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<AppUser?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Future<void> updateDisplayName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
    }
  }

  Future<void> updatePhotoUrl(String uid, String url) async {
    await _firestore.collection('users').doc(uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhotoURL(url);
    }
  }

  Future<void> updateShareWithFamily(String uid, bool value) async {
    await _firestore.collection('users').doc(uid).set({
      'shareWithFamily': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<List<DoseLog>> getDoseLogsLast7Days(String uid) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final query = await _firestore
        .collection('users')
        .doc(uid)
        .collection('doseLogs')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('scheduledAt', descending: true)
        .get();

    return query.docs.map(DoseLog.fromDoc).toList();
  }

  ({int taken, int missed, double adherence}) computeAdherenceFromLogs(
      List<DoseLog> logs) {
    final taken = logs.where((l) => l.status == DoseStatus.taken).length;
    final missed = logs.where((l) => l.status == DoseStatus.missed).length;
    final total = taken + missed;
    final adherence = total == 0 ? 0.0 : (taken / total) * 100;
    return (taken: taken, missed: missed, adherence: adherence);
  }

  Future<void> deleteUserData(String uid) async {
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(uid));

    // Delete medicines subcollection
    final medicinesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .get();
    for (final doc in medicinesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete dose logs subcollection
    final doseLogsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('doseLogs')
        .get();
    for (final doc in doseLogsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit all deletions
    await batch.commit();

    // Delete user avatar from storage if exists
    try {
      final avatarRef = _storage.ref().child('avatars').child('$uid.jpg');
      await avatarRef.delete();
    } catch (e) {
      // Avatar might not exist, ignore error
    }
  }
}
