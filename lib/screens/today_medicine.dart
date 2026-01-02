import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';

class TodayMedicineTab extends StatefulWidget {
  final String role;
  final String? name;
  final String? userEmail;

  const TodayMedicineTab({
    super.key,
    required this.role,
    this.name,
    this.userEmail,
  });

  @override
  State<TodayMedicineTab> createState() => _TodayMedicineTabState();
}

class _TodayMedicineTabState extends State<TodayMedicineTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update status every minute for real-time changes
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _markAsTaken(
    String docId,
    String timeKey,
    String todayDate,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(docId);

      final doc = await docRef.get();
      final data = doc.data();
      final dailyTaken = Map<String, dynamic>.from(data?['dailyTaken'] ?? {});
      final takenList = List<String>.from(dailyTaken[todayDate] ?? []);

      if (!takenList.contains(timeKey)) {
        takenList.add(timeKey);
        dailyTaken[todayDate] = takenList;
        await docRef.update({'dailyTaken': dailyTaken});

        // Award 10 points for taking medicine on time
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'points': FieldValue.increment(10)});
      }
    } catch (e) {
      // Handle error, maybe show snackbar
      debugPrint('Error marking as taken: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text(context.loc.t('signInToView')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final points = userData?['points'] ?? 0;

        final stream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .snapshots();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PointsCard(points: points),
              const SizedBox(height: 12),

              Text(
                context.loc.t('todayMedicinesTitle'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text(context.loc.t('failedLoad')));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(child: Text(context.loc.t('noMedicines')));
                    }

                    final now = DateTime.now();
                    final currentDay = _getCurrentDay(now.weekday);
                    final currentTime = TimeOfDay.fromDateTime(now);
                    final todayDate =
                        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                    /// 🔹 סינון תרופות לפי היום והתאריכים
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data();

                      /// 🔹 ימים
                      final days =
                          (data['days'] as List?)?.cast<String>() ?? [];
                      final validDay = days.contains(currentDay);

                      /// 🔹 תאריכים
                      final startTimestamp = data['startDate'] as Timestamp?;
                      final endTimestamp = data['endDate'] as Timestamp?;

                      final nowDate = DateTime(now.year, now.month, now.day);

                      final startDate = startTimestamp?.toDate();
                      final endDate = endTimestamp?.toDate();

                      final validDate =
                          (startDate == null || !nowDate.isBefore(startDate)) &&
                          (endDate == null || !nowDate.isAfter(endDate));

                      return validDay && validDate;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(context.loc.t('noMedicinesToday')),
                      );
                    }

                    /// 🔹 בניית רשימת תרופות להיום
                    final todayMedicines = <Map<String, dynamic>>[];

                    for (final doc in filteredDocs) {
                      final data = doc.data();

                      final name = data['name'] as String? ?? 'Unnamed';

                      final dosage = data['dosage'];
                      final unit = data['unit'] ?? '';
                      final dose = dosage != null
                          ? '$dosage $unit'
                          : unit.toString();

                      final times =
                          (data['timesOfDay'] as List?)?.cast<String>() ?? [];

                      final takenTimes =
                          (data['dailyTaken']?[todayDate] as List?)
                              ?.cast<String>() ??
                          [];

                      for (final timeKey in times) {
                        final timeValue = _parseTime(timeKey);
                        if (timeValue == null) continue;

                        final isTaken = takenTimes.contains(timeKey);
                        final status = isTaken
                            ? 'taken'
                            : _getStatus(timeKey, currentTime);

                        todayMedicines.add({
                          'name': name,
                          'dose': dose,
                          'timeLabel': _getTimeDisplay(timeKey),
                          'timeValue': timeValue,
                          'status': status,
                          'isTaken': isTaken,
                          'docId': doc.id,
                          'timeKey': timeKey,
                        });
                      }
                    }

                    /// 🔹 מיון מהבוקר לערב
                    todayMedicines.sort((a, b) {
                      final t1 = a['timeValue'] as TimeOfDay;
                      final t2 = b['timeValue'] as TimeOfDay;
                      return (t1.hour * 60 + t1.minute) -
                          (t2.hour * 60 + t2.minute);
                    });

                    return ListView.builder(
                      itemCount: todayMedicines.length,
                      itemBuilder: (context, index) {
                        final med = todayMedicines[index];
                        return _MedicineRow(
                          name: med['name'],
                          dose: med['dose'],
                          time: med['timeLabel'],
                          status: med['status'],
                          isTaken: med['isTaken'],
                          onMarkTaken: () => _markAsTaken(
                            med['docId'],
                            med['timeKey'],
                            todayDate,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 יום נוכחי
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

  /// 🔹 המרת זמן
  TimeOfDay? _parseTime(String timeKey) {
    switch (timeKey) {
      case 'morning':
        return const TimeOfDay(hour: 5, minute: 0); // טווח 5:00-11:59
      case 'noon':
        return const TimeOfDay(hour: 12, minute: 0); // טווח 12:00-16:59
      case 'evening':
        return const TimeOfDay(hour: 17, minute: 0); // טווח 17:00-18:59
      case 'night':
        return const TimeOfDay(hour: 19, minute: 0); // טווח 19:00-4:59
      default:
        final parts = timeKey.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            return TimeOfDay(hour: h, minute: m);
          }
        }
        return null;
    }
  }

  /// 🔹 תצוגת זמן
  String _getTimeDisplay(String timeKey) {
    switch (timeKey) {
      case 'morning':
        return context.loc.t('morning');
      case 'noon':
        return context.loc.t('noon');
      case 'evening':
        return context.loc.t('evening');
      case 'night':
        return context.loc.t('night');
      default:
        return timeKey;
    }
  }

  /// 🔹 סטטוס תרופה
  String _getStatus(String timeKey, TimeOfDay now) {
    TimeOfDay start, end;
    bool isNight = false;

    switch (timeKey) {
      case 'morning':
        start = const TimeOfDay(hour: 5, minute: 0);
        end = const TimeOfDay(hour: 11, minute: 59);
        break;
      case 'noon':
        start = const TimeOfDay(hour: 12, minute: 0);
        end = const TimeOfDay(hour: 16, minute: 59);
        break;
      case 'evening':
        start = const TimeOfDay(hour: 17, minute: 0);
        end = const TimeOfDay(hour: 18, minute: 59);
        break;
      case 'night':
        start = const TimeOfDay(hour: 19, minute: 0);
        end = const TimeOfDay(hour: 4, minute: 59);
        isNight = true;
        break;
      default:
        // For custom times like HH:MM, use point logic
        final medTime = _parseTime(timeKey);
        if (medTime != null) {
          final medMin = medTime.hour * 60 + medTime.minute;
          final nowMin = now.hour * 60 + now.minute;
          if (medMin < nowMin) return 'late';
          if (medMin <= nowMin + 30) return 'due';
          return 'upcoming';
        }
        return 'upcoming';
    }

    final nowMin = now.hour * 60 + now.minute;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;

    if (isNight) {
      // Night spans midnight: 21:00 to 4:59 next day
      if (nowMin < startMin) return 'upcoming';
      if (nowMin >= startMin || nowMin <= endMin) return 'due';
      return 'late';
    } else {
      if (nowMin < startMin) return 'upcoming';
      if (nowMin <= endMin) return 'due';
      return 'late';
    }
  }
}

/// ⭐ כרטיס נקודות
class _PointsCard extends StatelessWidget {
  final int points;
  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC83D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.paid, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            '${context.loc.t('points')}: $points',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// 💊 שורת תרופה
class _MedicineRow extends StatelessWidget {
  final String name;
  final String dose;
  final String time;
  final String status;
  final bool isTaken;
  final VoidCallback onMarkTaken;

  const _MedicineRow({
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
    required this.isTaken,
    required this.onMarkTaken,
  });

  Color get statusColor {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'due':
        return Colors.orange;
      case 'late':
        return Colors.red;
      case 'upcoming':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String statusText(BuildContext context) {
    switch (status) {
      case 'taken':
        return context.loc.t('statusTaken');
      case 'due':
        return context.loc.t('statusDue');
      case 'late':
        return context.loc.t('statusLate');
      case 'upcoming':
        return context.loc.t('statusUpcoming');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.medication, color: statusColor),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dose, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText(context),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (!isTaken && status == 'due') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: onMarkTaken,
                        iconSize: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }
}
