import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/services/admin_service.dart';

class ApproveVehiclesScreen extends StatefulWidget {
  const ApproveVehiclesScreen({super.key});

  @override
  State<ApproveVehiclesScreen> createState() => _ApproveVehiclesScreenState();
}

class _ApproveVehiclesScreenState extends State<ApproveVehiclesScreen> {
  List<dynamic> approvedVehicles = [];
  List<dynamic> deniedVehicles = [];
  List<dynamic> pendingVehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    setState(() => isLoading = true);
    try {
      final json = await AdminService.getAllVehicles();

      setState(() {
        approvedVehicles = json['approved_vehicles'] ?? [];
        deniedVehicles = json['denied_vehicles'] ?? [];
        pendingVehicles = json['pending_vehicles'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching vehicles: $e')),
      );
    }
  }

  Future<void> handleApprove(String userId, String vehicleNumber) async {
    try {
      await AdminService.approveVehicle(userId, vehicleNumber);
      fetchVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> handleDeny(String userId, String vehicleNumber) async {
    try {
      await AdminService.denyVehicle(userId, vehicleNumber);
      fetchVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildVehicleCard(Map vehicle, {bool showActions = false}) {
    return Container(
      width:double.infinity,
      child:
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle: ${vehicle['vehicle_number']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Owner: ${vehicle['owner_name_associated']}'),
                if (showActions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => handleApprove(vehicle['user_id'], vehicle['vehicle_number']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => handleDeny(vehicle['user_id'], vehicle['vehicle_number']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Deny'),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        )
    );
  }

  Widget buildSection(String title, List<dynamic> vehicles, {bool showActions = false}) {
    return  Container(
      width:double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (vehicles.isEmpty)
             Container(
              width:double.infinity,
              child:Text('No vehicles in this section.', style: TextStyle(color: Colors.grey),textAlign:TextAlign.center)
            ),
          ...vehicles.map((v) => buildVehicleCard(v, showActions: showActions)).toList(),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Vehicles')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchVehicles,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSection('Pending Vehicles', pendingVehicles, showActions: true),
                    buildSection('Approved Vehicles', approvedVehicles),
                    buildSection('Denied Vehicles', deniedVehicles),
                  ],
                ),
              ),
            ),
    );
  }
}
