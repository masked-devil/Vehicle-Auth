import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vehicle_auth/core/config.dart';  // Import global config

class AdminService {
  static Future<Map<String, dynamic>> verifyOtp(String qrData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otp': qrData}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {'success': false, 'message': 'QR Code Invalid'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    final response = await http.get(Uri.parse('${AppConfig.userUrl}/get_users'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> approveUser(String userId, String status) async {
    final response = await http.post(
      Uri.parse('${AppConfig.userUrl}/approve_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"userid": userId, "approved": status}),
    );
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getAllLogs() async {
    final url = Uri.parse('${AppConfig.logsUrl}/get_logs');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch logs: ${response.body}');
    }
  }

    static Future<Map<String, dynamic>> getAllVehicles() async {
    final response = await http.get(Uri.parse('${AppConfig.vehicleUrl}/get_all_vehicles'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch vehicles');
    }
  }

  static Future<void> approveVehicle(String userId, String vehicleNumber) async {
    final response = await http.put(
      Uri.parse('${AppConfig.vehicleUrl}/approve_vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'vehicle_number': vehicleNumber,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve vehicle');
    }
  }

  static Future<void> denyVehicle(String userId, String vehicleNumber) async {
    final response = await http.put(
      Uri.parse('${AppConfig.vehicleUrl}/deny_vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'vehicle_number': vehicleNumber,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to deny vehicle');
    }
  }

  static Future<Map<String, dynamic>> emergencyOpenGate() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.gateUrl}/emergency_open_gate'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server returned error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }


}
