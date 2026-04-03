import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../services/firestore_service.dart';

class IncidentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<IncidentModel> _activeIncidents = [];
  List<IncidentModel> get activeIncidents => _activeIncidents;
  
  int get activeIncidentsCount => _activeIncidents.length;

  IncidentProvider() {
    _firestoreService.streamActiveIncidents().listen((incidents) {
      _activeIncidents = incidents;
      // Sort by severity descending for default view
      _activeIncidents.sort((a, b) => (b.severity ?? 0).compareTo(a.severity ?? 0));
      notifyListeners();
    });
  }
}
