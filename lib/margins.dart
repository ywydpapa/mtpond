import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'config/api_config.dart';

class MarginsPage extends StatefulWidget {
  const MarginsPage({Key? key}) : super(key: key);

  @override
  State<MarginsPage> createState() => _MarginsPageState();
}

class _MarginsPageState extends State<MarginsPage> {
  late String userNo;
  String? setKey;

  bool loading = true;
  String? errorText;

  List<dynamic> orders = [];
  Map<String, double> cuPricesMap = {}; // 현재가를 저장할 Map

  final NumberFormat _moneyFormat = NumberFormat('#,##0.##');
  final NumberFormat _percentFormat = NumberFormat("+#,##0.00%;-#,##0.00%");

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userNo = args?['userNo']?.toString() ?? '';
    setKey = args?['setKey']?.toString(); // main.dart에서 넘겨준 setKey 받기

    if (userNo.isEmpty || setKey == null) {
      setState(() {
        loading = false;
        errorText = '유저 정보(또는 인증키)가 없습니다. 다시 로그인해 주세요.';
      });
      return;
    }
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    setState(() {
      loading = true;
      errorText = null;
    });

    // API 주소에 setKey 추가
    final url = Uri.parse('${ApiConf.baseUrl}/api/myorders/$userNo/$setKey');

    try {
      final resp = await http.post(url, headers: {
        'Content-Type': 'application/json',
      });
      if (resp.statusCode != 200) {
        setState(() {
          loading = false;
          errorText = '서버 오류: ${resp.statusCode}';
        });
        return;
      }

      final decoded = json.decode(utf8.decode(resp.bodyBytes));
      final success = decoded['success'] == true;
      if (!success) {
        setState(() {
          loading = false;
          errorText = decoded['message']?.toString() ?? '요청 실패';
        });
        return;
      }

      final data = decoded['data'];
      final cprices = decoded['cprices'] ?? [];

      // 현재가 리스트를 Map으로 변환 (빠른 검색을 위해)
      final Map<String, double> tempPriceMap = {};
      for (var item in cprices) {
        final String market = item['market']?.toString() ?? '';
        final double price = double.tryParse(item['trade_price']?.toString() ?? '0') ?? 0.0;
        if (market.isNotEmpty) {
          tempPriceMap[market] = price;
        }
      }

      if (data is List) {
        setState(() {
          orders = data;
          cuPricesMap = tempPriceMap;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorText = '데이터 형식이 올바르지 않습니다.';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorText = '네트워크 오류: $e';
      });
    }
  }

  // 소수점 처리를 위한 헬퍼 함수
  String _fmtNum(dynamic v) {
    if (v == null) return '';
    final n = double.tryParse(v.toString());
    if (n == null) return v.toString();
    if (n < 1) return n.toStringAsFixed(6); // 소수점이 긴 코인(예: 도지, 시바견 등)
    if (n < 100) return n.toStringAsFixed(2);
    return _moneyFormat.format(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('미체결 주문 목록'),
        leading: const BackButton(),
      ),
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: _fetchMyOrders,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchMyOrders,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorText != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 16))),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _fetchMyOrders,
              child: const Text('다시 시도'),
            ),
          ),
        ],
      );
    }
    if (orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('미체결된 주문이 없습니다.', style: TextStyle(fontSize: 16))),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, idx) {
        final o = orders[idx] as Map<String, dynamic>;

        final market = o['market']?.toString() ?? '';
        final side = o['side']?.toString() ?? '';
        final isAsk = (side == 'ask'); // ask = 매도, bid = 매수
        final created = o['created_at']?.toString() ?? '';

        // 가격 및 수량 파싱
        final double orderPrice = double.tryParse(o['price']?.toString() ?? '0') ?? 0.0;
        final double volume = double.tryParse(o['volume']?.toString() ?? '0') ?? 0.0;
        final double orderValue = orderPrice * volume;

        // 현재가 가져오기
        final double currentPrice = cuPricesMap[market] ?? 0.0;

        // 체결까지 남은 퍼센트(차이) 계산
        // 공식: ((주문가 - 현재가) / 현재가) * 100
        // - 매도(Ask)일 경우: 현재가보다 높게 주문하므로 보통 +% (현재가가 이만큼 올라야 체결됨)
        // - 매수(Bid)일 경우: 현재가보다 낮게 주문하므로 보통 -% (현재가가 이만큼 내려야 체결됨)
        double gapPercent = 0.0;
        if (currentPrice > 0) {
          gapPercent = ((orderPrice - currentPrice) / currentPrice);
        }

        // 색상 설정 (한국 업비트 기준: 매수=빨강, 매도=파랑)
        final Color typeColor = isAsk ? Colors.blue : Colors.red;
        final String typeText = isAsk ? '매도' : '매수';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 마켓명 & 매수/매도 타입
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      market,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor),
                      ),
                      child: Text(
                        typeText,
                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '주문일시: ${created.replaceAll('T', ' ').split('+').first}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Divider(height: 24),

                // 정보 행
                _buildInfoRow('주문 가격', '${_fmtNum(orderPrice)} 원', isBold: true),
                const SizedBox(height: 8),
                _buildInfoRow('현재 가격', '${_fmtNum(currentPrice)} 원', valueColor: Colors.black54),
                const SizedBox(height: 8),

                // 체결까지 남은 차이 (%)
                _buildInfoRow(
                    '체결까지 차이',
                    _percentFormat.format(gapPercent),
                    valueColor: gapPercent > 0 ? Colors.red : Colors.blue,
                    isBold: true
                ),
                const SizedBox(height: 8),

                _buildInfoRow('주문 수량', '${_fmtNum(volume)} 개'),
                const SizedBox(height: 8),
                _buildInfoRow('총 주문금액', '${_moneyFormat.format(orderValue)} 원'),
              ],
            ),
          ),
        );
      },
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
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
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
