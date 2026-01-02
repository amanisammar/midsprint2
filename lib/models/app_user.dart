import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int points;
  final int streakDays;
  final bool shareWithFamily;
  final String? timezone;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.points = 0,
    this.streakDays = 0,
    this.shareWithFamily = false,
    this.timezone,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      shareWithFamily: data['shareWithFamily'] as bool? ?? false,
      timezone: data['timezone'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'streakDays': streakDays,
      'shareWithFamily': shareWithFamily,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get level => (points ~/ 200) + 1;

  double get levelProgress => (points % 200) / 200.0;

  int get nextLevelPoints => 200 - (points % 200);
}
