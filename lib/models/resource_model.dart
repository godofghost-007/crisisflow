import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String name; // "Fire Team Alpha"
  final String type; // fire_team | medical_kit | medic | security_guard
  final String zone; // current zone name
  final bool available;
  final DateTime lastUpdated;

  ResourceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.zone,
    required this.available,
    required this.lastUpdated,
  });

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      zone: data['zone'] ?? '',
      available: data['available'] ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'zone': zone,
      'available': available,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
