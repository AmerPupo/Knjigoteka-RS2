import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/models/branch_inventory.dart';
import 'package:knjigoteka_mobile/providers/branch_inventory_provider.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final VoidCallback onClose;
  const BookDetailsScreen({required this.book, required this.onClose});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  int _quantity = 1;
  bool _showAvailability = false;
  List<BranchInventory> _availability = [];
  bool _loadingAvailability = false;

  Future<void> _fetchAvailability() async {
    setState(() {
      _loadingAvailability = true;
    });
    try {
      final list = await Provider.of<BranchInventoryProvider>(
        context,
        listen: false,
      ).getAvailabilityByBookId(widget.book.id);
      if (!mounted) return;
      setState(() {
        _availability = list;
        _loadingAvailability = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;

    return SafeArea(
      child: Container(
        color: Color(0xFFF3F6FA),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Color(0xFF233348),
                        size: 27,
                      ),
                      onPressed: widget.onClose,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Detalji knjige",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF233348),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: b.hasImage
                      ? Image.network(
                          "http://10.0.2.2:7295${b.photoEndpoint}",
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.menu_book,
                          size: 90,
                          color: Colors.grey[400],
                        ),
                ),
                SizedBox(height: 14),
                Text(
                  b.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  b.author,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  b.shortDescription,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      b.averageRating!.toStringAsFixed(1),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 3),
                    Row(
                      children: List.generate(5, (i) {
                        final full = b.averageRating! >= i + 1;
                        final half =
                            b.averageRating! > i && b.averageRating! < i + 1;
                        return Icon(
                          full
                              ? Icons.star
                              : half
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 19,
                        );
                      }),
                    ),
                    SizedBox(width: 7),
                    Text(
                      "(${b.reviewsCount})",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                if (!_showAvailability)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF233348),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      onPressed: () async {
                        setState(() => _showAvailability = true);
                        await _fetchAvailability();
                      },
                      child: Text("Provjeri dostupnost u radnjama"),
                    ),
                  ),
                if (_showAvailability)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              setState(() => _showAvailability = false),
                          child: Text("Zatvori dostupnost u radnjama"),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: EdgeInsets.all(13),
                        child: _loadingAvailability
                            ? Center(child: CircularProgressIndicator())
                            : _availability.isEmpty
                            ? Text("Nema informacija o dostupnosti.")
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dostupno u sljedećim poslovnicama:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 9),
                                  Column(
                                    children: _availability
                                        .where((bi) => bi.supportsBorrowing)
                                        .map((bi) {
                                          final available =
                                              bi.quantityForBorrow > 0;
                                          return Card(
                                            color: available
                                                ? Color(0xFFEFFEED)
                                                : Color(0xFFFFEFEF),
                                            child: ListTile(
                                              title: Text(
                                                bi.branchName ?? "N/A",
                                              ),
                                              subtitle: Text(
                                                "Adresa: ${bi.branchAddress ?? "N/A"}",
                                              ),
                                              trailing: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: available
                                                      ? Colors.green
                                                      : Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: available
                                                    ? () {
                                                        // Rezerviši
                                                      }
                                                    : () {
                                                        // Obavijesti me
                                                      },
                                                child: Text(
                                                  available
                                                      ? "Rezerviši"
                                                      : "Obavijesti me",
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                SizedBox(height: 17),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Količina",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final q = int.tryParse(val);
                          if (q != null && q > 0) setState(() => _quantity = q);
                        },
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.shopping_cart_outlined),
                        label: Text("Dodaj u korpu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF233348),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  "Specifikacije:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "Kategorija:",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 8),
                    Text(b.genreName),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text("ISBN:", style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 8),
                    Text(b.isbn),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text("Jezik:", style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 8),
                    Text(b.languageName),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
