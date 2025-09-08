import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_mobile/main.dart';
import 'package:knjigoteka_mobile/providers/auth_provider.dart';

class ReservationProvider with ChangeNotifier {
  static const String _baseUrl = "http://10.0.2.2:7295/api/Reservations";

  Future<void> createReservation({
    required int bookId,
    required int branchId,
    String? token,
  }) async {
    final _token = token ?? AuthProvider.token;
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        "bookId": bookId.toString(),
        "branchId": branchId.toString(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg =
          jsonDecode(response.body)["message"]?.toString() ??
          response.body.toString();
      try {
        if (msg.toLowerCase().contains("imate")) {
          msg = "Već imate aktivnu rezervaciju za ovu knjigu.";
        }
      } catch (e) {
        msg = response.body.toString();
      }
      throw Exception(msg);
    }
  }
}
