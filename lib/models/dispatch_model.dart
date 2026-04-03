import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchModel {
  final String id;
  final String incidentId;
  final String resourceId;
  final String resourceName;
  final String resourceType;
  final String fromZone;
  final String toZone;
  final int estimatedMinutes;
  final bool confirmed;
  final DateTime createdAt;

  DispatchModel({
    required this.id,
    required this.incidentId,
    required this.resourceId,
    required this.resourceName,
    required this.resourceType,
    required this.fromZone,
    required this.toZone,
    required this.estimatedMinutes,
    required this.confirmed,
    required this.createdAt,
  });

  factory DispatchModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DispatchModel(
      id: doc.id,
      incidentId: data['incidentId'] ?? '',
      resourceId: data['resourceId'] ?? '',
      resourceName: data['resourceName'] ?? '',
      resourceType: data['resourceType'] ?? '',
      fromZone: data['fromZone'] ?? '',
      toZone: data['toZone'] ?? '',
      estimatedMinutes: data['estimatedMinutes'] ?? 0,
      confirmed: data['confirmed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'resourceType': resourceType,
      'fromZone': fromZone,
      'toZone': toZone,
      'estimatedMinutes': estimatedMinutes,
      'confirmed': confirmed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
