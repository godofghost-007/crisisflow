import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/zone_model.dart';
import '../../../models/incident_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/incident_provider.dart';
import '../../../services/firestore_service.dart';
import 'dart:math';

class ZoneMapWidget extends StatelessWidget {
  final List<ZoneModel> zones;

  const ZoneMapWidget({Key? key, required this.zones}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cfBorder),
        ),
        child: const Center(child: Text("No zones mapped", style: TextStyle(color: AppTheme.cfMuted))),
      );
    }
    
    return StreamBuilder<String?>(
      stream: FirestoreService().streamVenueMapUrl(),
      builder: (context, mapSnapshot) {
        final mapUrl = mapSnapshot.data;

        return Consumer<IncidentProvider>(
          builder: (context, provider, child) {
            final activeIncidents = provider.activeIncidents;

            if (mapUrl != null) {
              return _buildInteractiveMap(mapUrl, activeIncidents);
            }

            return _buildGridMap(activeIncidents);
          }
        );
      }
    );
  }

  Widget _buildInteractiveMap(String mapUrl, List<IncidentModel> activeIncidents) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cfSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cfBorder),
        image: DecorationImage(image: NetworkImage(mapUrl), fit: BoxFit.cover),
      ),
      child: Stack(
        children: zones.map((zone) {
          int maxSeverity = 0;
          for (var inc in activeIncidents) {
            if (inc.location.zoneId == zone.id) {
              if (inc.severity != null && inc.severity! > maxSeverity) {
                maxSeverity = inc.severity!;
              }
            }
          }

          if (maxSeverity == 0) return const SizedBox();

          // Consistent pseudo-random positioning based on zone id
          final rand = Random(zone.id.hashCode);
          final top = rand.nextDouble() * 150 + 20;
          final left = rand.nextDouble() * 200 + 20;

          Color beaconColor = maxSeverity >= 8 ? AppTheme.cfRed : AppTheme.cfAmber;

          return Positioned(
            top: top,
            left: left,
            child: Tooltip(
              message: "${zone.name} - Alert!",
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                   color: beaconColor.withOpacity(0.3),
                   shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                       color: beaconColor,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridMap(List<IncidentModel> activeIncidents) {

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            
            // Calculate severity of this zone
            int maxSeverity = 0;
            int incidentCount = 0;
            for (var inc in activeIncidents) {
              if (inc.location.zoneId == zone.id) {
                incidentCount++;
                if (inc.severity != null && inc.severity! > maxSeverity) {
                  maxSeverity = inc.severity!;
                }
              }
            }

            Color bgColor = const Color(0xFFE1F5EE);
            Color borderColor = AppTheme.cfGreen;
            Color textColor = AppTheme.cfNavy;
            FontWeight fw = FontWeight.w500;
            double scale = 1.0;

            if (maxSeverity >= 8) {
               bgColor = AppTheme.cfRed.withOpacity(0.2);
               borderColor = AppTheme.cfRed;
               textColor = AppTheme.cfRed;
               fw = FontWeight.w600;
               scale = 1.05;
            } else if (maxSeverity >= 4) {
               bgColor = AppTheme.cfAmber.withOpacity(0.15);
               borderColor = AppTheme.cfAmber;
               textColor = const Color(0xFF854F0B);
               fw = FontWeight.w600;
            } else if (incidentCount == 0) {
               bgColor = Colors.white;
               borderColor = AppTheme.cfBorder;
               textColor = AppTheme.cfMuted;
            }

            return Transform.scale(
              scale: scale,
              child: Tooltip(
                message: "$incidentCount active incidents",
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        zone.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: textColor, fontWeight: fw),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }
}
