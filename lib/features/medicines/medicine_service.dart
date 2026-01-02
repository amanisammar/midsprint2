import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineService {
  static Future<void> addMedicine({
    required String name,
    required String dosage,
    required List<String> times,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .add({
          'name': name,
          'dose': dosage,
          'times': times,
          'notes': notes,
          'createdAt': Timestamp.now(),
        });
  }
}
