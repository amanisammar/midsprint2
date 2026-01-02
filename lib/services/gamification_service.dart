import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'history_service.dart';

class GamificationResult {
  final int pointsAwarded;
  final int streakDays;
  final bool streakMilestone;
  final bool fullDayAwarded;
  final bool onTime;
  final double? fullDayAdherence;

  const GamificationResult({
    required this.pointsAwarded,
    required this.streakDays,
    required this.streakMilestone,
    required this.fullDayAwarded,
    required this.onTime,
    this.fullDayAdherence,
  });
}

class GamificationService {
  GamificationService({FirebaseFirestore? firestore, HistoryService? historyService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _historyService = historyService ?? HistoryService();

  final FirebaseFirestore _firestore;
  final HistoryService _historyService;

  static const _streakMilestones = {3, 7, 14, 21, 30, 60, 90};

  String _buildDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  Future<GamificationResult> awardDose({
    required String uid,
    required DateTime scheduledAt,
    required DateTime takenAt,
  }) async {
    final dateKey = _buildDateKey(scheduledAt);
    final onTime = takenAt.isBefore(scheduledAt.add(const Duration(minutes: 30)));
    final basePoints = onTime ? 10 : 5;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final data = userSnap.data() ?? {};

      final currentPoints = (data['points'] as num?)?.toInt() ?? 0;
      final currentStreak = (data['streakDays'] as num?)?.toInt() ?? 0;
      final longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
      final lastStreakDate = data['lastStreakDate'] as String?;
      final awardedFullDaysRaw = (data['awardedFullDays'] as List?) ?? [];
      final awardedFullDays = awardedFullDaysRaw.cast<String>().toSet();

      // Compute streak with zero-meds grace.
      final todayDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
      int updatedStreak = currentStreak;

      if (lastStreakDate == null) {
        updatedStreak = 1;
      } else {
        final lastDate = _parseDateKey(lastStreakDate);
        final gap = todayDate.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;

        if (gap == 0) {
          // already counted today
        } else if (gap == 1) {
          updatedStreak = currentStreak + 1;
        } else if (gap > 1) {
          // Check if any missing day had scheduled doses; if none, keep streak, else reset.
          bool broke = false;
          for (int i = 1; i < gap; i++) {
            final checkDate = lastDate.add(Duration(days: i));
            final summary = await _historyService.getDaySummary(uid, checkDate);
            if (summary.scheduledCount > 0 && summary.takenCount < summary.scheduledCount) {
              broke = true;
              break;
            }
          }
          updatedStreak = broke ? 1 : currentStreak + 1;
        }
      }

      final newLongest = updatedStreak > longestStreak ? updatedStreak : longestStreak;
      bool streakMilestone = _streakMilestones.contains(updatedStreak);

      // Full day adherence award (after logging dose, recompute day summary)
      final daySummary = await _historyService.getDaySummary(uid, todayDate);
      bool fullDayAwarded = false;
      int extraPoints = 0;
      if (daySummary.scheduledCount > 0 &&
          daySummary.takenCount == daySummary.scheduledCount &&
          !awardedFullDays.contains(dateKey)) {
        fullDayAwarded = true;
        extraPoints += 20;
        awardedFullDays.add(dateKey);
      }

      final totalAward = basePoints + extraPoints;

      await userRef.set({
        'points': currentPoints + totalAward,
        'streakDays': updatedStreak,
        'longestStreak': newLongest,
        'lastStreakDate': dateKey,
        'awardedFullDays': awardedFullDays.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return GamificationResult(
        pointsAwarded: totalAward,
        streakDays: updatedStreak,
        streakMilestone: streakMilestone,
        fullDayAwarded: fullDayAwarded,
        onTime: onTime,
        fullDayAdherence: daySummary.adherencePercent,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Gamification award error: $e');
      }
      return const GamificationResult(
        pointsAwarded: 0,
        streakDays: 0,
        streakMilestone: false,
        fullDayAwarded: false,
        onTime: false,
      );
    }
  }

  Future<void> awardRefill(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'points': FieldValue.increment(15),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Gamification refill award error: $e');
      }
    }
  }

  Future<void> awardProfileCompletion(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'points': FieldValue.increment(10),
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Gamification profile completion error: $e');
      }
    }
  }
}
