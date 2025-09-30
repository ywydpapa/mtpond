import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 링크 이동용

class LosscutPage extends StatelessWidget {
  const LosscutPage({super.key});

  // 광고 배너를 누르면 이동할 링크
  final String adUrl = 'http://www.naver.com';

  // 광고 배너 위젯 생성
  Widget _buildAdBanner(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(adUrl))) {
          await launchUrl(Uri.parse(adUrl));
        }
      },
      child: Container(
        color: Colors.white,
        height: 120,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 광고 이미지가 있다면 Image.asset 또는 Image.network 사용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.campaign, color: Colors.blueAccent, size: 32),
            ),
            const Text(
              '나만의 광고 배너입니다! 클릭해서 이동',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('손절현황'),
        leading: BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(''),
            ),
          ),
          _buildAdBanner(context), // 여기에 광고 배너가 들어갑니다
        ],
      ),
    );
  }
}
