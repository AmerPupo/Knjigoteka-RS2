import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: const Center(
        child: Text(
          'Payment Screen Placeholder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
