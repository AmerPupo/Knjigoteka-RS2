import '../models/restock_request.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;

class RestockRequestProvider extends BaseProvider<RestockRequest> {
  RestockRequestProvider() : super('RestockRequests');

  @override
  RestockRequest fromJson(data) => RestockRequest.fromJson(data);

  Future<List<RestockRequest>> getAllRequests() async => getAll();

  Future<bool> approve(int id) async {
    final res = await http.post(
      Uri.parse('https://localhost:7295/api/RestockRequests/$id/approve'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> reject(int id) async {
    final res = await http.post(
      Uri.parse('https://localhost:7295/api/RestockRequests/$id/reject'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
