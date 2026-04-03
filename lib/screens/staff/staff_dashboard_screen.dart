import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/zone_model.dart';
import '../../widgets/incident/incident_card.dart';
import '../../widgets/venue/zone_map_widget.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _triggerEvacuation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Trigger Evacuation?"),
        content: const Text("This will send an emergency alert to all venue staff and active guest screens."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // Write to /alerts
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evacuation triggered")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfRed),
            child: const Text("Confirm Evacuation"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.cfSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cfRed, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text("CrisisFlow", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 8),
            Text("·", style: TextStyle(color: Colors.white.withOpacity(0.4))),
            const SizedBox(width: 8),
            Text("Security Console", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
          ],
        ),
        actions: [
          Center(
            child: Consumer<IncidentProvider>(builder: (context, prov, child) {
              if (prov.activeIncidentsCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.cfRed, borderRadius: BorderRadius.circular(12)),
                  child: Text("${prov.activeIncidentsCount} Active", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                );
              }
              return const SizedBox();
            }),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: Colors.white, size: 20),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.cfGreen,
            child: Text(authProv.user?.displayName?.substring(0, 1) ?? "S", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Center(child: Text("Staff", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)))),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              authProv.signOut();
              context.go('/login');
            },
            child: Text("Sign out", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANEL: INCIDENT FEED
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text("LIVE INCIDENT FEED", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          Consumer<IncidentProvider>(
                            builder: (context, prov, child) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.cfBorder, borderRadius: BorderRadius.circular(4)),
                              child: Text(prov.activeIncidentsCount.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: const [
                          Text("Sort by: ", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                          Text("Severity", style: TextStyle(fontSize: 11, color: AppTheme.cfNavy, fontWeight: FontWeight.w500)),
                          Icon(Icons.keyboard_arrow_down, size: 14),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<IncidentProvider>(
                      builder: (context, prov, child) {
                        if (prov.activeIncidents.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_outlined, size: 48, color: AppTheme.cfGreen),
                                const SizedBox(height: 16),
                                const Text("All clear", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.cfGreen)),
                                const Text("No active incidents", style: TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: prov.activeIncidents.length,
                          itemBuilder: (context, index) {
                            return IncidentCard(incident: prov.activeIncidents[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT PANEL
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: AppTheme.cfBorder, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION A - Venue Zones
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("VENUE ZONES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        StreamBuilder<List<ZoneModel>>(
                          stream: _firestoreService.streamZones(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            return ZoneMapWidget(zones: snapshot.data!);
                          }
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendDot(AppTheme.cfRed, "Critical"),
                            const SizedBox(width: 8),
                            _buildLegendDot(AppTheme.cfAmber, "Active"),
                            const SizedBox(width: 8),
                            _buildLegendDot(AppTheme.cfGreen, "Clear"),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                
                // SECTION B - Quick Actions
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.cfBorder, width: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("QUICK ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _triggerEvacuation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cfRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Trigger venue-wide evacuation alert", textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            if (authProv.role == 'manager') {
                              context.go('/manager');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager access required.')));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.cfBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            foregroundColor: AppTheme.cfNavy,
                          ),
                          child: const Text("View manager command", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: AppTheme.cfMuted)),
      ],
    );
  }
}
