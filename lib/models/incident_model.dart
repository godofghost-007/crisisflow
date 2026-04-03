import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String type; // fire | medical | security | other
  final String status; // pending | verified | dismissed | resolved
  final LocationInfo location;
  final String? photoURL;
  final DateTime timestamp;
  final String? aiType;
  final int? severity; // 1-10
  final String? confidence; // low | medium | high
  final String? aiDescription;
  final DateTime? processedAt;
  final DateTime? resolvedAt;
  final String? assignedTo; // resourceId
  final String? note;

  IncidentModel({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
    this.photoURL,
    required this.timestamp,
    this.aiType,
    this.severity,
    this.confidence,
    this.aiDescription,
    this.processedAt,
    this.resolvedAt,
    this.assignedTo,
    this.note,
  });

  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return IncidentModel(
      id: doc.id,
      type: data['type'] ?? 'other',
      status: data['status'] ?? 'pending',
      location: LocationInfo.fromMap(data['location'] ?? {}),
      photoURL: data['photoURL'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aiType: data['aiType'],
      severity: data['severity'],
      confidence: data['confidence'],
      aiDescription: data['aiDescription'],
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      assignedTo: data['assignedTo'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'location': location.toMap(),
      'photoURL': photoURL,
      'timestamp': Timestamp.fromDate(timestamp),
      'aiType': aiType,
      'severity': severity,
      'confidence': confidence,
      'aiDescription': aiDescription,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'assignedTo': assignedTo,
      'note': note,
    };
  }
}

class LocationInfo {
  final String? zoneId;
  final String? zoneName;
  final String? floor;

  LocationInfo({this.zoneId, this.zoneName, this.floor});

  factory LocationInfo.fromMap(Map<dynamic, dynamic> map) {
    return LocationInfo(
      zoneId: map['zoneId'],
      zoneName: map['zoneName'],
      floor: map['floor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (zoneId != null) 'zoneId': zoneId,
      if (zoneName != null) 'zoneName': zoneName,
      if (floor != null) 'floor': floor,
    };
  }
}
