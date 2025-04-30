import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? otp;
  bool isLoading = false;
  String? selectedCategory;

  final List<String> categories = ['delivery', 'guest', 'other'];

  Future<void> generateOtp() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID not found')));
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await UserService.generateOtp(userId, selectedCategory!);
      setState(() {
        otp = response['otp'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Select Category:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items:
                  categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat[0].toUpperCase() + cat.substring(1)),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  otp = null; // reset previous OTP if any
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  (isLoading || selectedCategory == null) ? null : generateOtp,
              child: Text(
                otp == null ? 'Generate QR Code' : 'Regenerate QR Code',
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (otp != null)
              Column(
                children: [
                  QrImageView(
                    data: otp!,
                    version: QrVersions.auto,
                    size: 300,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(15),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Category : ${selectedCategory!}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This QR Code is valid till ${DateFormat('h:mm a').format(DateTime.now().add(Duration(minutes: 30)))}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
