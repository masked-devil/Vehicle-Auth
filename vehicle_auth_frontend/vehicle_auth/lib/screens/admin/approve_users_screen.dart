import 'package:flutter/material.dart';
import '/services/admin_service.dart';

class ApproveUsersScreen extends StatefulWidget {
  const ApproveUsersScreen({super.key});

  @override
  State<ApproveUsersScreen> createState() => _ApproveUsersScreenState();
}

class _ApproveUsersScreenState extends State<ApproveUsersScreen> {
  Map<String, dynamic> users = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final data = await AdminService.getAllUsers();
    setState(() {
      users = data;
      isLoading = false;
    });
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await AdminService.approveUser(userId, status);
    fetchUsers(); // Refresh list
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isPending = false}) {
    return Container(
      width: double.infinity,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Wing: ${user['wing']}, Floor: ${user['flat_floor']}, Flat: ${user['flat_number']}'),
              if (isPending)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => updateUserStatus(user['userid'], "true"),
                      child: const Text("Approve", style: TextStyle(color: Colors.green)),
                    ),
                    TextButton(
                      onPressed: () => updateUserStatus(user['userid'], "denied"),
                      child: const Text("Deny", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> usersList, {bool isPending = false}) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          ),
          if (usersList.isEmpty)
            Container(
              width: double.infinity,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No users", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center,),
              ),
            )
          else
            ...usersList.map((u) => _buildUserCard(u, isPending: isPending)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approve Users")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSection("Pending Users", users["pending_users"] ?? [], isPending: true),
                    _buildSection("Approved Users", users["approved_users"] ?? []),
                    _buildSection("Denied Users", users["denied_users"] ?? []),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
