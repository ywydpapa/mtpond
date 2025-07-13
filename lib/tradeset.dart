import 'package:flutter/material.dart';

class TradesetPage extends StatelessWidget {
  const TradesetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('설정 목록'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''),
      ),
    );
  }
}