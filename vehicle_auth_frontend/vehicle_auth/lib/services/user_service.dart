import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vehicle_auth/core/config.dart';

class UserService {
  static Future<Map<String, dynamic>> getVehicles(String userId) async {
    final response = await http.get(Uri.parse('${AppConfig.vehicleUrl}/get_user_vehicles?user_id=$userId'));
    return json.decode(response.body);
  }

  static Future<void> updateVehicle(String userId, String oldVehicle, String newVehicle) async {
    await http.put(
      Uri.parse('${AppConfig.vehicleUrl}/update_vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'old_vehicle_number': oldVehicle,
        'new_vehicle_number': newVehicle,
      }),
    );
  }

  static Future<void> deleteVehicle(String userId, String vehicleNumber) async {
    await http.delete(
      Uri.parse('${AppConfig.vehicleUrl}/delete_vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'vehicle_number': vehicleNumber,
      }),
    );
  }

  static Future<void> addVehicle(String userId, String vehicleNumber) async {
    await http.post(
      Uri.parse('${AppConfig.vehicleUrl}/add_vehicle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'vehicle_number': vehicleNumber,
      }),
    );
  }

  static Future<Map<String, dynamic>> generateOtp(String userId, String selectedCategory) async {
    final response = await http.post(
      Uri.parse('${AppConfig.otpUrl}/generate-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId,'category':selectedCategory}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['otp'] != null) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to generate OTP');
    }
  }

  static Future<List<dynamic>> getUserLogs(String userId) async {
    final response = await http.get(Uri.parse('${AppConfig.logsUrl}/get_logs/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load logs');
    }
  }


}
