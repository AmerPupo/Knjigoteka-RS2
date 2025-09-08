import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: Center(
          child: Text(
            'Nema istorije narudžbi/posudbi.',
            style: TextStyle(fontSize: 21, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
