import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/book_provider.dart';
import '../models/branch_inventory.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/sale_provider.dart';
import '../models/sale_insert.dart';

class EmployeeSalesScreen extends StatefulWidget {
  @override
  State<EmployeeSalesScreen> createState() => _EmployeeSalesScreenState();
}

class _EmployeeSalesScreenState extends State<EmployeeSalesScreen> {
  List<Book> _allBooks = [];
  Map<int, BranchInventory> _branchInventoryMap = {};
  Map<int, int> _cart = {};
  bool _loading = false;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final branchId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).branchId!;
      final allBooks = await Provider.of<BookProvider>(
        context,
        listen: false,
      ).getBooks(fts: _search);
      final branchBooks = await Provider.of<BranchInventoryProvider>(
        context,
        listen: false,
      ).getAvailableForSale(branchId, fts: _search);
      final branchMap = {for (var b in branchBooks) b.bookId: b};
      setState(() {
        _allBooks = allBooks;
        _branchInventoryMap = branchMap;
      });
    } catch (e) {
      setState(() {
        _allBooks = [];
        _branchInventoryMap = {};
      });
    }
    setState(() => _loading = false);
  }

  void _addToCart(int bookId, int max) {
    setState(() {
      if (!_cart.containsKey(bookId)) _cart[bookId] = 1;
    });
  }

  void _updateCart(int bookId, int value, int max) {
    setState(() {
      if (value > 0 && value <= max) {
        _cart[bookId] = value;
      } else if (value == 0) {
        _cart.remove(bookId);
      }
    });
  }

  double get _total => _cart.entries.fold(0, (sum, entry) {
    final inv = _branchInventoryMap[entry.key];
    final price = inv?.price ?? 0;
    return sum + (price * entry.value);
  });

  void _showCart() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              minWidth: 320,
              maxHeight: 400,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(18),
              color: Color(0xfffaf5fb),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _cart.isEmpty
                        ? Center(child: Text("Korpa je prazna."))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                "Izabrane knjige",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Divider(),
                              ..._cart.entries.map((e) {
                                final b = _allBooks.firstWhere(
                                  (bk) => bk.id == e.key,
                                );
                                final inv = _branchInventoryMap[e.key];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "${b.author} • ${b.genreName}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "${e.value} x ${inv?.price.toStringAsFixed(2) ?? '0.00'} KM",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Divider(),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Ukupno:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_total.toStringAsFixed(2)} KM",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _finalizeSale();
                                  },
                                  child: Text("Finaliziraj prodaju"),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(170, 40),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      barrierColor: Colors.black.withOpacity(0.15),
    );
  }

  Future<void> _finalizeSale() async {
    if (_cart.isEmpty) return;
    final employeeId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userId!;
    final items = _cart.entries
        .map((e) => SaleItemInsert(bookId: e.key, quantity: e.value))
        .toList();
    try {
      await Provider.of<SaleProvider>(
        context,
        listen: false,
      ).createSale(SaleInsert(employeeId: employeeId, items: items).toJson());
      setState(() {
        _cart.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Prodaja uspješna!')));
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }

  void _showAvailabilityDialog(int bookId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              FutureBuilder<List<BranchInventory>>(
                future: Provider.of<BranchInventoryProvider>(
                  context,
                  listen: false,
                ).getAvailabilityByBookId(bookId),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 140,
                      width: 340,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final data = snapshot.data ?? [];
                  return Container(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    width: 340,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          'Dostupnost u poslovnicama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 16),
                        data.isEmpty
                            ? Text(
                                'Knjiga nije dostupna ni u jednoj poslovnici.',
                                style: TextStyle(fontSize: 14),
                              )
                            : ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 220),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: data.length,
                                  separatorBuilder: (_, __) => Divider(),
                                  itemBuilder: (_, i) {
                                    final inv = data[i];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        inv.branchName ?? 'Poslovnica',
                                      ),
                                      subtitle: Text(
                                        'Za prodaju: ${inv.quantityForSale} | Za iznajmljivanje: ${inv.quantityForBorrow}',
                                        style: TextStyle(fontSize: 13.5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(ctx),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prodaja',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži po nazivu ili autoru...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _search = '';
                                  });
                                  _fetchData();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _search = val;
                        });
                        _fetchData();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _allBooks.isEmpty
                    ? Center(
                        child: Text(
                          'Nema knjiga u sistemu.',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          double screenWidth = constraints.maxWidth;
                          int cardsPerRow = screenWidth > 1200
                              ? 3
                              : screenWidth > 800
                              ? 2
                              : 1;

                          double maxCross = screenWidth / cardsPerRow;
                          double cardHeight = maxCross * 0.4;
                          double childAspect = maxCross / cardHeight;
                          return GridView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: maxCross,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  childAspectRatio: childAspect,
                                ),
                            itemCount: _allBooks.length,
                            itemBuilder: (_, idx) {
                              final book = _allBooks[idx];
                              final inv = _branchInventoryMap[book.id];
                              final inCart = _cart.containsKey(book.id);
                              final isAvailable =
                                  inv != null && inv.quantityForSale > 0;
                              return Opacity(
                                opacity: isAvailable ? 1.0 : 0.55,
                                child: Stack(
                                  children: [
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(18),
                                      color: Color(0xfffaf5fb),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Flexible(
                                              flex: 30,
                                              child: AspectRatio(
                                                aspectRatio: 0.65,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    color: Colors.grey.shade100,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child:
                                                      (book
                                                          .photoEndpoint
                                                          .isNotEmpty)
                                                      ? Image.network(
                                                          "http://localhost:7295${book.photoEndpoint}",
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                size: 38,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 38,
                                                          color: Colors.grey,
                                                        ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Flexible(
                                              flex: 100,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                  left: 4.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      book.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      book.author,
                                                      style: TextStyle(
                                                        fontSize: 13.5,
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${book.genreName} • ${book.languageName}',
                                                      style: TextStyle(
                                                        fontSize: 12.2,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Spacer(),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          '${(inv?.price ?? book.price).toStringAsFixed(2)} KM',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.indigo,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              SizedBox(
                                                                width: 138,
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .stretch,
                                                                  children: [
                                                                    ElevatedButton(
                                                                      onPressed: () =>
                                                                          _showAvailabilityDialog(
                                                                            book.id,
                                                                          ),
                                                                      child: Text(
                                                                        'Dostupnost',
                                                                      ),
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors.grey[300],
                                                                        foregroundColor:
                                                                            Colors.black87,
                                                                        minimumSize:
                                                                            Size(
                                                                              0,
                                                                              35,
                                                                            ),
                                                                        padding: EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              0,
                                                                        ),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: 8,
                                                                    ),
                                                                    isAvailable
                                                                        ? (inCart
                                                                              ? Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.remove_circle_outline,
                                                                                        size: 20,
                                                                                      ),
                                                                                      onPressed: () {
                                                                                        final value =
                                                                                            (_cart[book.id] ??
                                                                                                1) -
                                                                                            1;
                                                                                        _updateCart(
                                                                                          book.id,
                                                                                          value,
                                                                                          inv.quantityForSale,
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                    Text(
                                                                                      '${_cart[book.id]}',
                                                                                    ),
                                                                                    IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.add_circle_outline,
                                                                                        size: 20,
                                                                                      ),
                                                                                      onPressed: () {
                                                                                        final value =
                                                                                            (_cart[book.id] ??
                                                                                                1) +
                                                                                            1;
                                                                                        if (value <=
                                                                                            inv.quantityForSale) {
                                                                                          _updateCart(
                                                                                            book.id,
                                                                                            value,
                                                                                            inv.quantityForSale,
                                                                                          );
                                                                                        }
                                                                                      },
                                                                                    ),
                                                                                    IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.delete_outline,
                                                                                        size: 20,
                                                                                      ),
                                                                                      onPressed: () => _updateCart(
                                                                                        book.id,
                                                                                        0,
                                                                                        inv.quantityForSale,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                )
                                                                              : ElevatedButton(
                                                                                  child: Text(
                                                                                    'Dodaj',
                                                                                  ),
                                                                                  onPressed: () => _addToCart(
                                                                                    book.id,
                                                                                    inv.quantityForSale,
                                                                                  ),
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    minimumSize: Size(
                                                                                      0,
                                                                                      35,
                                                                                    ),
                                                                                    padding: EdgeInsets.symmetric(
                                                                                      horizontal: 0,
                                                                                    ),
                                                                                    textStyle: TextStyle(
                                                                                      fontSize: 16,
                                                                                    ),
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(
                                                                                        8,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ))
                                                                        : Container(
                                                                            padding: EdgeInsets.symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 6,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: Colors.red.withOpacity(
                                                                                0.18,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                            ),
                                                                            child: Center(
                                                                              child: Text(
                                                                                "Nije dostupno",
                                                                                textAlign: TextAlign.center,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: TextStyle(
                                                                                  color: Colors.red,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 14,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isAvailable)
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.9),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(18),
                                              bottomRight: Radius.circular(18),
                                            ),
                                          ),
                                          child: Text(
                                            "Nije dostupno",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_cart.isNotEmpty)
            Positioned(
              right: 32,
              bottom: 32,
              child: FloatingActionButton.extended(
                onPressed: _showCart,
                icon: Icon(Icons.shopping_cart),
                label: Text('${_cart.values.fold(0, (sum, qty) => sum + qty)}'),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
