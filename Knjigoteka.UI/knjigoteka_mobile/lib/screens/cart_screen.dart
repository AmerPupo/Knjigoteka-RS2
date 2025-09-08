import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: Center(
          child: Text(
            'Vaša korpa je prazna.',
            style: TextStyle(fontSize: 21, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
