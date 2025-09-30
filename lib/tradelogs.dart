import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // <-- 숫자 포맷용 패키지 추가
import 'config/api_config.dart';

class TradeLogsPage extends StatefulWidget {
  const TradeLogsPage({super.key});

  @override
  State<TradeLogsPage> createState() => _TradeLogsPageState();
}

class _TradeLogsPageState extends State<TradeLogsPage> {
  int? userNo;
  List<dynamic> tradelogs = [];
  List<String> currencyList = [];
  String? selectedCurrency;
  bool isLoading = true;
  bool _isInit = false;

  final NumberFormat _numberFormat = NumberFormat('#,##0.##'); // 숫자 포맷

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      userNo = args?['userNo'] != null ? int.tryParse(args!['userNo'].toString()) : null;
      _isInit = true;
      if (userNo != null) {
        fetchTradeLogs();
      }
    }
  }

  Future<void> fetchTradeLogs() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('${ApiConf.baseUrl}/phapp/tradelog/$userNo');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final currencies = data.map((e) => e['currency'] as String).toSet().toList();
      setState(() {
        tradelogs = data;
        currencyList = currencies;
        selectedCurrency = currencies.isNotEmpty ? currencies[0] : null;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오지 못했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userNo == null) {
      return Scaffold(
        appBar: AppBar(title: Text('거래 내역')),
        body: Center(child: Text('userNo 정보가 없습니다.')),
      );
    }

    final filtered = selectedCurrency == null
        ? tradelogs
        : tradelogs.where((e) => e['currency'] == selectedCurrency).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('거래 내역'),
        leading: const BackButton(),
      ),
      backgroundColor: Colors.grey,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: selectedCurrency,
              hint: const Text('통화 선택'),
              items: currencyList
                  .map((cur) => DropdownMenuItem(
                value: cur,
                child: Text(cur),
              ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCurrency = val;
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1280, // DataTable의 최소 가로폭을 충분히 확보
                child: ListView(
                  children: [
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('changeType')),
                        DataColumn(label: Text('currency')),
                        DataColumn(label: Text('unitPrice'), numeric: true),
                        DataColumn(label: Text('inAmt'), numeric: true),
                        DataColumn(label: Text('outAmt'), numeric: true),
                        DataColumn(label: Text('remainAmt'), numeric: true),
                        DataColumn(label: Text('regDate')),
                      ],
                      rows: filtered.map((row) {
                        return DataRow(cells: [
                          DataCell(Text(row['changeType'].toString())),
                          DataCell(Text(row['currency'].toString())),
                          DataCell(Text(
                            row['unitPrice'] != null
                                ? _numberFormat.format(num.tryParse(row['unitPrice'].toString()) ?? 0)
                                : '',
                            textAlign: TextAlign.right, // 오른쪽 정렬
                          )),
                          DataCell(Text(
                            row['inAmt'] != null
                                ? _numberFormat.format(num.tryParse(row['inAmt'].toString()) ?? 0)
                                : '',
                            textAlign: TextAlign.right, // 오른쪽 정렬
                          )),
                          DataCell(Text(
                            row['outAmt'] != null
                                ? _numberFormat.format(num.tryParse(row['outAmt'].toString()) ?? 0)
                                : '',
                            textAlign: TextAlign.right, // 오른쪽 정렬
                          )),
                          DataCell(Text(
                            row['remainAmt'] != null
                                ? _numberFormat.format(num.tryParse(row['remainAmt'].toString()) ?? 0)
                                : '',
                            textAlign: TextAlign.right, // 오른쪽 정렬
                          )),
                          DataCell(Text(row['regDate'].toString())),
                        ]);
                      }).toList(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
