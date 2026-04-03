import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/incident_model.dart';

class GuestSuccessScreen extends StatefulWidget {
  final String incidentId;
  const GuestSuccessScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<GuestSuccessScreen> createState() => _GuestSuccessScreenState();
}

class _GuestSuccessScreenState extends State<GuestSuccessScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _controller;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: StreamBuilder<IncidentModel>(
              stream: _firestoreService.streamIncidentById(widget.incidentId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final incident = snapshot.data!;
                final bool isDismissed = incident.status == 'dismissed';
                final bool showEvac = incident.severity != null && incident.severity! >= 6;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80, height: 80,
                      child: AnimatedBuilder(
                         animation: _checkAnimation,
                         builder: (context, child) {
                           return CustomPaint(
                             painter: CheckmarkPainter(
                               progress: _checkAnimation.value,
                               color: isDismissed ? AppTheme.cfMuted : AppTheme.cfGreen,
                             ),
                           );
                         },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isDismissed ? "Report logged" : "Report received",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.cfNavy),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDismissed
                          ? "No threat detected by AI."
                          : "Responders have been notified and are on their way.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.cfMuted),
                    ),
                    const SizedBox(height: 32),
                    
                    // SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDismissed ? const Color(0xFFF5F5F5) : const Color(0xFFF0FDF7),
                        border: Border.all(color: isDismissed ? AppTheme.cfBorder : const Color(0xFF6EE7B7)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("YOUR REPORT", style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, 
                            color: isDismissed ? AppTheme.cfMuted : const Color(0xFF085041), 
                            letterSpacing: 0.5)
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow("Type", incident.type.toUpperCase()),
                          _buildSummaryRow("Zone", incident.location.zoneName ?? 'Unknown'),
                          _buildSummaryRow("AI severity", "${incident.severity ?? 0}/10 — ${incident.confidence ?? '-'}"),
                          _buildSummaryRow("Responders", isDismissed ? "Stand down" : "Notified"),
                          _buildSummaryRow("Reference", widget.incidentId.substring(0, 8), monospace: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (showEvac && !isDismissed)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFF854F0B), size: 16),
                                SizedBox(width: 8),
                                Text("Evacuation guidance", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF854F0B))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Proceed to the nearest marked exit. Do not use lifts. Assembly point: Main Car Park — follow staff instructions.",
                              style: TextStyle(fontSize: 12, color: Color(0xFF854F0B), height: 1.7),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/report'),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppTheme.cfNavy,
                        ),
                        child: const Text("Submit another report"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/report'),
                      child: const Text("Back to home", style: TextStyle(color: AppTheme.cfNavy)),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
          Text(value, style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: AppTheme.cfNavy,
            fontFamily: monospace ? 'Courier' : null,
          )),
        ],
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Circle
    path.addArc(Rect.fromLTWH(0, 0, size.width, size.height), -pi / 2, 2 * pi * progress);
    
    // Checkmark inside
    if (progress > 0.5) {
      final checkProgress = (progress - 0.5) * 2;
      final checkPath = Path();
      checkPath.moveTo(size.width * 0.25, size.height * 0.5);
      
      final p1 = Offset(size.width * 0.45, size.height * 0.7);
      if (checkProgress < 0.5) {
        final currentProgress = checkProgress * 2;
        checkPath.lineTo(
          size.width * 0.25 + (p1.dx - size.width * 0.25) * currentProgress,
          size.height * 0.5 + (p1.dy - size.height * 0.5) * currentProgress,
        );
      } else {
        checkPath.lineTo(p1.dx, p1.dy);
        final p2 = Offset(size.width * 0.75, size.height * 0.35);
        final currentProgress = (checkProgress - 0.5) * 2;
        checkPath.lineTo(
          p1.dx + (p2.dx - p1.dx) * currentProgress,
          p1.dy + (p2.dy - p1.dy) * currentProgress,
        );
      }
      canvas.drawPath(checkPath, paint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
