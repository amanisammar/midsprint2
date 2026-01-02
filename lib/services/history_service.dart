import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dose_log.dart';

/// Data class for daily adherence summary.
class DaySummary {
  final DateTime date;
  final String dateKey;
  final int scheduledCount;
  final int takenCount;
  final int missedCount;
  final double adherencePercent;

  const DaySummary({
    required this.date,
    required this.dateKey,
    required this.scheduledCount,
    required this.takenCount,
    required this.missedCount,
    required this.adherencePercent,
  });
}

/// Instance of a scheduled dose
class DoseInstance {
  final String medicineId;
  final String medName;
  final String timeKey;
  final DateTime scheduledAt;

  const DoseInstance({
    required this.medicineId,
    required this.medName,
    required this.timeKey,
    required this.scheduledAt,
  });
}

/// Service for computing medicine history and adherence statistics
class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get 7-day summary (today + previous 6 days)
  Future<List<DaySummary>> getLast7DaysSummary(String uid) async {
    final now = DateTime.now();
    final summaries = <DaySummary>[];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final summary = await getDaySummary(uid, date);
      summaries.add(summary);
    }

    return summaries;
  }

  /// Get summary for a specific date
  Future<DaySummary> getDaySummary(String uid, DateTime date) async {
    final dateKey = _buildDateKey(date);
    
    // Get all scheduled doses for this date
    final scheduledDoses = await getScheduledDoseInstancesForDate(uid, date);
    final scheduledCount = scheduledDoses.length;

    if (scheduledCount == 0) {
      return DaySummary(
        date: date,
        dateKey: dateKey,
        scheduledCount: 0,
        takenCount: 0,
        missedCount: 0,
        adherencePercent: 0.0,
      );
    }

    // Get all dose logs for this date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('doseLogs')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final takenLogs = logsSnapshot.docs
        .map(DoseLog.fromDoc)
        .where((log) => log.status == DoseStatus.taken)
        .toList();

    // Create a set of taken dose keys for quick lookup
    final takenKeys = takenLogs
        .map((log) => '${log.medicineId}_${log.timeKey}')
        .toSet();

    // Count how many scheduled doses were taken
    int takenCount = 0;
    for (final dose in scheduledDoses) {
      final key = '${dose.medicineId}_${dose.timeKey}';
      if (takenKeys.contains(key)) {
        takenCount++;
      }
    }

    final missedCount = scheduledCount - takenCount;
    final adherencePercent = (takenCount / scheduledCount) * 100;

    return DaySummary(
      date: date,
      dateKey: dateKey,
      scheduledCount: scheduledCount,
      takenCount: takenCount,
      missedCount: missedCount,
      adherencePercent: adherencePercent,
    );
  }

  /// Get all scheduled dose instances for a specific date
  /// Uses the same logic as today_medicine.dart to determine which doses are scheduled
  Future<List<DoseInstance>> getScheduledDoseInstancesForDate(
    String uid,
    DateTime date,
  ) async {
    final instances = <DoseInstance>[];
    final currentDay = _getCurrentDay(date.weekday);
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Get all medicines for this user
    final medicinesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .get();

    for (final medicineDoc in medicinesSnapshot.docs) {
      final data = medicineDoc.data();
      final medicineId = medicineDoc.id;
      final medName = data['name'] as String? ?? 'Unnamed';

      // Check if medicine is active on this day
      final days = (data['days'] as List?)?.cast<String>() ?? [];
      final validDay = days.contains(currentDay);

      // Check date range
      final startTimestamp = data['startDate'] as Timestamp?;
      final endTimestamp = data['endDate'] as Timestamp?;

      final startDate = startTimestamp?.toDate();
      final endDate = endTimestamp?.toDate();

      final validDate =
          (startDate == null || !dateOnly.isBefore(startDate)) &&
          (endDate == null || !dateOnly.isAfter(endDate));

      if (!validDay || !validDate) continue;

      // Get scheduled times for this medicine
      final times = (data['timesOfDay'] as List?)?.cast<String>() ?? [];

      for (final timeKey in times) {
        final scheduledAt = _combineDateAndTimeKey(dateOnly, timeKey);
        instances.add(DoseInstance(
          medicineId: medicineId,
          medName: medName,
          timeKey: timeKey,
          scheduledAt: scheduledAt,
        ));
      }
    }

    return instances;
  }

  /// Build date key (YYYY-MM-DD)
  String _buildDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get current day name from weekday number
  String _getCurrentDay(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Combine date and time key into DateTime
  DateTime _combineDateAndTimeKey(DateTime day, String timeKey) {
    final parts = timeKey.split(':');
    if (parts.length != 2) return day;
    
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Stream version for real-time updates
  Stream<List<DaySummary>> watchLast7DaysSummary(String uid) {
    // Return a stream that recomputes every time doseLogs changes
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('doseLogs')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .snapshots()
        .asyncMap((_) => getLast7DaysSummary(uid));
  }
}
