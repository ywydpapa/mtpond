import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'config/api_config.dart';

class TradeLogsPage extends StatefulWidget {
  const TradeLogsPage({super.key});

  @override
  State<TradeLogsPage> createState() => _TradeLogsPageState();
}

class _TradeLogsPageState extends State<TradeLogsPage> {
  int? userNo;
  String? setKey;

  List<dynamic> myCoins = [];
  // 현재가 데이터를 쉽게 찾기 위해 Map으로 변환해서 저장할 변수
  Map<String, double> cuPricesMap = {};

  bool isLoading = true;
  bool _isInit = false;
  String? errorText;

  // 숫자 포맷 (금액용, 소수점 2자리)
  final NumberFormat _moneyFormat = NumberFormat('#,##0.##');
  // 퍼센트 포맷 (수익률용)
  final NumberFormat _percentFormat = NumberFormat("+#,##0.00%;-#,##0.00%");

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      userNo = args?['userNo'] != null ? int.tryParse(args!['userNo'].toString()) : null;
      setKey = args?['setKey']?.toString();

      _isInit = true;
      if (userNo != null && setKey != null) {
        _fetchWalletData();
      } else {
        setState(() {
          isLoading = false;
          errorText = '사용자 정보(userNo, setKey)가 없습니다.';
        });
      }
    }
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    final url = Uri.parse('${ApiConf.baseUrl}/api/balance/$userNo/$setKey');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));

        if (decodedData['success'] == true) {
          // 1. 내 코인 리스트 저장
          final List<dynamic> coins = decodedData['mycoins'] ?? [];

          // 2. 현재가 리스트를 Map<String, double> 형태로 변환하여 검색을 빠르게 만듦
          // 예: [{"market":"KRW-XRP","trade_price":2137.0}] -> {"KRW-XRP": 2137.0}
          final List<dynamic> pricesList = decodedData['cuprices'] ?? [];
          final Map<String, double> tempPriceMap = {};
          for (var item in pricesList) {
            final String market = item['market']?.toString() ?? '';
            final double price = _toDouble(item['trade_price']);
            if (market.isNotEmpty) {
              tempPriceMap[market] = price;
            }
          }

          setState(() {
            myCoins = coins;
            cuPricesMap = tempPriceMap;
            isLoading = false;
          });
        } else {
          setState(() {
            errorText = '데이터를 불러오지 못했습니다.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorText = '서버 오류: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorText = '네트워크 오류: $e';
        isLoading = false;
      });
    }
  }

  // 데이터 타입 변환 헬퍼 함수 (String으로 오는 숫자도 안전하게 변환)
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('내 지갑 및 수익률'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (userNo != null && setKey != null) ? _fetchWalletData : null,
          )
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchWalletData,
              child: const Text('다시 시도'),
            )
          ],
        ),
      );
    }

    if (myCoins.isEmpty) {
      return const Center(child: Text('보유 중인 자산이 없습니다.', style: TextStyle(fontSize: 16)));
    }

    return RefreshIndicator(
      onRefresh: _fetchWalletData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: myCoins.length,
        itemBuilder: (context, index) {
          final coinData = myCoins[index];

          final String currency = coinData['currency']?.toString() ?? 'UNKNOWN';

          // 보유 수량 = balance + locked (사용 가능 수량 + 주문 묶인 수량)
          final double balance = _toDouble(coinData['balance']);
          final double locked = _toDouble(coinData['locked']);
          final double totalAmount = balance + locked;

          final double avgBuyPrice = _toDouble(coinData['avg_buy_price']);

          // 원화(KRW)인 경우 수익률 계산을 생략하고 잔고만 표시
          if (currency == 'KRW') {
            return _buildKrwCard(totalAmount);
          }

          // 현재가 매칭 (예: currency가 'ETH'면 'KRW-ETH'로 검색)
          final String marketSymbol = 'KRW-$currency';
          final double currentPrice = cuPricesMap[marketSymbol] ?? 0.0;

          // 계산 로직
          final double totalBuyAmount = totalAmount * avgBuyPrice; // 총 매수 금액
          final double totalEvalAmount = totalAmount * currentPrice; // 총 평가 금액
          final double profitAmount = totalEvalAmount - totalBuyAmount; // 평가 손익

          double profitRate = 0.0; // 수익률 (%)
          if (avgBuyPrice > 0) {
            profitRate = ((currentPrice - avgBuyPrice) / avgBuyPrice);
          }

          // 색상 결정 (수익: 빨강, 손실: 파랑)
          Color priceColor = Colors.black;
          if (profitRate > 0) {
            priceColor = Colors.red;
          } else if (profitRate < 0) {
            priceColor = Colors.blue;
          }

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marketSymbol,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('보유수량', '${_moneyFormat.format(totalAmount)} 개'),
                  const SizedBox(height: 8),
                  _buildInfoRow('매수평균가', '${_moneyFormat.format(avgBuyPrice)} 원'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      '현재가',
                      '${_moneyFormat.format(currentPrice)} 원',
                      valueColor: priceColor,
                      isBold: true
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      '평가손익 / 수익률',
                      '${_moneyFormat.format(profitAmount)} 원 (${_percentFormat.format(profitRate)})',
                      valueColor: priceColor,
                      isBold: true
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 원화(KRW) 표시용 특별 카드
  Widget _buildKrwCard(double amount) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50], // 원화 카드는 색상을 살짝 다르게
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보유 원화 (KRW)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const Divider(height: 24),
            _buildInfoRow('총 보유금액', '${_moneyFormat.format(amount)} 원', isBold: true),
          ],
        ),
      ),
    );
  }

  // 행을 그리는 헬퍼 위젯
  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.black87 : Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            )
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 14,
          ),
        ),
      ],
    );
  }
}
