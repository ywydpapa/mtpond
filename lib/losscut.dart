import 'package:flutter/material.dart';

class LosscutPage extends StatelessWidget {
  const LosscutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('손절현황'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''),
      ),
    );
  }
}
