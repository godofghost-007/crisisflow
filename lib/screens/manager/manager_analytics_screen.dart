import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class ManagerAnalyticsScreen extends StatelessWidget {
  const ManagerAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cfSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        elevation: 0,
        title: const Text("Manager · Analytics", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/manager')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
               children: [
                 _buildFilterChip("Today", true),
                 const SizedBox(width: 8),
                 _buildFilterChip("Last 7 days", false),
                 const SizedBox(width: 8),
                 _buildFilterChip("Last 30 days", false),
               ],
            ),
            const SizedBox(height: 16),
            
            // CARD 1
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cfBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOTAL INCIDENTS BY TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                  const SizedBox(height: 16),
                  _buildHorizontalBar("Fire", 4, AppTheme.cfRed, 0.4),
                  _buildHorizontalBar("Medical", 6, AppTheme.cfBlue, 0.6),
                  _buildHorizontalBar("Security", 2, AppTheme.cfAmber, 0.2),
                  _buildHorizontalBar("Other", 1, AppTheme.cfMuted, 0.1),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD 2
                Expanded(
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cfBorder)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("AVG RESPONSE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                         const SizedBox(height: 16),
                         _buildMetricsRow("Fire", "1.8m", AppTheme.cfRed),
                         _buildMetricsRow("Medical", "2.1m", AppTheme.cfNavy),
                         _buildMetricsRow("Security", "3.4m", AppTheme.cfAmber),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // CARD 3
                Expanded(
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cfBorder)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                         const Align(alignment: Alignment.centerLeft, child: Text("AI ACCURACY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted))),
                         const SizedBox(height: 8),
                         Expanded(
                           child: Center(
                             child: Stack(
                               alignment: Alignment.center,
                               children: [
                                 SizedBox(
                                   width: 100, height: 100,
                                   child: CircularProgressIndicator(value: 0.92, strokeWidth: 12, backgroundColor: AppTheme.cfSurface, color: AppTheme.cfGreen),
                                 ),
                                 const Text("92%\nVerified", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                               ],
                             ),
                           ),
                         )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CARD 4
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cfBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("INCIDENTS BY ZONE (TOP 5)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                  const SizedBox(height: 16),
                  _buildTableBar("Lobby — Level 1", 5, 0.5),
                  _buildTableBar("Main Kitchen", 3, 0.3),
                  _buildTableBar("Pool Deck", 2, 0.2),
                  _buildTableBar("East Wing Hall", 1, 0.1),
                  _buildTableBar("Basement Parking", 1, 0.1),
                ],
              ),
            ),
          ]
        )
      )
    );
  }

  Widget _buildFilterChip(String label, bool active) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       decoration: BoxDecoration(
         color: active ? AppTheme.cfNavy : Colors.transparent,
         border: Border.all(color: active ? AppTheme.cfNavy : AppTheme.cfBorder),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : AppTheme.cfNavy)),
     );
  }

  Widget _buildHorizontalBar(String label, int value, Color color, double factor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(
            child: TweenAnimationBuilder<double>(
               tween: Tween(begin: 0, end: factor),
               duration: const Duration(milliseconds: 800),
               builder: (ctx, val, child) {
                 return FractionallySizedBox(
                   alignment: Alignment.centerLeft,
                   widthFactor: val,
                   child: Container(height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                 );
               }
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.cfNavy)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTableBar(String label, int count, double factor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.cfNavy))),
          Expanded(
             flex: 3,
             child: Row(
               children: [
                 Expanded(
                   child: FractionallySizedBox(
                     alignment: Alignment.centerLeft,
                     widthFactor: factor,
                     child: Container(height: 8, decoration: BoxDecoration(color: AppTheme.cfBorder, borderRadius: BorderRadius.circular(2))),
                   )
                 ),
                 const SizedBox(width: 8),
                 Text(count.toString(), style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
               ],
             )
          )
        ],
      ),
    );
  }
}
