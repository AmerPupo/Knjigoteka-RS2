import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/main.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import '../models/reservation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReservationProvider with ChangeNotifier {
  final String baseUrl = 'http://localhost:7295/api/Reservations';

  Future<List<Reservation>> getAllReservations() async {
    final token = AuthProvider.token;
    final res = await http.get(
      Uri.parse('$baseUrl'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print(res.body);
    _ensureValidResponseOrThrow(res);
    final decoded = jsonDecode(res.body);
    final List items = decoded is List ? decoded : decoded['items'] ?? [];
    return items.map((json) => Reservation.fromJson(json)).toList();
  }

  Future<void> deleteReservation(int reservationId) async {
    final token = AuthProvider.token;
    final res = await http.delete(
      Uri.parse('$baseUrl/$reservationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    _ensureValidResponseOrThrow(res);
    notifyListeners();
  }

  void _ensureValidResponseOrThrow(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 401) {
      AuthProvider().logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);

      throw Exception("Session expired. Please login again.");
    }

    String msg = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'];
      }
    } catch (_) {}
    throw Exception("Error ${res.statusCode}: $msg");
  }
}
