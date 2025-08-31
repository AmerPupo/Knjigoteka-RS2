import '../models/book.dart';
import 'base_provider.dart';

class BookProvider extends BaseProvider<Book> {
  BookProvider() : super("Books");

  @override
  Book fromJson(dynamic data) => Book.fromJson(data);

  // Pretraga sa search stringom
  Future<List<Book>> getBooks({String? fts = ''}) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['fts'] = fts;
    return getAll(params: params);
  }

  Future<Book> addBook(Map<String, dynamic> req) async {
    return insert(req);
  }

  Future<Book> updateBook(int id, Map<String, dynamic> req) async {
    return update(id, req);
  }

  Future<bool> deleteBook(int id) async {
    return super.delete(id);
  }
}
