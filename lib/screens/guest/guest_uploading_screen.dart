import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class GuestUploadingScreen extends StatefulWidget {
  final String incidentId;

  const GuestUploadingScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<GuestUploadingScreen> createState() => _GuestUploadingScreenState();
}

class _GuestUploadingScreenState extends State<GuestUploadingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Auto-navigate after 3 seconds fallback
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/verifying?incidentId=${widget.incidentId}');
    });

    _subscription = _firestoreService.streamIncidentById(widget.incidentId).listen((incident) {
      if (!mounted) return;
      if (incident.status == 'verified') {
        _timer?.cancel();
        context.go('/verifying?incidentId=${widget.incidentId}');
      } else if (incident.status == 'dismissed') {
        _timer?.cancel();
        context.go('/success?incidentId=${widget.incidentId}&msg=dismissed');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 60, color: AppTheme.cfAmber),
              const SizedBox(height: 16),
              const Text("Sending your report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
              const SizedBox(height: 8),
              const Text("Your report is being processed securely", style: TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: AppTheme.cfSurface,
                      color: AppTheme.cfRed,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              _buildStep(1, "Location captured", true),
              _buildStep(2, "Photo uploading...", false, isActive: true),
              _buildStep(3, "AI verification", false),
              _buildStep(4, "Alerting responders", false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text, bool isComplete, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? AppTheme.cfGreen : (isActive ? AppTheme.cfSurface : Colors.transparent),
              border: Border.all(color: isComplete ? AppTheme.cfGreen : (isActive ? AppTheme.cfRed : AppTheme.cfBorder)),
            ),
            child: Center(
              child: isComplete 
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cfRed, shape: BoxShape.circle)) : Text(num.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.cfMuted))),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(
            fontSize: 14, 
            fontWeight: isActive || isComplete ? FontWeight.w500 : FontWeight.w400,
            color: isComplete ? AppTheme.cfNavy : (isActive ? AppTheme.cfNavy : AppTheme.cfMuted),
          )),
        ],
      ),
    );
  }
}
