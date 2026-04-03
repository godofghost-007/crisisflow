import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/zone_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class ManagerQRScreen extends StatefulWidget {
  const ManagerQRScreen({Key? key}) : super(key: key);

  @override
  State<ManagerQRScreen> createState() => _ManagerQRScreenState();
}

class _ManagerQRScreenState extends State<ManagerQRScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddZoneSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String name = "";
        String floor = "";
        String section = "";

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create new zone", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: "Zone name (e.g. Lobby — Level 1)"),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Floor (e.g. Level 1)"),
                onChanged: (val) => floor = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Section / Area (e.g. Zone A, East Wing)"),
                onChanged: (val) => section = val,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (name.isEmpty || floor.isEmpty) return;
                    final zoneId = const Uuid().v4();
                    final safeName = Uri.encodeComponent(name);
                    final safeFloor = Uri.encodeComponent(floor);
                    final qrData = "https://crisisflow.app/report?zone=$zoneId&name=$safeName&floor=$safeFloor";
                    
                    final authProv = Provider.of<AuthProvider>(context, listen: false);
                    final uid = authProv.user?.uid ?? 'unknown';

                    final zone = ZoneModel(
                      id: zoneId,
                      name: name,
                      floor: floor,
                      section: section,
                      qrData: qrData,
                      createdAt: DateTime.now(),
                      createdBy: uid,
                    );
                    
                    await _firestoreService.createZone(zone);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfNavy),
                  child: const Text("Create zone"),
                )
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cfSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        elevation: 0,
        title: const Text("Manager · Zones & Maps", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/manager')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Venue zone QR codes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                          Text("Place these QR codes in each area of your venue", style: TextStyle(fontSize: 12, color: AppTheme.cfMuted)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _showAddZoneSheet,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfNavy, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                        child: const Text("+ New zone", style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // NEW MAP UPLOAD SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cfBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("VENUE MAP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfMuted)),
                        const SizedBox(height: 12),
                        StreamBuilder<String?>(
                          stream: _firestoreService.streamVenueMapUrl(),
                          builder: (context, snapshot) {
                            final mapUrl = snapshot.data;
                            return Row(
                              children: [
                                Container(
                                  width: 80, height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cfSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.cfBorder),
                                    image: mapUrl != null ? DecorationImage(image: NetworkImage(mapUrl), fit: BoxFit.cover) : null,
                                  ),
                                  child: mapUrl == null ? const Center(child: Icon(Icons.map_outlined, color: AppTheme.cfDim)) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mapUrl != null ? "Map uploaded successfully" : "No map uploaded", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.cfNavy)),
                                      Text(mapUrl != null ? "Visible to staff dashboard" : "Helps staff locate emergencies", style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final photo = await picker.pickImage(source: ImageSource.gallery);
                                    if (photo != null) {
                                       await _firestoreService.updateVenueMapUrl(photo.path);
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file, size: 14),
                                  label: Text(mapUrl != null ? "Replace" : "Upload Map"),
                                )
                              ],
                            );
                          }
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cfSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cfBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHowToStep("1", "Create zone", "Define area"),
                        const Icon(Icons.arrow_forward, size: 16, color: AppTheme.cfMuted),
                        _buildHowToStep("2", "Print QR", "Place in venue"),
                        const Icon(Icons.arrow_forward, size: 16, color: AppTheme.cfMuted),
                        _buildHowToStep("3", "Guest scans", "Auto-fills location"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<ZoneModel>>(
            stream: _firestoreService.streamZones(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              final zones = snapshot.data!;

              if (zones.isEmpty) {
                 return SliverToBoxAdapter(
                   child: Center(
                     child: Padding(
                       padding: const EdgeInsets.all(40.0),
                       child: Column(
                         children: const [
                           Icon(Icons.add_circle_outline, size: 48, color: AppTheme.cfMuted),
                           SizedBox(height: 16),
                           Text("Create your first zone", style: TextStyle(color: AppTheme.cfMuted)),
                         ],
                       ),
                     ),
                   ),
                 );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final zone = zones[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cfBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(zone.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.cfNavy), overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.cfNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(zone.floor, style: const TextStyle(fontSize: 10, color: AppTheme.cfNavy)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.cfRed, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    // Confirm and delete
                                    _firestoreService.deleteZone(zone.id);
                                  },
                                )
                              ],
                            ),
                            const Spacer(),
                            // QR Display
                            QrImageView(
                              data: zone.qrData,
                              version: QrVersions.auto,
                              size: 120,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(30, 30)),
                            ),
                            const Spacer(),
                            Text(zone.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                            Text("${zone.floor} · ${zone.section}", style: const TextStyle(fontSize: 10, color: AppTheme.cfMuted)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR code saved"))); },
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                    child: const Text("Download", style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfNavy, padding: EdgeInsets.zero),
                                    child: const Text("Print", style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                    childCount: zones.length,
                  ),
                ),
              );
            }
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      )
    );
  }

  Widget _buildHowToStep(String num, String title, String sub) {
    return Row(
      children: [
        Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppTheme.cfNavy, shape: BoxShape.circle), child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.cfMuted)),
          ],
        )
      ],
    );
  }
}
