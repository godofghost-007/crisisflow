import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  String? _role;

  User? get user => _user;
  String? get role => _role;

  AuthProvider() {
    // Mock initial state: logged out
    _user = null;
    _role = null;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    // Mock anonymous login
    await Future.delayed(const Duration(milliseconds: 500));
    _role = 'guest';
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    // MANAGER LOGIN MOCK
    await Future.delayed(const Duration(milliseconds: 800));
    if (email.startsWith('manager')) {
      _role = 'manager';
      notifyListeners();
    } else {
      throw Exception('Invalid manager credentials');
    }
  }

  Future<void> signInWithStaffId(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final isValid = _firestoreService.validateStaffAccessKey(staffId);
    if (isValid) {
      _role = 'staff';
      notifyListeners();
    } else {
      throw Exception('Invalid Staff Access ID');
    }
  }

  Future<void> signOut() async {
    _role = null;
    notifyListeners();
  }
}

