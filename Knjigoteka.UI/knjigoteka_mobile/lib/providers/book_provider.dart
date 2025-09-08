import '../models/book.dart';
import 'base_provider.dart';

class BookProvider extends BaseProvider<Book> {
  BookProvider() : super("Books");

  @override
  Book fromJson(dynamic data) => Book.fromJson(data);

  Future<List<Book>> getBooks({
    String? fts = '',
    int? genreId,
    int? languageId,
  }) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['FTS'] = fts;
    if (genreId != null) params['GenreId'] = genreId.toString();
    if (languageId != null) params['LanguageId'] = languageId.toString();
    return getAll(params: params);
  }

  Future<Book> getBook(int id) async {
    return getById(id);
  }
}
