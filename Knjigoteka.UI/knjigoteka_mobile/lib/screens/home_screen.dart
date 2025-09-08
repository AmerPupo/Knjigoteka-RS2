import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/language.dart';
import '../providers/book_provider.dart';
import '../providers/genre_provider.dart';
import '../providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Book) onBookTap;
  const HomeScreen({required this.onBookTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  String _search = '';
  bool _loading = false;
  Genre? _selectedGenre;
  Language? _selectedLanguage;
  List<Genre> _genres = [];
  List<Language> _languages = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _fetchBooks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final genres = await Provider.of<GenreProvider>(
      context,
      listen: false,
    ).getAll();
    final languages = await Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).getAll();
    setState(() {
      _genres = genres;
      _languages = languages;
    });
  }

  Future<void> _fetchBooks() async {
    setState(() => _loading = true);
    try {
      final books = await Provider.of<BookProvider>(context, listen: false)
          .getBooks(
            fts: _search,
            genreId: _selectedGenre?.id,
            languageId: _selectedLanguage?.id,
          );
      setState(() => _books = books);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: ${e.toString()}')));
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _showFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _FilterSheet(
        genres: _genres,
        languages: _languages,
        selectedGenre: _selectedGenre,
        selectedLanguage: _selectedLanguage,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedGenre = result['genre'] as Genre?;
        _selectedLanguage = result['language'] as Language?;
      });
      _fetchBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      child: TextField(
                        onChanged: (val) {
                          _search = val;
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () {
                              _fetchBooks();
                            },
                          );
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Pretraži knjige ili autore...',
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF3F6FA),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showFilters,
                    icon: Icon(Icons.filter_list, size: 20),
                    label: Text('Filteri', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF233348),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchBooks,
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _books.isEmpty
                    ? Center(
                        child: Text(
                          'Nema knjiga za prikaz',
                          style: TextStyle(fontSize: 17),
                        ),
                      )
                    : ListView.separated(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: _books.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final b = _books[idx];
                          return GestureDetector(
                            onTap: () {
                              widget.onBookTap(b);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 75,
                                    height: 105,
                                    margin: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF3F6FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: b.hasImage
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              "http://10.0.2.2:7295${b.photoEndpoint}",
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    Icons.menu_book,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.menu_book,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 12,
                                        top: 15,
                                        bottom: 15,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            b.author,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${b.price.toStringAsFixed(2)} KM',
                                            style: TextStyle(
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(height: 7),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              child: Text('Dodaj u korpu'),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 11,
                                                ),
                                                backgroundColor: Color(
                                                  0xFF233348,
                                                ),
                                                foregroundColor: Colors.white,
                                                textStyle: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<Genre> genres;
  final List<Language> languages;
  final Genre? selectedGenre;
  final Language? selectedLanguage;
  const _FilterSheet({
    required this.genres,
    required this.languages,
    this.selectedGenre,
    this.selectedLanguage,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  Genre? _genre;
  Language? _language;

  @override
  void initState() {
    super.initState();
    _genre = widget.selectedGenre;
    _language = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 22, right: 22, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filteri',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<Genre>(
            decoration: InputDecoration(
              labelText: 'Žanr',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: _genre,
            isExpanded: true,
            items: [
              DropdownMenuItem(child: Text('Svi žanrovi'), value: null),
              ...widget.genres.map(
                (g) => DropdownMenuItem(child: Text(g.name), value: g),
              ),
            ],
            onChanged: (val) => setState(() => _genre = val),
          ),
          SizedBox(height: 15),
          DropdownButtonFormField<Language>(
            decoration: InputDecoration(
              labelText: 'Jezik',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: _language,
            isExpanded: true,
            items: [
              DropdownMenuItem(child: Text('Svi jezici'), value: null),
              ...widget.languages.map(
                (l) => DropdownMenuItem(child: Text(l.name), value: l),
              ),
            ],
            onChanged: (val) => setState(() => _language = val),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'genre': _genre,
                'language': _language,
              }),
              child: Text('Primijeni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF233348),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
