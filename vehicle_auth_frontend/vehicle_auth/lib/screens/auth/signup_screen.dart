import 'package:flutter/material.dart';
import 'package:vehicle_auth/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController wingController = TextEditingController();
  final TextEditingController flatFloorController = TextEditingController();
  final TextEditingController flatNumberController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final response = await AuthService.signup({
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text,
      "userid": userIdController.text.trim(),
      "wing": wingController.text.trim(),
      "flat_floor": int.tryParse(flatFloorController.text) ?? 0,
      "flat_number": int.tryParse(flatNumberController.text) ?? 0,
    });

    setState(() {
      isLoading = false;
    });

    if (response['success']) {
      // Navigate to login screen after successful signup
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        errorMessage = response['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Signup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: userIdController, decoration: const InputDecoration(labelText: 'User ID')),
            TextField(controller: wingController, decoration: const InputDecoration(labelText: 'Wing')),
            TextField(controller: flatFloorController, decoration: const InputDecoration(labelText: 'Flat Floor'), keyboardType: TextInputType.number),
            TextField(controller: flatNumberController, decoration: const InputDecoration(labelText: 'Flat Number'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : registerUser,
              child: isLoading ? const CircularProgressIndicator() : const Text('Signup'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
