import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/branch_inventory.dart';
import '../models/book.dart';
import '../models/restock_request.dart';
import '../providers/auth_provider.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/restock_request_provider.dart';
import '../providers/book_provider.dart';

class EmployeeBooksScreen extends StatefulWidget {
  @override
  State<EmployeeBooksScreen> createState() => _EmployeeBooksScreenState();
}

class _EmployeeBooksScreenState extends State<EmployeeBooksScreen> {
  List<Book> _allBooks = [];
  Map<int, BranchInventory> _branchInventoryMap = {};
  Map<int, RestockRequest?> _approvedRestock = {};
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
    ).getAvailableForBranch(branchId, fts: _search);
    final restockProvider = Provider.of<RestockRequestProvider>(
      context,
      listen: false,
    );
    final restockMap = <int, RestockRequest?>{};
    for (var b in allBooks) {
      final requests = await restockProvider.getApprovedForBranchBook(b.id);
      restockMap[b.id] = requests.isNotEmpty ? requests.first : null;
    }

    setState(() {
      _allBooks = allBooks;
      _branchInventoryMap = {for (var b in branchBooks) b.bookId: b};
      _approvedRestock = restockMap;
    });
    setState(() => _loading = false);
  }

  void _openEditDialog(Book book, BranchInventory? inv) async {
    final rr = _approvedRestock[book.id];
    int maxAdd = rr?.quantityRequested ?? 0;
    int sale = inv?.quantityForSale ?? 0;
    int borrow = inv?.quantityForBorrow ?? 0;
    int saleChange = 0;
    int borrowChange = 0;
    String error = '';
    final saleController = TextEditingController(text: '0');
    final borrowController = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (rr == null || maxAdd <= 0) {
              return AlertDialog(
                title: Text('Unos knjiga (${book.title})'),
                content: Text(
                  'Nema odobrenog zahtjeva za prijem ove knjige. Zatraži dopunu preko "Dopuna" opcije.',
                  style: TextStyle(color: Colors.red),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Odustani'),
                  ),
                ],
              );
            }
            void updateSale(String v) {
              int val = int.tryParse(v) ?? 0;
              setState(() {
                saleChange = val;
                error = '';
              });
            }

            void updateBorrow(String v) {
              int val = int.tryParse(v) ?? 0;
              setState(() {
                borrowChange = val;
                error = '';
              });
            }

            int totalAdd =
                (saleChange > 0 ? saleChange : 0) +
                (borrowChange > 0 ? borrowChange : 0);
            return AlertDialog(
              title: Text('Unos knjiga (${book.title})'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Na stanju: prodaja: $sale, iznajmljivanje: $borrow'),
                  Text('Dostupno za prijem: $maxAdd'),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text('Za prodaju:')),
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (saleChange > 0)
                            setState(() {
                              saleChange--;
                              saleController.text = saleChange.toString();
                              error = '';
                            });
                        },
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: saleController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (v) {
                            int val = int.tryParse(v) ?? 0;
                            if (val < 0) val = 0;
                            if (val + borrowChange > maxAdd)
                              val = maxAdd - borrowChange;
                            saleController.text = val.toString();
                            saleController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: saleController.text.length),
                            );
                            updateSale(saleController.text);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if ((saleChange + borrowChange) < maxAdd)
                            setState(() {
                              saleChange++;
                              saleController.text = saleChange.toString();
                              error = '';
                            });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Za iznajmljivanje:')),
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (borrowChange > 0)
                            setState(() {
                              borrowChange--;
                              borrowController.text = borrowChange.toString();
                              error = '';
                            });
                        },
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: borrowController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (v) {
                            int val = int.tryParse(v) ?? 0;
                            if (val < 0) val = 0;
                            if (val + saleChange > maxAdd)
                              val = maxAdd - saleChange;
                            borrowController.text = val.toString();
                            borrowController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: borrowController.text.length,
                                  ),
                                );
                            updateBorrow(borrowController.text);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if ((saleChange + borrowChange) < maxAdd)
                            setState(() {
                              borrowChange++;
                              borrowController.text = borrowChange.toString();
                              error = '';
                            });
                        },
                      ),
                    ],
                  ),
                  if (totalAdd != maxAdd)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Zbir mora biti tačno $maxAdd knjiga!',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error, style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (totalAdd != maxAdd) {
                      setState(
                        () => error = 'Zbir mora biti tačno $maxAdd knjiga!',
                      );
                      return;
                    }
                    try {
                      await Provider.of<BranchInventoryProvider>(
                        context,
                        listen: false,
                      ).upsertInventory(
                        inv?.branchId ??
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).branchId!,
                        book.id,
                        saleChange,
                        borrowChange,
                      );
                      Navigator.pop(ctx);
                      _fetchData();
                    } catch (e) {
                      setState(() => error = e.toString());
                    }
                  },
                  child: Text('Spasi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openRestockDialog(Book book, BranchInventory? inv) {
    int maxCentralStock = book.centralStock;
    int wanted = 1;
    String? error;
    final TextEditingController controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateWanted(String v) {
              int val = int.tryParse(v) ?? 1;
              if (val < 1) val = 1;
              if (val > maxCentralStock) val = maxCentralStock;
              wanted = val;
              controller.text = wanted.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              setState(() {
                error = null;
              });
            }

            return AlertDialog(
              title: Text('Zatraži dopunu (${book.title})'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: wanted > 1
                            ? () {
                                setState(() {
                                  wanted--;
                                  controller.text = wanted.toString();
                                  error = null;
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                          onChanged: (v) => setState(() => updateWanted(v)),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: wanted < maxCentralStock
                            ? () {
                                setState(() {
                                  wanted++;
                                  controller.text = wanted.toString();
                                  error = null;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Dostupno u centralnom skladištu: $maxCentralStock'),
                  if (error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(error!, style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (wanted > maxCentralStock) {
                      setState(() {
                        error = 'Nema dovoljno knjiga na stanju!';
                      });
                      return;
                    }
                    if (wanted < 1) {
                      setState(() {
                        error = 'Minimalno 1 knjiga!';
                      });
                      return;
                    }
                    try {
                      await Provider.of<RestockRequestProvider>(
                        context,
                        listen: false,
                      ).createRestockRequest(book.id, wanted);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Zahtjev za dopunu je uspješno poslan!',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      _fetchData();
                    } catch (e) {
                      setState(() {
                        error = e.toString();
                      });
                    }
                  },
                  child: Text('Zatraži'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeBook(Book book, BranchInventory? inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Potvrda brisanja'),
        content: Text(
          'Da li ste sigurni da želite trajno ukloniti knjigu "${book.title}" iz ove poslovnice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Provider.of<BranchInventoryProvider>(
        context,
        listen: false,
      ).removeBookFromBranch(inv!.branchId, book.id);
      _fetchData();
    }
  }

  Widget _responsiveButton(
    String text,
    VoidCallback onPressed,
    Color? bg,
    Color? fg,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              minimumSize: Size(0, 32),
              maximumSize: Size(double.infinity, 34),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Knjige',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxCross,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: childAspect,
                        ),
                        itemCount: _allBooks.length,
                        itemBuilder: (_, idx) {
                          final book = _allBooks[idx];
                          final inv = _branchInventoryMap[book.id];
                          final available =
                              inv != null &&
                              (inv.quantityForSale > 0 ||
                                  inv.quantityForBorrow > 0);
                          return Opacity(
                            opacity: available ? 1.0 : 0.7,
                            child: Stack(
                              children: [
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  color: Color(0xFFFCFAFF),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: AspectRatio(
                                            aspectRatio: 0.65,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.grey.shade100,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child:
                                                  (book
                                                      .photoEndpoint
                                                      .isNotEmpty)
                                                  ? Image.network(
                                                      "https://localhost:7295${book.photoEndpoint}",
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) => Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 38,
                                                            color: Colors.grey,
                                                          ),
                                                    )
                                                  : Icon(
                                                      Icons.image_not_supported,
                                                      size: 38,
                                                      color: Colors.grey,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      book.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                book.author,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${book.genreName} • ${book.languageName}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  if (inv != null) ...[
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.indigo[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Prodaja: ${inv.quantityForSale}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.indigo,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Iznajmljivanje: ${inv.quantityForBorrow}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.teal[900],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (inv == null) ...[
                                                _responsiveButton(
                                                  'Uredi',
                                                  () => _openEditDialog(
                                                    book,
                                                    null,
                                                  ),
                                                  Colors.blue[50],
                                                  Colors.blue[900],
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: _responsiveButton(
                                                    'Dopuna',
                                                    () => _openRestockDialog(
                                                      book,
                                                      inv,
                                                    ),
                                                    Colors.deepOrange[50],
                                                    Colors.deepOrange,
                                                  ),
                                                ),
                                              ] else ...[
                                                _responsiveButton(
                                                  'Uredi',
                                                  () => _openEditDialog(
                                                    book,
                                                    inv,
                                                  ),
                                                  Colors.blue[50],
                                                  Colors.blue[900],
                                                ),
                                                SizedBox(height: 8),
                                                _responsiveButton(
                                                  'Dopuna',
                                                  () => _openRestockDialog(
                                                    book,
                                                    inv,
                                                  ),
                                                  Colors.deepOrange[50],
                                                  Colors.deepOrange,
                                                ),
                                                SizedBox(height: 8),
                                                _responsiveButton(
                                                  'Ukloni',
                                                  () => _removeBook(book, inv),
                                                  Colors.red[50],
                                                  Colors.red[800],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (inv == null)
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
    );
  }
}
