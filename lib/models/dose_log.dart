import 'package:cloud_firestore/cloud_firestore.dart';

enum DoseStatus { taken, missed }

class DoseLog {
  final String id;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final DoseStatus status;
  final String? medName;

  const DoseLog({
    required this.id,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.medName,
  });

  factory DoseLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusRaw = data['status'] as String? ?? 'missed';
    return DoseLog(
      id: doc.id,
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      takenAt: (data['takenAt'] as Timestamp?)?.toDate(),
      status: statusRaw == 'taken' ? DoseStatus.taken : DoseStatus.missed,
      medName: data['medName'] as String?,
    );
  }
}
