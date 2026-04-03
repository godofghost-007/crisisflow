import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String name; // "Lobby — Level 1, Zone A"
  final String floor; // "Level 1"
  final String section; // "Zone A"
  final String qrData; // deep link URL encoded in QR
  final DateTime createdAt;
  final String createdBy; // manager uid

  ZoneModel({
    required this.id,
    required this.name,
    required this.floor,
    required this.section,
    required this.qrData,
    required this.createdAt,
    required this.createdBy,
  });

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ZoneModel(
      id: doc.id,
      name: data['name'] ?? '',
      floor: data['floor'] ?? '',
      section: data['section'] ?? '',
      qrData: data['qrData'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'floor': floor,
      'section': section,
      'qrData': qrData,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
