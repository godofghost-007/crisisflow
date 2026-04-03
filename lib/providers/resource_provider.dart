import 'package:flutter/material.dart';
import '../models/resource_model.dart';
import '../services/firestore_service.dart';

class ResourceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ResourceModel> _resources = [];
  List<ResourceModel> get resources => _resources;
  
  int get availableCount => _resources.where((r) => r.available).length;
  int get deployedCount => _resources.where((r) => !r.available).length;

  ResourceProvider() {
    _firestoreService.streamResources().listen((resourcesList) {
      _resources = resourcesList;
      notifyListeners();
    });
  }
}
