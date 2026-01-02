import 'package:cloud_firestore/cloud_firestore.dart';

enum DoseStatus { taken, missed, skipped }

class DoseLog {
  final String id;
  final String medicineId;
  final String medName;
  final String dateKey; // YYYY-MM-DD
  final String timeKey; // HH:MM
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final DoseStatus status;
  final DateTime? createdAt;

  const DoseLog({
    required this.id,
    required this.medicineId,
    required this.medName,
    required this.dateKey,
    required this.timeKey,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.createdAt,
  });

  factory DoseLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final statusRaw = data['status'] as String? ?? 'missed';
    DoseStatus status;
    switch (statusRaw) {
      case 'taken':
        status = DoseStatus.taken;
        break;
      case 'skipped':
        status = DoseStatus.skipped;
        break;
      default:
        status = DoseStatus.missed;
    }
    
    return DoseLog(
      id: doc.id,
      medicineId: data['medicineId'] as String? ?? '',
      medName: data['medName'] as String? ?? '',
      dateKey: data['dateKey'] as String? ?? '',
      timeKey: data['timeKey'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      takenAt: (data['takenAt'] as Timestamp?)?.toDate(),
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medName': medName,
      'dateKey': dateKey,
      'timeKey': timeKey,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'takenAt': takenAt != null ? Timestamp.fromDate(takenAt!) : null,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
