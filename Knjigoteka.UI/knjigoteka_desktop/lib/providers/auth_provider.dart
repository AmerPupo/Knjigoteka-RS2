import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class AuthProvider extends ChangeNotifier {
  static String? token;
  LoginResponse? _user;

  static bool get isLoggedIn => token != null;

  static String baseUrl = 'https://localhost:7295/api';

  Future<void> login(String email, String password) async {
    // Login and get the JWT token
    final res = await http.post(
      Uri.parse('$baseUrl/User/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      token = data['token'];

      // Fetch user profile using the token
      final userRes = await http.get(
        Uri.parse('$baseUrl/User/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _user = LoginResponse.fromJson(userData);
        notifyListeners();
      } else {
        token = null;
        throw Exception("Failed to fetch user info.");
      }
    } else {
      throw Exception('Pogrešan email ili lozinka.');
    }
  }

  Future<void> logout() async {
    token = null;
    _user = null;
    notifyListeners();
  }

  // Access properties more easily
  String? get role => _user?.role;
  int? get branchId => _user?.branchId;
  int? get userId => _user?.id;
  String? get fullName => _user?.fullName;
  String? get email => _user?.email;
}
