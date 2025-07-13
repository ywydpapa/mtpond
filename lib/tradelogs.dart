import 'package:flutter/material.dart';

class TradeLogsPage extends StatelessWidget {
  const TradeLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('거래 내역'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''),
      ),
    );
  }
}
