import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing dose logs in Firestore.
/// Provides methods to write dose events with deterministic IDs and backfill from legacy data.
class DoseLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Build a date key string (YYYY-MM-DD) from a DateTime
  String buildDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Combine a date and time key (HH:MM) into a single DateTime
  /// Uses local time zone
  DateTime combineDateAndTimeKey(DateTime day, String timeKey) {
    final parts = timeKey.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid timeKey format: $timeKey. Expected HH:MM');
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Build a deterministic dose log ID
  /// Format: medicineId_dateKey_timeKeySanitized
  String buildDoseLogId(String medicineId, String dateKey, String timeKey) {
    final sanitizedTimeKey = timeKey.replaceAll(':', '-');
    return '${medicineId}_${dateKey}_$sanitizedTimeKey';
  }

  /// Write a dose log when user marks a dose as taken
  /// Uses merge: true to be idempotent (safe to call multiple times)
  Future<void> logDoseTaken({
    required String uid,
    required String medicineId,
    required String medName,
    required String dateKey,
    required String timeKey,
  }) async {
    try {
      final logId = buildDoseLogId(medicineId, dateKey, timeKey);
      final day = _parseDateKey(dateKey);
      final scheduledAt = combineDateAndTimeKey(day, timeKey);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('doseLogs')
          .doc(logId)
          .set({
        'medicineId': medicineId,
        'medName': medName,
        'dateKey': dateKey,
        'timeKey': timeKey,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'takenAt': FieldValue.serverTimestamp(),
        'status': 'taken',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw to avoid disrupting UI
      if (kDebugMode) {
        debugPrint('Error logging dose taken: $e');
      }
    }
  }

  /// Parse a dateKey (YYYY-MM-DD) into a DateTime
  DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return DateTime.now();
    }
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  /// Backfill dose logs from dailyTaken for the last N days
  Future<void> backfillDoseLogsFromDailyTaken(String uid, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      // Get all medicines for this user
      final medicinesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .get();

      final batch = _firestore.batch();
      int batchCount = 0;

      for (final medicineDoc in medicinesSnapshot.docs) {
        final medicineId = medicineDoc.id;
        final data = medicineDoc.data();
        final medName = data['name'] as String? ?? 'Unnamed';
        final dailyTaken = data['dailyTaken'] as Map<String, dynamic>? ?? {};

        // Process each date in dailyTaken that falls within last N days
        for (final entry in dailyTaken.entries) {
          final dateKey = entry.key;
          final day = _parseDateKey(dateKey);

          // Skip if outside our date range
          if (day.isBefore(startDate) || day.isAfter(now)) continue;

          final timeKeys = (entry.value as List?)?.cast<String>() ?? [];

          for (final timeKey in timeKeys) {
            try {
              final logId = buildDoseLogId(medicineId, dateKey, timeKey);
              final scheduledAt = combineDateAndTimeKey(day, timeKey);
              final docRef = _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('doseLogs')
                  .doc(logId);

              batch.set(docRef, {
                'medicineId': medicineId,
                'medName': medName,
                'dateKey': dateKey,
                'timeKey': timeKey,
                'scheduledAt': Timestamp.fromDate(scheduledAt),
                'takenAt': Timestamp.fromDate(scheduledAt),
                'status': 'taken',
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              batchCount++;

              // Firestore batch limit is 500, commit and start new batch if needed
              if (batchCount >= 450) {
                await batch.commit();
                batchCount = 0;
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error backfilling log for $medicineId $dateKey $timeKey: $e');
              }
            }
          }
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        debugPrint('Backfill complete: processed $batchCount dose logs');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during backfill: $e');
      }
      rethrow;
    }
  }
}
