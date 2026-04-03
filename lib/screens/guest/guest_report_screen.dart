import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/incident_model.dart';
// Note: In real app import mobile_scanner here

class GuestReportScreen extends StatefulWidget {
  final String? zoneId;

  const GuestReportScreen({Key? key, this.zoneId}) : super(key: key);

  @override
  State<GuestReportScreen> createState() => _GuestReportScreenState();
}

class _GuestReportScreenState extends State<GuestReportScreen> {
  String? _selectedType;
  File? _photo;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _locationZoneName;

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _signInSilently();
    if (widget.zoneId != null) {
      // Mock lookup zone name from zoneId
      _locationZoneName = "Scanned Location";
    }
  }

  Future<void> _signInSilently() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (authProv.user == null) {
      await authProv.signInAnonymously();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) {
      setState(() {
        _photo = File(photo.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_selectedType == null) return;
    setState(() => _isSubmitting = true);

    try {
      final String newId = const Uuid().v4();
      String? photoURL;

      if (_photo != null) {
        // Upload photo
        await _storageService.uploadIncidentPhotoWithFile(newId, _photo!);
        photoURL = await _storageService.getDownloadURL(newId);
      }

      final incident = IncidentModel(
        id: newId,
        type: _selectedType!,
        status: 'pending',
        location: LocationInfo(zoneId: widget.zoneId, zoneName: _locationZoneName),
        photoURL: photoURL,
        timestamp: DateTime.now(),
        note: _noteController.text,
      );

      await _firestoreService.createIncident(incident);

      if (mounted) {
        context.go('/uploading?incidentId=$newId');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.cfRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.cfNavy,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppTheme.cfRed, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CrisisFlow", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text("Scan QR to report", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text("Staff login", style: TextStyle(fontSize: 11, color: AppTheme.cfRed)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("SELECT INCIDENT TYPE"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTypeCard('fire', 'Fire', AppTheme.cfRed, const Color(0xFFFFF0F0), const Color(0xFFFECACA), Icons.local_fire_department)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTypeCard('medical', 'Medical', AppTheme.cfBlue, const Color(0xFFEFF6FF), const Color(0xFFBFDBFE), Icons.medical_services)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTypeCard('security', 'Security', AppTheme.cfAmber, const Color(0xFFFFFBEB), const Color(0xFFFDE68A), Icons.security)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTypeCard('other', 'Other', AppTheme.cfMuted, const Color(0xFFF5F5F5), const Color(0xFFE0E0E0), Icons.more_horiz)),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle("YOUR LOCATION"),
                const SizedBox(height: 8),
                _buildLocationSection(),
                const SizedBox(height: 24),

                _buildSectionTitle("ADD A PHOTO (OPTIONAL)"),
                const SizedBox(height: 8),
                _buildPhotoSection(),
                const SizedBox(height: 24),

                _buildSectionTitle("ADD A NOTE (OPTIONAL)"),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Describe what you see...",
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_selectedType != null && !_isSubmitting) ? _submitReport : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType != null ? AppTheme.cfRed : const Color(0xFFF0AEAE),
                    ),
                    child: _isSubmitting 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check, size: 18),
                              SizedBox(width: 8),
                              Text("Report Emergency"),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text("Already staff? Sign in →", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                  ),
                ),
                const SizedBox(height: 32), // bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.cfMuted, letterSpacing: 0.07),
    );
  }

  Widget _buildTypeCard(String id, String label, Color mainColor, Color bgUnselected, Color borderUnselected, IconData icon) {
    final bool isSelected = _selectedType == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        height: 88,
        decoration: BoxDecoration(
          color: isSelected ? bgUnselected.withOpacity(0.8) : bgUnselected,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainColor : borderUnselected,
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: mainColor, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mainColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (widget.zoneId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF7),
          border: Border.all(color: const Color(0xFF6EE7B7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF085041), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_locationZoneName ?? widget.zoneId!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF085041))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 4),
              child: Text("Scanned from QR code", style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7))),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          border: Border.all(color: AppTheme.cfBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 32, color: AppTheme.cfMuted),
            const SizedBox(height: 8),
            const Text("Scan the QR code at your location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.cfMuted)),
            const Text("QR codes are posted in every area of the venue", style: TextStyle(fontSize: 11, color: AppTheme.cfDim)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // To be implemented with mobile_scanner
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.cfRed),
                foregroundColor: AppTheme.cfRed,
              ),
              child: const Text("Scan QR Code"),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("Enter location manually", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
            )
          ],
        ),
      );
    }
  }

  Widget _buildPhotoSection() {
    if (_photo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Photo ready", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.cfGreen)),
              TextButton(
                onPressed: () => setState(() => _photo = null),
                child: const Text("Remove", style: TextStyle(fontSize: 11, color: AppTheme.cfRed)),
              )
            ],
          )
        ],
      );
    } else {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cfBorder, style: BorderStyle.none), // Dashed border ideal
          ),
          child: Center(
            child: Column(
              children: const [
                Icon(Icons.camera_alt_outlined, size: 32, color: AppTheme.cfMuted),
                SizedBox(height: 8),
                Text("Tap to take or upload a photo", style: TextStyle(fontSize: 13, color: AppTheme.cfMuted)),
                Text("Gemini AI will verify severity automatically", style: TextStyle(fontSize: 11, color: AppTheme.cfDim)),
              ],
            ),
          ),
        ),
      );
    }
  }
}
