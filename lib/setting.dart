import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('설정'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''),
      ),
    );
  }
}
