import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/staff_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class ManagerStaffScreen extends StatefulWidget {
  const ManagerStaffScreen({Key? key}) : super(key: key);

  @override
  State<ManagerStaffScreen> createState() => _ManagerStaffScreenState();
}

class _ManagerStaffScreenState extends State<ManagerStaffScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _generateComplexId(String name, String roleType) {
    if (name.isEmpty) return "TYPE NAME";

    // 1. First 4 characters of name (pad with X to ensure 4 chars)
    String prefix = name.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    if (prefix.length < 4) {
      prefix = prefix.padRight(4, 'X'); 
    } else {
      prefix = prefix.substring(0, 4);
    }
    
    // 2. Special char based on rule
    String specialChar = '@'; // default
    final lowerRole = roleType.toLowerCase();
    
    if (lowerRole.contains('secur') || lowerRole.contains('guard')) {
      specialChar = '#';
    } else if (lowerRole.contains('fire') || lowerRole.contains('medic') || lowerRole.contains('emerg')) {
      specialChar = '!';
    } else if (lowerRole.contains('manag') || lowerRole.contains('upper') || lowerRole.contains('admin')) {
      specialChar = '&';
    }
    
    // 3. 3 random digits to make it 8 characters total
    final rnd = Random();
    String digits = '${rnd.nextInt(10)}${rnd.nextInt(10)}${rnd.nextInt(10)}';
    
    return '$prefix$specialChar$digits';
  }

  void _showAddStaffModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String name = "";
        String roleType = "security_guard"; // Use a sensible default that matches DB stream
        String generatedId = _generateComplexId(name, roleType);
        String phoneInput = "";
        String emailInput = "";

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: StreamBuilder<List<String>>(
            stream: _firestoreService.streamResourceTypes(),
            builder: (context, snapshot) {
              final availableRoles = snapshot.data ?? ['security_guard'];
              if (!availableRoles.contains(roleType) && availableRoles.isNotEmpty) {
                 roleType = availableRoles.first;
              }

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Authorize New Staff", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: roleType,
                        decoration: const InputDecoration(labelText: "Role classification"),
                        items: availableRoles.map((r) => DropdownMenuItem(
                          value: r, 
                          child: Text(r.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13))
                        )).toList(),
                        onChanged: (val) {
                           setState(() {
                             roleType = val!;
                             generatedId = _generateComplexId(name, roleType);
                           });
                        }
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(labelText: "Staff Name (e.g. John Doe)"),
                        onChanged: (val) {
                           setState(() {
                             name = val;
                             generatedId = _generateComplexId(name, roleType);
                           });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "Mobile number (Optional)", hintText: "+1 555-0000"),
                              keyboardType: TextInputType.phone,
                              onChanged: (val) => phoneInput = val,
                            )
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "Email address (Optional)", hintText: "name@venue.com"),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) => emailInput = val,
                            )
                          )
                        ]
                      ),
                      const SizedBox(height: 16),
                      const Text("Generated Staff Access ID:", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cfSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cfBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(generatedId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2, color: AppTheme.cfNavy)),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppTheme.cfNavy),
                              onPressed: () {
                                 setState(() {
                                   generatedId = _generateComplexId(name, roleType);
                                 });
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("First 4 chars of name + 1 role symbol + 3 auto-generated numbers.", style: TextStyle(fontSize: 10, color: AppTheme.cfDim)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (name.isEmpty) return;
                            final newStaff = StaffModel(
                              id: const Uuid().v4(),
                              name: name,
                              accessKey: generatedId,
                              role: roleType,
                              createdAt: DateTime.now(),
                              phone: phoneInput.isNotEmpty ? phoneInput : null,
                              email: emailInput.isNotEmpty ? emailInput : null,
                            );
                            await _firestoreService.addStaff(newStaff);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cfNavy),
                          child: const Text("Authorize & Save", style: TextStyle(color: Colors.white)),
                        )
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
              );
            }
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
        title: const Text("Manager · Staff Access", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/manager')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffModal,
        backgroundColor: AppTheme.cfNavy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Authorize Staff", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<StaffModel>>(
        stream: _firestoreService.streamStaff(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final staffList = snapshot.data!;
          
          if (staffList.isEmpty) {
            return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                    Icon(Icons.badge_outlined, size: 48, color: AppTheme.cfDim),
                    SizedBox(height: 16),
                    Text("No staff authorized", style: TextStyle(color: AppTheme.cfMuted)),
                 ],
               )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cfBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                        const SizedBox(height: 4),
                        Text("ID: ${staff.accessKey}", style: const TextStyle(fontSize: 12, color: AppTheme.cfDim, letterSpacing: 1.2)),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                         _firestoreService.removeStaff(staff.id);
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cfRed, side: const BorderSide(color: AppTheme.cfRed)),
                      child: const Text("Revoke Access", style: TextStyle(fontSize: 11)),
                    )
                  ],
                ),
              );
            },
          );
        }
      )
    );
  }
}
