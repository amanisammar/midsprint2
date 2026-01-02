import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/dose_log.dart';
import 'gamification_service.dart';
import 'history_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final HistoryService _historyService = HistoryService();
  final GamificationService _gamificationService = GamificationService();

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

    await _checkProfileCompletion(uid);

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

    await _checkProfileCompletion(uid);

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

    await _checkProfileCompletion(uid);
  }

  Future<String> uploadAvatar({
    required String uid,
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    if (file == null && bytes == null) {
      throw ArgumentError('Either file or bytes must be provided');
    }

    // Read the current photo path (if any) so we can delete stale files
    String? previousPath;
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      previousPath = (snap.data() ?? {})['photoPath'] as String?;
    } catch (_) {
      // Ignore – best-effort cleanup only
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = filename ?? 'avatar.jpg';
    final path = 'avatars/$uid/$timestamp-$safeName';
    final ref = _storage.ref().child(path);

    if (bytes != null) {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else if (file != null) {
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    }

    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).set({
      'photoUrl': url,
      'photoPath': path,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _checkProfileCompletion(uid);

    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhotoURL(url);
    }

    // Best-effort delete of the old avatar to avoid storage bloat
    if (previousPath != null && previousPath != path) {
      try {
        await _storage.ref().child(previousPath).delete();
      } catch (_) {
        // Ignore cleanup errors
      }
    }

    return url;
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

  /// Compute adherence using HistoryService for consistency
  Future<({int taken, int missed, double adherence})> computeAdherenceFromLogs(
    List<DoseLog> logs,
  ) async {
    // Get the UID from the first log, or return zeros if no logs
    if (logs.isEmpty) {
      return (taken: 0, missed: 0, adherence: 0.0);
    }

    // Use HistoryService to get accurate scheduled counts
    // Note: This is a simplified version. For full accuracy, we'd need the uid
    // For now, use the old logic but with improved calculation
    final taken = logs.where((l) => l.status == DoseStatus.taken).length;
    final total = logs.length;
    final adherence = total == 0 ? 0.0 : (taken / total) * 100;
    
    // Calculate missed based on what we have
    final missed = total - taken;
    
    return (taken: taken, missed: missed, adherence: adherence);
  }

  /// Alternative: Get adherence using HistoryService directly (more accurate)
  Future<({int taken, int missed, double adherence})> getWeeklyAdherence(
    String uid,
  ) async {
    final summaries = await _historyService.getLast7DaysSummary(uid);
    
    final totalTaken = summaries.fold<int>(0, (acc, s) => acc + s.takenCount);
    final totalMissed = summaries.fold<int>(0, (acc, s) => acc + s.missedCount);
    final totalScheduled = summaries.fold<int>(0, (acc, s) => acc + s.scheduledCount);
    
    final adherence = totalScheduled > 0 
        ? (totalTaken / totalScheduled) * 100 
        : 0.0;
    
    return (taken: totalTaken, missed: totalMissed, adherence: adherence);
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

  Future<void> _checkProfileCompletion(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final hasName = (data['displayName'] as String? ?? '').trim().isNotEmpty;
      final hasPhoto = (data['photoUrl'] as String? ?? '').isNotEmpty;
      final alreadyAwarded = data['profileCompleted'] as bool? ?? false;

      if (hasName && hasPhoto && !alreadyAwarded) {
        await _gamificationService.awardProfileCompletion(uid);
      }
    } catch (_) {
      // Do not block profile update on gamification errors
    }
  }
}
