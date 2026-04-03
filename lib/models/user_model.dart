import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role; // staff | manager
  final String name;
  final String? fcmToken;
  final String venue;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    this.fcmToken,
    required this.venue,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      role: data['role'] ?? 'staff',
      name: data['name'] ?? '',
      fcmToken: data['fcmToken'],
      venue: data['venue'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'venue': venue,
    };
  }
}
