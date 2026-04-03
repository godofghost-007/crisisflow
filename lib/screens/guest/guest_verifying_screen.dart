import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/incident_model.dart';

class GuestVerifyingScreen extends StatefulWidget {
  final String incidentId;

  const GuestVerifyingScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<GuestVerifyingScreen> createState() => _GuestVerifyingScreenState();
}

class _GuestVerifyingScreenState extends State<GuestVerifyingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Auto-navigate to success after 5 seconds
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) context.go('/success?incidentId=${widget.incidentId}');
    });

    _subscription = _firestoreService.streamIncidentById(widget.incidentId).listen((incident) {
      if (!mounted) return;
      if (incident.status == 'verified') {
        _timer?.cancel();
        context.go('/success?incidentId=${widget.incidentId}');
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
              const Icon(Icons.psychology, size: 60, color: Color(0xFF534AB7)),
              const SizedBox(height: 16),
              const Text("AI is verifying", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
              const SizedBox(height: 8),
              const Text("Gemini Vision is analysing your photo", style: TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
              const SizedBox(height: 40),
              
              StreamBuilder<IncidentModel>(
                stream: _firestoreService.streamIncidentById(widget.incidentId),
                builder: (context, snapshot) {
                  final incident = snapshot.data;
                  if (incident?.aiType != null) {
                    return _buildAICardReady(incident!);
                  }
                  return _buildAICardLoading();
                },
              ),
              
              const SizedBox(height: 40),
              _buildStep(1, "Location captured", true),
              _buildStep(2, "Photo uploading...", true),
              _buildStep(3, "AI verification", false, isActive: true),
              _buildStep(4, "Alerting responders", false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAICardReady(IncidentModel incident) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        border: Border.all(color: const Color(0xFFAFA9EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GEMINI VISION — VERIFIED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF534AB7), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildRow("Type detected", Text(incident.aiType?.toUpperCase() ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cfNavy))),
          const SizedBox(height: 8),
          _buildRow("Severity", Row(
            children: [
              Text("${incident.severity ?? 0}/10", style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cfRed)),
            ],
          )),
          const SizedBox(height: 8),
          _buildRow("Confidence", Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF534AB7).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(incident.confidence ?? 'Medium', style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7), fontWeight: FontWeight.w500)),
          )),
          const SizedBox(height: 12),
          Text(incident.aiDescription ?? '', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF534AB7))),
        ],
      ),
    );
  }

  Widget _buildAICardLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEBEBEB),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cfBorder),
        ),
      ),
    );
  }

  Widget _buildRow(String label, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
        child,
      ],
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
              border: Border.all(color: isComplete ? AppTheme.cfGreen : (isActive ? const Color(0xFF534AB7) : AppTheme.cfBorder)),
            ),
            child: Center(
              child: isComplete 
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF534AB7), shape: BoxShape.circle)) : Text(num.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.cfMuted))),
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
