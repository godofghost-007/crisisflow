import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../theme/app_theme.dart';
import '../../../models/incident_model.dart';
import 'package:go_router/go_router.dart';

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;

  const IncidentCard({Key? key, required this.incident}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color severityColor = AppTheme.cfGreen;
    if (incident.severity != null) {
      if (incident.severity! >= 8) severityColor = AppTheme.cfRed;
      else if (incident.severity! >= 4) severityColor = AppTheme.cfAmber;
    }

    String aiStatusText = "Pending";
    Color aiStatusBg = const Color(0xFFFAEEDA);
    Color aiStatusTextCol = const Color(0xFF633806);

    if (incident.status == 'verified') {
      aiStatusText = "AI Verified";
      aiStatusBg = const Color(0xFFE1F5EE);
      aiStatusTextCol = const Color(0xFF085041);
    } else if (incident.status == 'dismissed') {
      aiStatusText = "Dismissed";
      aiStatusBg = AppTheme.cfSurface;
      aiStatusTextCol = AppTheme.cfMuted;
    }

    return InkWell(
      onTap: () => context.push('/staff/incident/${incident.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cfBorder, width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SEVERITY STRIPE
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(incident.type.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(4)),
                                child: Text("${incident.severity ?? '-'}/10", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: aiStatusBg, borderRadius: BorderRadius.circular(4)),
                            child: Text(aiStatusText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: aiStatusTextCol)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // MIDDLE ROW
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.cfMuted),
                          const SizedBox(width: 4),
                          Expanded(child: Text(incident.location.zoneName ?? 'Unknown area', style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // BOTTOM ROW
                      Row(
                        children: [
                          Text(timeago.format(incident.timestamp), style: const TextStyle(fontSize: 10, color: AppTheme.cfDim)),
                          if (incident.assignedTo != null) ...[
                            const SizedBox(width: 4),
                            const Text("· Resource assigned", style: TextStyle(fontSize: 10, color: AppTheme.cfGreen, fontWeight: FontWeight.w500)),
                          ]
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: Icon(Icons.chevron_right, size: 16, color: AppTheme.cfDim)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
