import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 광고 클릭시 링크 이동용
import 'config/api_config.dart';

class HotCoin {
  final String dateTag;
  final String coinName;
  final int bidAmt;
  final int askAmt;
  final int totalAmt;
  final double amtDiff;

  HotCoin({
    required this.dateTag,
    required this.coinName,
    required this.bidAmt,
    required this.askAmt,
    required this.totalAmt,
    required this.amtDiff,
  });

  factory HotCoin.fromJson(Map<String, dynamic> json) {
    return HotCoin(
      dateTag: json['dateTag'] as String,
      coinName: json['coinName'] as String,
      bidAmt: json['bidAmt'] is int
          ? json['bidAmt']
          : int.tryParse(json['bidAmt'].toString()) ?? 0,
      askAmt: json['askAmt'] is int
          ? json['askAmt']
          : int.tryParse(json['askAmt'].toString()) ?? 0,
      totalAmt: json['totalAmt'] is int
          ? json['totalAmt']
          : int.tryParse(json['totalAmt'].toString()) ?? 0,
      amtDiff: json['amtDiff'] is double
          ? json['amtDiff']
          : double.tryParse(json['amtDiff'].toString()) ?? 0.0,
    );
  }
}

String formatDatetag(String datetag) {
  return "${datetag.substring(0, 4)}-${datetag.substring(4, 6)}-${datetag.substring(6, 8)} "
      "${datetag.substring(8, 10)}:${datetag.substring(10, 12)}:${datetag.substring(12, 14)}";
}

Future<List<HotCoin>> fetchHotCoins() async {
  final response = await http.get(
    Uri.parse('${ApiConf.baseUrl}/phapp/hotcoinlist'),
  );
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => HotCoin.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load hot coins');
  }
}

class HotCoinsPage extends StatefulWidget {
  const HotCoinsPage({super.key});

  @override
  State<HotCoinsPage> createState() => _HotCoinsPageState();
}

class _HotCoinsPageState extends State<HotCoinsPage> {
  late Future<List<HotCoin>> hotCoinsFuture;
  final NumberFormat numberFormat = NumberFormat('#,###');

  List<HotCoin> coins = [];
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    hotCoinsFuture = fetchHotCoins();
    hotCoinsFuture.then((value) {
      setState(() {
        coins = value;
      });
    });
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
      switch (columnIndex) {
        case 0:
          coins.sort(
                (a, b) =>
            ascending
                ? a.coinName.compareTo(b.coinName)
                : b.coinName.compareTo(a.coinName),
          );
          break;
        case 1:
          coins.sort(
                (a, b) =>
            ascending
                ? a.bidAmt.compareTo(b.bidAmt)
                : b.bidAmt.compareTo(a.bidAmt),
          );
          break;
        case 2:
          coins.sort(
                (a, b) =>
            ascending
                ? a.askAmt.compareTo(b.askAmt)
                : b.askAmt.compareTo(a.askAmt),
          );
          break;
        case 3:
          coins.sort(
                (a, b) =>
            ascending
                ? a.totalAmt.compareTo(b.totalAmt)
                : b.totalAmt.compareTo(a.totalAmt),
          );
          break;
        case 4:
          coins.sort(
                (a, b) =>
            ascending
                ? a.amtDiff.compareTo(b.amtDiff)
                : b.amtDiff.compareTo(a.amtDiff),
          );
          break;
      }
    });
  }

  // 광고 배너 위젯
  Widget _buildAdBanner(BuildContext context) {
    const String adUrl = 'http://www.naver.com'; // 광고 클릭시 이동할 링크
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
            Icon(Icons.campaign, color: Colors.blueAccent, size: 32),
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
        title: const Text('추천 종목'),
        leading: const BackButton(),
      ),
      backgroundColor: Colors.grey,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 표시 및 테이블
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

                String formattedDate = '';
                if (coins.isNotEmpty) {
                  formattedDate = formatDatetag(coins[0].dateTag);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formattedDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '수집 시각: $formattedDate',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            sortColumnIndex: sortColumnIndex,
                            sortAscending: sortAscending,
                            columns: [
                              DataColumn(
                                label: const Text('종목'),
                                onSort: (i, asc) => onSort(i, asc),
                              ),
                              DataColumn(
                                label: const Text('매수'),
                                numeric: true,
                                onSort: (i, asc) => onSort(i, asc),
                              ),
                              DataColumn(
                                label: const Text('매도'),
                                numeric: true,
                                onSort: (i, asc) => onSort(i, asc),
                              ),
                              DataColumn(
                                label: const Text('총액'),
                                numeric: true,
                                onSort: (i, asc) => onSort(i, asc),
                              ),
                              DataColumn(
                                label: const Text('차이(%)'),
                                numeric: true,
                                onSort: (i, asc) => onSort(i, asc),
                              ),
                            ],
                            rows: coins.map((coin) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(coin.coinName)),
                                  DataCell(Text(numberFormat.format(coin.bidAmt))),
                                  DataCell(Text(numberFormat.format(coin.askAmt))),
                                  DataCell(Text(numberFormat.format(coin.totalAmt))),
                                  DataCell(Text(coin.amtDiff.toStringAsFixed(2))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 광고 배너
          _buildAdBanner(context),
        ],
      ),
    );
  }
}
