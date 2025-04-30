import 'package:flutter/material.dart';
import 'package:vehicle_auth/services/admin_service.dart';


class EmergencyGateScreen extends StatelessWidget {
  const EmergencyGateScreen({super.key});

  Future<void> _handleEmergencyOpenGate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Emergency'),
        content: const Text('Are you sure you want to open the gate in emergency?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 111, 23, 23), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Gate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await AdminService.emergencyOpenGate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'No message',style: TextStyle(color: Colors.white),),
        backgroundColor: (result['success'] == true) ? Colors.green : Color.fromARGB(255, 111, 23, 23),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Access')),
      body: Center(
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color.fromARGB(255, 111, 23, 23),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleEmergencyOpenGate(context),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.warning, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Emergency Open Gate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
