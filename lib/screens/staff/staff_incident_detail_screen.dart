import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/incident_model.dart';
import '../../models/resource_model.dart';

class StaffIncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  const StaffIncidentDetailScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<StaffIncidentDetailScreen> createState() => _StaffIncidentDetailScreenState();
}

class _StaffIncidentDetailScreenState extends State<StaffIncidentDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAssignBottomSheet(BuildContext context, IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StreamBuilder<List<ResourceModel>>(
          stream: _firestoreService.streamResources(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            
            final resources = snapshot.data!.where((r) => r.available).toList();

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Assign Responder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                  const SizedBox(height: 16),
                  if (resources.isEmpty)
                    const Text("No available responders right now.", style: TextStyle(color: AppTheme.cfMuted)),
                  ...resources.map((res) {
                    return ListTile(
                      title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("Zone: ${res.zone}", style: const TextStyle(fontSize: 11)),
                      trailing: const Text("Assign", style: TextStyle(color: AppTheme.cfGreen, fontWeight: FontWeight.w600)),
                      onTap: () async {
                         Navigator.pop(ctx);
                         // Manual assigning logic here without tools plan
                         await _firestoreService.confirmDispatch(
                            'direct_dispatch', res.id, incident.id // mock direct dispatch id
                         );
                      },
                    );
                  }).toList()
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _markResolved(IncidentModel incident) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark as resolved?"),
        content: const Text("This will close the incident and free assigned resources."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.resolveIncident(incident.id, incident.assignedTo);
              if (mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfGreen),
            child: const Text("Confirm"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cfSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: StreamBuilder<IncidentModel>(
          stream: _firestoreService.streamIncidentById(widget.incidentId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Text(snapshot.data!.type.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white));
          }
        ),
      ),
      body: StreamBuilder<IncidentModel>(
        stream: _firestoreService.streamIncidentById(widget.incidentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final incident = snapshot.data!;

          return Center(
            child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 700),
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(20),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // PHOTO
                     Container(
                       height: 180,
                       width: double.infinity,
                       decoration: BoxDecoration(
                         color: const Color(0xFFF0F0F0),
                         borderRadius: BorderRadius.circular(12),
                         image: incident.photoURL != null 
                            ? DecorationImage(image: NetworkImage(incident.photoURL!), fit: BoxFit.cover)
                            : null,
                       ),
                       child: incident.photoURL == null 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt_outlined, color: AppTheme.cfDim, size: 32),
                                SizedBox(height: 8),
                                Text("No photo provided", style: TextStyle(color: AppTheme.cfMuted)),
                              ],
                            )
                          : null,
                     ),
                     const SizedBox(height: 8),
                     Text("Reported ${timeago.format(incident.timestamp)} from ${incident.location.zoneName ?? 'Unknown location'}", 
                          style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                     
                     const SizedBox(height: 24),
                     // AI RESULT
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: const Color(0xFFF8F7FF),
                         border: Border.all(color: const Color(0xFFAFA9EC)),
                         borderRadius: BorderRadius.circular(14),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: const [
                               Icon(Icons.psychology, color: Color(0xFF3C3489), size: 16),
                               SizedBox(width: 8),
                               Text("Gemini AI result", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3C3489))),
                             ],
                           ),
                           const SizedBox(height: 16),
                           _buildDetailRow("Type", Text(incident.aiType?.toUpperCase() ?? 'None', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cfNavy))),
                           _buildDetailRow("Severity", TweenAnimationBuilder<double>(
                             tween: Tween(begin: 0, end: (incident.severity ?? 0) / 10.0),
                             duration: const Duration(milliseconds: 600),
                             builder: (context, val, _) {
                               return Row(
                                 children: [
                                   SizedBox(width: 100, child: LinearProgressIndicator(value: val, backgroundColor: Colors.white, color: AppTheme.cfRed, minHeight: 6)),
                                   const SizedBox(width: 8),
                                   Text("${incident.severity ?? 0}/10", style: const TextStyle(color: AppTheme.cfRed, fontWeight: FontWeight.w600)),
                                 ],
                               );
                             }
                           )),
                           _buildDetailRow("Confidence", Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(color: const Color(0xFF534AB7).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                             child: Text(incident.confidence ?? 'null', style: const TextStyle(fontSize: 10, color: Color(0xFF534AB7))),
                           )),
                           const SizedBox(height: 12),
                           Text(incident.aiDescription ?? 'Waiting for AI processing...', style: const TextStyle(fontSize: 12, color: Color(0xFF534AB7), fontStyle: FontStyle.italic, height: 1.6)),
                         ],
                       ),
                     ),

                     const SizedBox(height: 16),
                     // DETAILS CARD
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         border: Border.all(color: AppTheme.cfBorder),
                         borderRadius: BorderRadius.circular(14),
                       ),
                       child: Column(
                         children: [
                           _buildDetailTable("Reported by", "Guest (anonymous)"),
                           _buildDetailTable("Zone", incident.location.zoneName ?? '-'),
                           _buildDetailTable("Floor", incident.location.floor ?? '-'),
                           _buildDetailTable("Reported at", DateFormat('HH:mm - dd MMM yyyy').format(incident.timestamp)),
                           _buildDetailTable("Status", incident.status),
                           _buildDetailTable("Assigned to", incident.assignedTo ?? "Unassigned", valueColor: incident.assignedTo != null ? AppTheme.cfGreen : AppTheme.cfMuted),
                           _buildDetailTable("Reference", incident.id.substring(0, 8), monospace: true),
                         ],
                       ),
                     ),

                     const SizedBox(height: 24),
                     // ACTIONS
                     if (incident.status == 'verified' && incident.assignedTo == null)
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                             onPressed: () => _showAssignBottomSheet(context, incident),
                             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfNavy),
                             child: const Text("Acknowledge & assign"),
                          ),
                        ),
                     
                     if (incident.status != 'resolved') ...[
                       const SizedBox(height: 8),
                       SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton(
                             onPressed: () => _markResolved(incident),
                             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfGreen),
                             child: const Text("Mark as resolved"),
                          ),
                       ),
                     ],

                     const SizedBox(height: 8),
                     SizedBox(
                        width: double.infinity, height: 48,
                        child: OutlinedButton(
                           onPressed: () {},
                           child: const Text("Share location QR"),
                        ),
                     ),
                   ],
                 ),
               ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.cfMuted)),
          value,
        ],
      ),
    );
  }

  Widget _buildDetailTable(String label, String value, {Color valueColor = AppTheme.cfNavy, bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
          Text(value, style: TextStyle(
             fontSize: 13, 
             fontWeight: FontWeight.w500, 
             color: valueColor,
             fontFamily: monospace ? 'Courier' : null,
          )),
        ],
      ),
    );
  }
}
