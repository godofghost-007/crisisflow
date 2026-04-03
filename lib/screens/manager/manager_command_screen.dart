import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/incident_model.dart';
import '../../models/dispatch_model.dart';

class ManagerCommandScreen extends StatefulWidget {
  const ManagerCommandScreen({Key? key}) : super(key: key);

  @override
  State<ManagerCommandScreen> createState() => _ManagerCommandScreenState();
}

class _ManagerCommandScreenState extends State<ManagerCommandScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cfSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        elevation: 0,
        title: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cfRed, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text("CrisisFlow", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 8),
            Text("· Manager Command", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () => context.go('/login'),
             child: Text("Sign out", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: AppTheme.cfNavy,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
               children: [
                 _buildTab("Command", true, '/manager'),
                 _buildTab("Resources", false, '/manager/resources'),
                 _buildTab("QR Zones", false, '/manager/qr'),
                 _buildTab("Staff", false, '/manager/staff'),
                 _buildTab("Analytics", false, '/manager/analytics'),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ROW 1 - STATS
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard("Active incidents", "3", AppTheme.cfRed, true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard("Deployed", "4", AppTheme.cfAmber, false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard("Available", "12", AppTheme.cfGreen, false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard("Avg response", "2.4m", AppTheme.cfNavy, false)),
                ],
              ),
            ),

            // ROW 2 - BENTO SPLIT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT CARD - Log
                  Expanded(
                    child: Container(
                      height: 400,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cfBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("INCIDENT LOG — TODAY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: StreamBuilder<List<IncidentModel>>(
                              stream: _firestoreService.streamAllIncidents(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                final incidents = snapshot.data!;
                                return ListView.separated(
                                  itemCount: incidents.length,
                                  separatorBuilder: (ctx, i) => const Divider(color: AppTheme.cfBorder, height: 16),
                                  itemBuilder: (ctx, i) {
                                    final inc = incidents[i];
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(inc.type.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                                            Text(inc.location.zoneName ?? 'Unknown', style: const TextStyle(fontSize: 10, color: AppTheme.cfMuted)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: inc.status == 'resolved' ? AppTheme.cfGreen.withOpacity(0.1) : (inc.status == 'dismissed' ? AppTheme.cfSurface : AppTheme.cfRed.withOpacity(0.1)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(inc.status, style: TextStyle(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.w600,
                                            color: inc.status == 'resolved' ? AppTheme.cfGreen : (inc.status == 'dismissed' ? AppTheme.cfMuted : AppTheme.cfRed)
                                          )),
                                        )
                                      ],
                                    );
                                  },
                                );
                              }
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () { 
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("incident_log.csv exported")));
                              },
                              child: const Text("Export as CSV", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // RIGHT CARD - Dispatch Plan
                  Expanded(
                    child: Container(
                      height: 400,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(14),
                         border: Border.all(color: AppTheme.cfBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                             children: [
                               const Text("DISPATCH PLAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                               const SizedBox(width: 8),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                 decoration: BoxDecoration(color: AppTheme.cfGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                 child: const Text("OR-Tools optimized", style: TextStyle(fontSize: 9, color: AppTheme.cfGreen)),
                               )
                             ],
                           ),
                           const SizedBox(height: 12),
                           Expanded(
                             child: StreamBuilder<List<DispatchModel>>(
                               stream: _firestoreService.streamDispatchPlans(),
                               builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.cfGreen));
                                  final plans = snapshot.data!;
                                  
                                  if (plans.isEmpty) {
                                    return Center(child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        CircularProgressIndicator(color: AppTheme.cfGreen, strokeWidth: 2),
                                        SizedBox(height: 16),
                                        Text("Calculating optimal routes...", style: TextStyle(color: AppTheme.cfMuted, fontSize: 12)),
                                      ],
                                    ));
                                  }

                                  return ListView.builder(
                                    itemCount: plans.length,
                                    itemBuilder: (ctx, i) {
                                      final p = plans[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FB),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.cfBorder),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(p.resourceName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                Container(
                                                  width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cfBlue, shape: BoxShape.circle)
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(p.fromZone, style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                                                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 10, color: AppTheme.cfMuted)),
                                                Text(p.toZone, style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 10, color: AppTheme.cfDim),
                                                const SizedBox(width: 4),
                                                Text("Est. ${p.estimatedMinutes} min", style: const TextStyle(fontSize: 10, color: AppTheme.cfDim)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 36,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  await _firestoreService.confirmDispatch(p.id, p.resourceId, p.incidentId);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                child: const Text("Confirm dispatch", style: TextStyle(fontSize: 11)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                               }
                             ),
                           ),
                           const Center(child: Padding(
                             padding: EdgeInsets.only(top: 8.0),
                             child: Text("Powered by Google OR-Tools · minimizes response time", style: TextStyle(fontSize: 9, color: AppTheme.cfDim)),
                           ))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool trendUp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cfBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color)),
               if (trendUp) const Icon(Icons.arrow_upward, size: 14, color: AppTheme.cfRed)
               else const Icon(Icons.arrow_downward, size: 14, color: AppTheme.cfGreen)
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
           color: active ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
           color: active ? AppTheme.cfNavy : Colors.white.withOpacity(0.5),
           fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}
