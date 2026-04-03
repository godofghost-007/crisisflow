import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/resource_model.dart';
import 'package:uuid/uuid.dart';

class ManagerResourcesScreen extends StatefulWidget {
  const ManagerResourcesScreen({Key? key}) : super(key: key);

  @override
  State<ManagerResourcesScreen> createState() => _ManagerResourcesScreenState();
}

class _ManagerResourcesScreenState extends State<ManagerResourcesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddResourceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String name = "";
        String type = "security_guard";
        String zone = "";
        
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Resource", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Name (e.g. Fire Team Alpha)"),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<String>>(
                stream: _firestoreService.streamResourceTypes(),
                builder: (context, snapshot) {
                  final types = snapshot.data ?? ['security_guard'];
                  if (!types.contains(type) && types.isNotEmpty) type = types.first;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => type = val!,
                        decoration: const InputDecoration(labelText: "Type"),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "New type", isDense: true),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) _firestoreService.addResourceType(val);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.cfRed, size: 20),
                            onPressed: () {
                               if (types.length > 1) {
                                  _firestoreService.removeResourceType(type);
                                  type = types.firstWhere((t) => t != type);
                               }
                            },
                          )
                        ],
                      )
                    ],
                  );
                }
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: "Current Zone (e.g. Lobby)"),
                onChanged: (val) => zone = val,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newRes = ResourceModel(
                      id: const Uuid().v4(),
                      name: name,
                      type: type,
                      zone: zone,
                      available: true,
                      lastUpdated: DateTime.now(),
                    );
                    FirebaseFirestore.instance.collection('resources').doc(newRes.id).set(newRes.toMap());
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save Resource"),
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
        // Matching manager app bar minus the duplicate logic, simplified
        backgroundColor: AppTheme.cfNavy,
        elevation: 0,
        title: const Text("Manager · Resources", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/manager')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceModal,
        backgroundColor: AppTheme.cfGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add resource", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
                children: [
                   _buildFilterChip("All", true),
                   const SizedBox(width: 8),
                   _buildFilterChip("Fire teams", false),
                   const SizedBox(width: 8),
                   _buildFilterChip("Medical", false),
                   const Spacer(),
                   const Text("4 deployed · 12 available", style: TextStyle(fontSize: 11, color: AppTheme.cfMuted)),
                ],
             ),
          ),
          Expanded(
            child: StreamBuilder<List<ResourceModel>>(
              stream: _firestoreService.streamResources(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final resources = snapshot.data!;
                
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final res = resources[index];
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
                          Text(res.type.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getColorForType(res.type))),
                          const SizedBox(height: 4),
                          Text(res.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.cfNavy)),
                          Text("Currently: ${res.zone}", style: const TextStyle(fontSize: 11, color: AppTheme.cfMuted), overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: res.available ? AppTheme.cfGreen.withOpacity(0.1) : AppTheme.cfRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(res.available ? "Available" : "Deployed", style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600, 
                              color: res.available ? AppTheme.cfGreen : AppTheme.cfRed
                            )),
                          )
                        ],
                      ),
                    );
                  },
                );
              }
            ),
          )
        ],
      )
    );
  }

  Widget _buildFilterChip(String label, bool active) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       decoration: BoxDecoration(
         color: active ? AppTheme.cfNavy : Colors.white,
         border: Border.all(color: AppTheme.cfBorder),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : AppTheme.cfNavy)),
     );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'fire_team': return AppTheme.cfRed;
      case 'medical_kit': 
      case 'medic': return AppTheme.cfBlue;
      default: return AppTheme.cfAmber;
    }
  }
}
