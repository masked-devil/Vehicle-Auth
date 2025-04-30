import 'package:flutter/material.dart';
import 'package:vehicle_auth/screens/admin/admin_dashboard.dart';
import 'package:vehicle_auth/screens/admin/admin_logs_screen.dart';
import 'package:vehicle_auth/screens/admin/approve_users_screen.dart';
import 'package:vehicle_auth/screens/admin/approve_vehicles_screen';
import 'package:vehicle_auth/screens/admin/emergency_gate_open_screen.dart';
import 'package:vehicle_auth/screens/admin/qr_scanner_screen.dart';
import 'package:vehicle_auth/screens/auth/login_screen.dart';
import 'package:vehicle_auth/screens/auth/signup_screen.dart';
import 'package:vehicle_auth/screens/auth/forgot_password_screen.dart';
import 'package:vehicle_auth/screens/auth/admin_login_screen.dart';
import 'package:vehicle_auth/screens/user/dashboard_screen.dart';
import 'package:vehicle_auth/screens/user/generate_qr_screen.dart';
import 'package:vehicle_auth/screens/user/user_logs_screen.dart';
import 'package:vehicle_auth/screens/user/vehicle_management_screen.dart';  // Admin login

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  // '/forgot-password': (context) => const ForgotPasswordScreen(),
  '/admin-login': (context) => const AdminLoginScreen(),
  '/admin_dashboard': (context) => const AdminDashboard(),
  '/user-dashboard': (context) => const UserDashboard(),
  '/scan_qr': (context) => QRScannerScreen(),  
  '/user_vehicles': (context) => const VehicleManagementScreen(),
  '/generate_qr': (context) => const GenerateQrScreen(),
  '/approve_users': (context) => const ApproveUsersScreen(),
  '/vehicle_logs' : (context) => const UserLogsScreen(),
  '/admin_logs' : (context) => const AdminLogsScreen(),
  '/approve_vehicles' : (context) => const ApproveVehiclesScreen(),
  '/emergency_open' : (context) => const EmergencyGateScreen()
};
