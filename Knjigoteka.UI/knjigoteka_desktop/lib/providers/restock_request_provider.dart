import 'dart:convert';
import '../models/restock_request.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;

class RestockRequestProvider extends BaseProvider<RestockRequest> {
  static const String baseUrl = "http://localhost:7295/api/RestockRequests";
  RestockRequestProvider() : super('RestockRequests');

  @override
  RestockRequest fromJson(data) => RestockRequest.fromJson(data);

  Future<List<RestockRequest>> getAllRequests() async => getAll();

  Future<bool> approve(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$id/approve'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> reject(int id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$id/reject'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<List<RestockRequest>> getApprovedForBranchBook(int bookId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bybranch?bookId=$bookId'),
      headers: getHeaders(),
    );
    print('Response body: ${res.body}');
    if (res.statusCode < 200 || res.statusCode > 299) return [];
    final data = jsonDecode(res.body);
    final List items = data is List ? data : (data['items'] ?? data ?? []);

    return items.map((e) => RestockRequest.fromJson(e)).toList();
  }

  Future<void> createRestockRequest(int bookId, int quantityRequested) async {
    final body = jsonEncode({
      "bookId": bookId,
      "quantityRequested": quantityRequested,
    });
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: getHeaders(),
      body: body,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(res.body);
    }
  }
}
