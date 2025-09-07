import 'dart:async';
import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../models/borrowing.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../models/branch_inventory.dart';
import '../providers/borrowing_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/branch_inventory_provider.dart';

class EmployeeLoansScreen extends StatefulWidget {
  @override
  State<EmployeeLoansScreen> createState() => _EmployeeLoansScreenState();
}

class _EmployeeLoansScreenState extends State<EmployeeLoansScreen> {
  String _borrowingSearch = '';
  String _reservationSearch = '';
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xfff7f9fb),
          appBar: AppBar(
            backgroundColor: const Color(0xfff7f9fb),
            elevation: 0,
            toolbarHeight: 100,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: EdgeInsets.all(0),
              child: Text(
                'Posudbe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233348),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Container(
                color: Color(0xfff7f9fb),
                child: TabBar(
                  indicatorColor: Color(0xFF233348),
                  labelColor: Color(0xFF233348),
                  unselectedLabelColor: Colors.black45,
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(text: "Posudbe"),
                    Tab(text: "Rezervacije"),
                  ],
                ),
              ),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 24),
            child: TabBarView(
              children: [
                BorrowingsTab(
                  search: _borrowingSearch,
                  onSearchChanged: (val) =>
                      setState(() => _borrowingSearch = val),
                ),
                ReservationsTab(
                  search: _reservationSearch,
                  onSearchChanged: (val) =>
                      setState(() => _reservationSearch = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BorrowingsTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  const BorrowingsTab({required this.search, required this.onSearchChanged});

  @override
  State<BorrowingsTab> createState() => _BorrowingsTabState();
}

class _BorrowingsTabState extends State<BorrowingsTab> {
  bool _loading = true;
  String? _error;
  List<Borrowing> _borrowings = [];

  @override
  void initState() {
    super.initState();
    _loadBorrowings();
  }

  Future<void> _loadBorrowings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final branchId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).branchId!;
      final provider = Provider.of<BorrowingProvider>(context, listen: false);
      final results = await provider.getAllBorrowings(branchId);
      setState(() => _borrowings = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _returnBook(Borrowing b, bool returned) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Potvrdi vraćanje"),
        content: Text(
          "Da li ste sigurni da želite označiti ovu knjigu kao vraćenu?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Odustani"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Potvrdi"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Provider.of<BorrowingProvider>(
      context,
      listen: false,
    ).setReturned(b.id, returned);
    _loadBorrowings();
  }

  Future<void> _deleteBorrowing(Borrowing b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Potvrdi brisanje"),
        content: Text("Da li ste sigurni da želite obrisati ovu posudbu?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Odustani"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Obriši"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Provider.of<BorrowingProvider>(
      context,
      listen: false,
    ).deleteBorrowing(b.id);
    _loadBorrowings();
  }

  void _showAddBorrowingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddBorrowingDialog(
        onSave: (userId, bookId) async {
          await Provider.of<BorrowingProvider>(
            context,
            listen: false,
          ).insert({"userId": userId, "bookId": bookId, "reservationId": null});
          _loadBorrowings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.search.isEmpty
        ? _borrowings
        : _borrowings
              .where(
                (l) =>
                    l.userName.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ) ||
                    l.bookTitle.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ),
              )
              .toList();

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Pretraži posudbe",
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 18),
                ElevatedButton.icon(
                  onPressed: _showAddBorrowingDialog,
                  icon: Icon(Icons.add),
                  label: Text("Dodaj novu"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF233348),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      "Nema posudbi za prikaz.",
                      style: TextStyle(fontSize: 18, color: Colors.black45),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: [
                          DataColumn(label: Text("Ime i prezime")),
                          DataColumn(label: Text("Knjiga")),
                          DataColumn(label: Text("Datum posudjivanja")),
                          DataColumn(label: Text("Rok za vraćanje")),
                          DataColumn(label: Text("Vraćeno")),
                          DataColumn(label: Text("Obriši")),
                        ],
                        rows: filtered.map((b) {
                          final isReturned = b.returnedAt != null;
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (isReturned) return Colors.grey[200];
                              return Colors.white;
                            }),
                            cells: [
                              DataCell(
                                Text(
                                  b.userName,
                                  style: isReturned
                                      ? TextStyle(color: Colors.black54)
                                      : TextStyle(color: Colors.black),
                                ),
                              ),
                              DataCell(
                                Text(
                                  b.bookTitle,
                                  style: isReturned
                                      ? TextStyle(color: Colors.black54)
                                      : TextStyle(color: Colors.black),
                                ),
                              ),
                              DataCell(
                                Text(
                                  b.borrowedAt.toString().substring(0, 10),
                                  style: isReturned
                                      ? TextStyle(color: Colors.black54)
                                      : TextStyle(color: Colors.black),
                                ),
                              ),
                              DataCell(
                                Builder(
                                  builder: (context) {
                                    final now = DateTime.now();
                                    final daysLeft = b.dueDate
                                        .difference(now)
                                        .inDays;
                                    String text;
                                    TextStyle style = isReturned
                                        ? TextStyle(color: Colors.black54)
                                        : TextStyle(color: Colors.black);
                                    if (isReturned) {
                                      text = "Vraćeno";
                                    } else if (daysLeft < 0) {
                                      text = "Kasni ${-daysLeft} dana";
                                      style = style.copyWith(
                                        color: Colors.red[700],
                                      );
                                    } else if (daysLeft == 0) {
                                      text = "Rok ističe danas";
                                      style = style.copyWith(
                                        color: Colors.orange[800],
                                      );
                                    } else {
                                      text = "$daysLeft dana";
                                      if (daysLeft <= 3)
                                        style = style.copyWith(
                                          color: Colors.orange[800],
                                        );
                                    }
                                    return Text(text, style: style);
                                  },
                                ),
                              ),

                              isReturned
                                  ? DataCell(Container()) // prazno
                                  : DataCell(
                                      Checkbox(
                                        value: b.returnedAt != null,
                                        onChanged: (val) =>
                                            _returnBook(b, val ?? false),
                                      ),
                                    ),
                              isReturned
                                  ? DataCell(Container()) // prazno
                                  : DataCell(
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Color(0xFF233348),
                                        ),
                                        onPressed: () => _deleteBorrowing(b),
                                      ),
                                    ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class AddBorrowingDialog extends StatefulWidget {
  final Function(int userId, int bookId) onSave;
  const AddBorrowingDialog({required this.onSave});
  @override
  State<AddBorrowingDialog> createState() => _AddBorrowingDialogState();
}

class _AddBorrowingDialogState extends State<AddBorrowingDialog> {
  final _userController = TextEditingController();
  final _bookController = TextEditingController();
  User? _selectedUser;
  BranchInventory? _selectedBook;
  List<User> _users = [];
  List<BranchInventory> _books = [];
  bool _loadingUsers = false;
  bool _loadingBooks = false;
  final _formKey = GlobalKey<FormState>();
  Timer? _debounceUser;
  Timer? _debounceBook;

  void _fetchUsers(String query) {
    if (_debounceUser?.isActive ?? false) _debounceUser?.cancel();
    _debounceUser = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingUsers = true);
      try {
        final result = await Provider.of<UserProvider>(
          context,
          listen: false,
        ).searchUsers(FTS: query);
        setState(() {
          _users = result;
        });
      } catch (_) {}
      setState(() => _loadingUsers = false);
    });
  }

  void _fetchBooks(String query) async {
    if (_debounceBook?.isActive ?? false) _debounceBook?.cancel();
    _debounceBook = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingBooks = true);
      try {
        final branchId = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).branchId!;
        final result = await Provider.of<BranchInventoryProvider>(
          context,
          listen: false,
        ).getAvailableForBranch(branchId, fts: query);
        print("Fetched books: ${result.map((e) => e.title).toList()}");
        setState(() {
          _books = result
              .where((b) => b.supportsBorrowing && b.quantityForBorrow > 0)
              .toList();
        });
        print("Filtered books: ${_books.map((e) => e.title).toList()}");
      } catch (e) {
        print("Book fetch error: $e");
      }
      setState(() => _loadingBooks = false);
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _bookController.dispose();
    _debounceUser?.cancel();
    _debounceBook?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width < 900 ? 400.0 : 480.0;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Dodaj posudbu",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Autocomplete<User>(
                  displayStringForOption: (user) =>
                      '${user.fullName} <${user.email}>',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2)
                      return const Iterable<User>.empty();
                    _fetchUsers(value.text);
                    return _users.where(
                      (u) =>
                          u.fullName.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ) ||
                          u.email.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ),
                    );
                  },
                  onSelected: (user) {
                    setState(() {
                      _selectedUser = user;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _userController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Korisnik (ime ili email)',
                            border: OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedUser = null;
                                        _users = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) => _selectedUser == null
                              ? 'Odaberi korisnika'
                              : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _users = [];
                                _selectedUser = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingUsers
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final User option = options.elementAt(
                                      index,
                                    );
                                    return ListTile(
                                      title: Text(option.fullName),
                                      subtitle: Text(option.email),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Autocomplete<BranchInventory>(
                  displayStringForOption: (book) =>
                      '${book.title} - ${book.author}',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2)
                      return const Iterable<BranchInventory>.empty();
                    _fetchBooks(value.text);
                    return _books.where(
                      (b) =>
                          (b.title.toLowerCase().contains(
                                value.text.toLowerCase(),
                              ) ||
                              b.author.toLowerCase().contains(
                                value.text.toLowerCase(),
                              )) &&
                          b.supportsBorrowing &&
                          b.quantityForBorrow > 0,
                    );
                  },
                  onSelected: (book) {
                    setState(() {
                      _selectedBook = book;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _bookController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Knjiga (naslov ili autor)',
                            border: OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedBook = null;
                                        _books = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) =>
                              _selectedBook == null ? 'Odaberi knjigu' : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _books = [];
                                _selectedBook = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingBooks
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final BranchInventory option = options
                                        .elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        '${option.title} - ${option.author}',
                                      ),
                                      subtitle: Text(
                                        'Dostupno: ${option.quantityForBorrow}',
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Otkaži"),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedUser == null || _selectedBook == null)
                          return;
                        widget.onSave(_selectedUser!.id, _selectedBook!.bookId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text("Sačuvaj"),
                    ),
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

class ReservationsTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  const ReservationsTab({required this.search, required this.onSearchChanged});

  @override
  State<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  bool _loading = true;
  String? _error;
  List<Reservation> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<ReservationProvider>(context, listen: false);
      final results = await provider.getAllReservations();
      setState(() => _reservations = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _deleteReservation(Reservation res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Potvrdi brisanje"),
        content: Text("Da li ste sigurni da želite obrisati ovu rezervaciju?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Otkaži"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Obriši"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Provider.of<ReservationProvider>(
      context,
      listen: false,
    ).deleteReservation(res.id);
    _loadReservations();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.search.isEmpty
        ? _reservations
        : _reservations
              .where(
                (r) =>
                    r.userName.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ) ||
                    r.bookTitle.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ),
              )
              .where((r) => (r.expiredAt == null || r.expiredAt!.isAfter(now)))
              .toList();
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Pretraži rezervacije",
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      "Nema rezervacija za prikaz.",
                      style: TextStyle(fontSize: 18, color: Colors.black45),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: [
                          DataColumn(label: Text("Ime i prezime")),
                          DataColumn(label: Text("Knjiga")),
                          DataColumn(label: Text("Datum rezervacije")),
                          DataColumn(label: Text("Potvrdi")),
                          DataColumn(label: Text("Obriši")),
                        ],
                        rows: filtered.map((r) {
                          final isAccepted =
                              r.status.toLowerCase() != "pending";
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (states) =>
                                  isAccepted ? Colors.grey[200] : Colors.white,
                            ),
                            cells: [
                              DataCell(Text(r.userName)),
                              DataCell(Text(r.bookTitle)),
                              DataCell(
                                Text(r.reservedAt.toString().substring(0, 10)),
                              ),
                              isAccepted
                                  ? DataCell(Container())
                                  : DataCell(
                                      Checkbox(
                                        value: false,
                                        onChanged: (val) async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                "Potvrdi preuzimanje rezervacije",
                                              ),
                                              content: Text(
                                                "Da li želite evidentirati posudbu za ovu rezervaciju?\n"
                                                "Ova akcija će kreirati posudbu za korisnika i knjigu iz rezervacije.",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: Text("Otkaži"),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor: Color(
                                                          0xFF233348,
                                                        ),
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  child: Text("Potvrdi"),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await Provider.of<
                                                  BorrowingProvider
                                                >(context, listen: false)
                                                .insert({
                                                  "userId": r.userId,
                                                  "bookId": r.bookId,
                                                  "reservationId": r.id,
                                                });
                                            _loadReservations();
                                          }
                                        },
                                      ),
                                    ),
                              isAccepted
                                  ? DataCell(Container())
                                  : DataCell(
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Color(0xFF233348),
                                        ),
                                        onPressed: () => _deleteReservation(r),
                                      ),
                                    ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
