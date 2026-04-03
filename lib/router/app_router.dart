import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/guest/guest_report_screen.dart';
import '../screens/guest/guest_uploading_screen.dart';
import '../screens/guest/guest_verifying_screen.dart';
import '../screens/guest/guest_success_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/staff_incident_detail_screen.dart';
import '../screens/manager/manager_command_screen.dart';
import '../screens/manager/manager_resources_screen.dart';
import '../screens/manager/manager_qr_screen.dart';
import '../screens/manager/manager_analytics_screen.dart';
import '../screens/manager/manager_staff_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.role;
      final isLoggedIn = role != null && role != 'guest';
      final path = state.uri.path;

      // Guest routes always accessible
      if (path == '/report' || path == '/uploading' || path == '/verifying' || path == '/success') {
        return null; // no redirect
      }

      // Allow splash to do its thing
      if (path == '/') return null;

      // If trying to access staff/manager without login -> login
      final requiresAuth = path.startsWith('/staff') || path.startsWith('/manager');
      if (requiresAuth && !isLoggedIn) {
        return '/login';
      }

      // Role-based restrictions if logged in
      if (isLoggedIn) {
        if (path.startsWith('/staff') && role == 'manager') {
          return '/manager';
        }
        if (path.startsWith('/manager') && role == 'staff') {
          return '/staff';
        }
        // If logged in and on login page, send to their portal
        if (path == '/login') {
          return role == 'manager' ? '/manager' : '/staff';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => GuestReportScreen(
          zoneId: state.uri.queryParameters['zone'],
        ),
      ),
      GoRoute(
        path: '/uploading',
        builder: (context, state) => GuestUploadingScreen(
          incidentId: state.uri.queryParameters['incidentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verifying',
        builder: (context, state) => GuestVerifyingScreen(
          incidentId: state.uri.queryParameters['incidentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) => GuestSuccessScreen(
          incidentId: state.uri.queryParameters['incidentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/incident/:id',
        builder: (context, state) => StaffIncidentDetailScreen(
          incidentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerCommandScreen(),
      ),
      GoRoute(
        path: '/manager/resources',
        builder: (context, state) => const ManagerResourcesScreen(),
      ),
      GoRoute(
        path: '/manager/qr',
        builder: (context, state) => const ManagerQRScreen(),
      ),
      GoRoute(
        path: '/manager/analytics',
        builder: (context, state) => const ManagerAnalyticsScreen(),
      ),
      GoRoute(
        path: '/manager/staff',
        builder: (context, state) => const ManagerStaffScreen(),
      ),
    ],
  );
}
