import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/user_service.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  Map<String, dynamic>? vehicles;
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId == null) return;

    final response = await UserService.getVehicles(userId!);
    setState(() {
      vehicles = response;
      isLoading = false;
    });
  }

  void _showEditDialog(String oldVehicleNumber) {
    final controller = TextEditingController(text: oldVehicleNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Vehicle Number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserService.updateVehicle(userId!, oldVehicleNumber, controller.text);
              _loadVehicles();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String vehicleNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $vehicleNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserService.deleteVehicle(userId!, vehicleNumber);
              _loadVehicles();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Vehicle Number',
            hintText: 'e.g. MH12XY1234',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final vehicleNumber = controller.text.trim();
              if (vehicleNumber.isNotEmpty) {
                Navigator.pop(context);
                await UserService.addVehicle(userId!, vehicleNumber);
                _loadVehicles();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }



  Widget _buildVehicleList(String title, List list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...list.map<Widget>((v) => Card(
          child: ListTile(
            title: Text(v['number']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(v['number']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(v['number']),
                ),
              ],
            ),
          ),
        )),
        const Divider(),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),

      appBar: AppBar(title: const Text('My Vehicles')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVehicles,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vehicles?['approved_vehicles']?.isNotEmpty ?? false)
                    _buildVehicleList('Approved Vehicles', vehicles!['approved_vehicles']),
                  if (vehicles?['pending_vehicles']?.isNotEmpty ?? false)
                    _buildVehicleList('Pending Vehicles', vehicles!['pending_vehicles']),
                  if (vehicles?['denied_vehicles']?.isNotEmpty ?? false)
                    _buildVehicleList('Denied Vehicles', vehicles!['denied_vehicles']),
                  if ((vehicles?['approved_vehicles']?.isEmpty ?? true) &&
                      (vehicles?['pending_vehicles']?.isEmpty ?? true) &&
                      (vehicles?['denied_vehicles']?.isEmpty ?? true))
                    const Center(child: Text("No vehicles found.")),
                ],
              ),
            ),
    );
  }
}
