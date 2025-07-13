import 'package:flutter/material.dart';

class HotCoinsPage extends StatelessWidget {
  const HotCoinsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('추천 종목'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: const Center(
        child: Text(''), // 공백 페이지
      ),
    );
  }
}
