import 'package:flutter/material.dart';

class MarginsPage extends StatelessWidget {
  const MarginsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('수익현황'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''),
      ),
    );
  }
}
