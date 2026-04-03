import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';
import '../models/resource_model.dart';
import '../models/dispatch_model.dart';
import '../models/zone_model.dart';
import '../models/staff_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // MOCK DATA for Prototype
  final List<String> _mockResourceTypes = ['fire_team', 'medical_kit', 'medic', 'security_guard'];
  final List<StaffModel> _mockStaff = [];


  final List<IncidentModel> _mockIncidents = [
    IncidentModel(
      id: "inc-101",
      type: "fire",
      status: "verified",
      location: LocationInfo(zoneId: "zone_lobby", zoneName: "Lobby — Level 1", floor: "Level 1"),
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      aiType: "fire",
      severity: 8,
      confidence: "High",
      aiDescription: "Detected visible flames and smoke near the main entrance.",
    ),
    IncidentModel(
      id: "inc-102",
      type: "medical",
      status: "pending",
      location: LocationInfo(zoneId: "zone_pool", zoneName: "Pool Deck", floor: "Level 3"),
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final List<ResourceModel> _mockResources = [
    ResourceModel(id: "res-1", name: "Fire Team Alpha", type: "fire_team", zone: "Lobby", available: true, lastUpdated: DateTime.now()),
    ResourceModel(id: "res-2", name: "Medic Unit 1", type: "medic", zone: "Pool Deck", available: false, lastUpdated: DateTime.now()),
  ];

  final List<ZoneModel> _mockZones = [
    ZoneModel(id: "zone_lobby", name: "Lobby — Level 1", floor: "Level 1", section: "Main", qrData: "https://crisisflow.app/report?zone=zone_lobby", createdAt: DateTime.now(), createdBy: "user"),
    ZoneModel(id: "zone_pool", name: "Pool Deck", floor: "Level 3", section: "Outdoor", qrData: "https://crisisflow.app/report?zone=zone_pool", createdAt: DateTime.now(), createdBy: "user"),
  ];

  final List<DispatchModel> _mockDispatch = [
    DispatchModel(id: "disp-1", incidentId: "inc-101", resourceId: "res-1", resourceName: "Fire Team Alpha", resourceType: "fire_team", fromZone: "HQ", toZone: "Lobby", estimatedMinutes: 2, createdAt: DateTime.now(), confirmed: false),
    DispatchModel(id: "disp-2", incidentId: "inc-102", resourceId: "res-2", resourceName: "Medic Unit 1", resourceType: "medic", fromZone: "Level 1", toZone: "Pool Deck", estimatedMinutes: 4, createdAt: DateTime.now(), confirmed: false),
  ];

  String? _venueMapUrl;

  // -- Incidents --
  Future<String> createIncident(IncidentModel incident) async {
    _mockIncidents.add(incident);
    return incident.id;
  }

  Stream<List<IncidentModel>> streamActiveIncidents() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockIncidents.where((i) => i.status != 'resolved' && i.status != 'dismissed').toList());
  }

  Stream<List<IncidentModel>> streamAllIncidents() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockIncidents.toList());
  }

  Stream<IncidentModel> streamIncidentById(String id) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      try {
        final found = _mockIncidents.firstWhere((element) => element.id == id);
        if (found.status == 'pending' && DateTime.now().difference(found.timestamp).inSeconds > 3) {
           final updated = IncidentModel(
              id: found.id, type: found.type, status: 'verified', location: found.location, photoURL: found.photoURL,
              timestamp: found.timestamp, aiType: found.type, severity: 7, confidence: 'High', aiDescription: 'AI detected anomaly.'
           );
           _mockIncidents[_mockIncidents.indexOf(found)] = updated;
           return updated;
        }
        return found;
      } catch(e) {
        return _mockIncidents.first;
      }
    });
  }

  Future<void> updateIncidentStatus(String id, String status) async {}

  Future<void> resolveIncident(String id, String? resourceId) async {
      try {
        final idx = _mockIncidents.indexWhere((e) => e.id == id);
        if (idx != -1) {
           final inc = _mockIncidents[idx];
           _mockIncidents[idx] = IncidentModel(
             id: inc.id, type: inc.type, status: 'resolved', location: inc.location, timestamp: inc.timestamp,
             resolvedAt: DateTime.now()
           );
        }
      } catch(_) {}
  }

  // -- Resources --
  Stream<List<ResourceModel>> streamResources() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockResources.toList());
  }

  Future<void> updateResourceAvailability(String id, bool available) async {}

  // -- Dispatch --
  Stream<List<DispatchModel>> streamDispatchPlans() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockDispatch.toList());
  }

  Future<void> confirmDispatch(String dispatchId, String resourceId, String incidentId) async {
    try {
        _mockDispatch.removeWhere((d) => d.id == dispatchId);
        final idx = _mockIncidents.indexWhere((e) => e.id == incidentId);
        if (idx != -1) {
           final inc = _mockIncidents[idx];
           _mockIncidents[idx] = IncidentModel(
             id: inc.id, type: inc.type, status: inc.status, location: inc.location, timestamp: inc.timestamp,
             aiType: inc.aiType, severity: inc.severity, confidence: inc.confidence, aiDescription: inc.aiDescription,
             assignedTo: resourceId
           );
        }
    } catch(_) {}
  }

  // -- Zones & Map --
  Stream<List<ZoneModel>> streamZones() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockZones.toList());
  }

  Future<String> createZone(ZoneModel zone) async {
    _mockZones.add(zone);
    return zone.id;
  }

  Future<void> deleteZone(String zoneId) async {
    _mockZones.removeWhere((z) => z.id == zoneId);
  }

  Stream<String?> streamVenueMapUrl() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _venueMapUrl);
  }

  Future<void> updateVenueMapUrl(String url) async {
    _venueMapUrl = url;
  }

  Stream<List<String>> streamResourceTypes() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockResourceTypes.toList());
  }

  Future<void> addResourceType(String type) async {
    if (!_mockResourceTypes.contains(type)) {
      _mockResourceTypes.add(type);
    }
  }

  Future<void> removeResourceType(String type) async {
    _mockResourceTypes.remove(type);
  }

  // -- Staff Access --
  Stream<List<StaffModel>> streamStaff() {
    return Stream.periodic(const Duration(seconds: 1), (_) => _mockStaff.toList());
  }

  Future<void> addStaff(StaffModel staff) async {
    _mockStaff.add(staff);
  }

  Future<void> removeStaff(String id) async {
    _mockStaff.removeWhere((s) => s.id == id);
  }

  bool validateStaffAccessKey(String key) {
    // For prototype purposes, let's also allow a generic "staff" fallback if they haven't explicitly created one, but strictly checking the list if they have.
    if (key == 'STAFF123') return true; 
    return _mockStaff.any((s) => s.accessKey == key);
  }

  // -- Users --
  Future<String> getUserRole(String uid) async {
    return 'staff'; // mocked in AuthProvider anyway
  }

  Future<void> updateFCMToken(String uid, String token) async {}
}
