import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HotCoin {
  final String coinName;

  HotCoin({required this.coinName});

  factory HotCoin.fromString(String name) {
    return HotCoin(coinName: name);
  }
}

Future<List<HotCoin>> fetchHotCoins() async {
  final response = await http.get(
    Uri.parse('http://becog.iptime.org:8088/api/top30coins'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

    if (data.containsKey('markets') && data['markets'] is List) {
      List<dynamic> markets = data['markets'];
      return markets.map((name) => HotCoin.fromString(name.toString())).toList();
    } else {
      throw Exception('데이터에 markets 항목이 없습니다.');
    }
  } else {
    throw Exception('Failed to load hot coins: ${response.statusCode}');
  }
}

class HotCoinsPage extends StatefulWidget {
  const HotCoinsPage({super.key});

  @override
  State<HotCoinsPage> createState() => _HotCoinsPageState();
}

class _HotCoinsPageState extends State<HotCoinsPage> {
  late Future<List<HotCoin>> hotCoinsFuture;

  List<HotCoin> coins = [];
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    hotCoinsFuture = fetchHotCoins();
    hotCoinsFuture.then((value) {
      setState(() {
        coins = value;
      });
    }).catchError((error) {
      debugPrint("Error fetching coins: $error");
    });
  }

  // 업비트 링크 열기 함수
  Future<void> _launchUpbit(String marketCode) async {
    // 업비트 웹 거래소 URL 규칙 적용
    final String upbitUrl = 'https://upbit.com/exchange?code=CRIX.UPBIT.$marketCode';
    final Uri url = Uri.parse(upbitUrl);

    try {
      if (await canLaunchUrl(url)) {
        // mode: LaunchMode.externalApplication 을 사용하면
        // 스마트폰에 업비트 앱이 설치되어 있을 경우 앱으로 연결될 확률이 높습니다.
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $upbitUrl');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildAdBanner(BuildContext context) {
    const String adUrl = 'http://www.naver.com';
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(adUrl))) {
          await launchUrl(Uri.parse(adUrl));
        }
      },
      child: Container(
        color: Colors.amberAccent,
        height: 100,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, color: Colors.blueAccent, size: 32),
            const SizedBox(width: 10),
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
        title: const Text('추천 종목 (Top 30)'),
        leading: const BackButton(),
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<List<HotCoin>>(
              future: hotCoinsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('에러: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('데이터가 없습니다.'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        '실시간 트렌드 마켓 (클릭 시 업비트로 이동)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: coins.length,
                        itemBuilder: (context, index) {
                          final coin = coins[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              title: Text(
                                coin.coinName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
                              // 항목 클릭 시 업비트 함수 호출
                              onTap: () {
                                _launchUpbit(coin.coinName);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildAdBanner(context),
        ],
      ),
    );
  }
}
