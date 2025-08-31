import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ime;
  late TextEditingController _prezime;
  late TextEditingController _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _ime = TextEditingController(text: auth.fullName?.split(' ').first ?? '');
    _prezime = TextEditingController(
      text: auth.fullName?.split(' ').last ?? '',
    );
    _email = TextEditingController(text: auth.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fb),
      body: Center(
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 56, horizontal: 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 44),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Postavke računa",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 22),
                  TextFormField(
                    controller: _ime,
                    decoration: InputDecoration(labelText: "Ime"),
                    validator: (v) => v!.isEmpty ? "Obavezno polje" : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _prezime,
                    decoration: InputDecoration(labelText: "Prezime"),
                    validator: (v) => v!.isEmpty ? "Obavezno polje" : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(labelText: "Email"),
                    validator: (v) => v!.isEmpty ? "Obavezno polje" : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_error!, style: TextStyle(color: Colors.red)),
                    ),
                  SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(onPressed: _save, child: Text("Sačuvaj")),
                      SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Odustani"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {} catch (e) {
      setState(() => _error = "Greška: $e");
    }
  }
}
