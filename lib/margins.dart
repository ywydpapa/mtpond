import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class MarginsPage extends StatefulWidget {
  const MarginsPage({Key? key}) : super(key: key);

  @override
  State<MarginsPage> createState() => _MarginsPageState();
}

class _MarginsPageState extends State<MarginsPage> {
  late String userNo;
  bool loading = true;
  String? errorText;
  List<dynamic> orders = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userNo = args?['userNo']?.toString() ?? '';
    if (userNo.isEmpty) {
      setState(() {
        loading = false;
        errorText = '유저 정보가 없습니다. 다시 로그인해 주세요.';
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

    final url = Uri.parse('${ApiConf.baseUrl}/api/myorders/$userNo');

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
      if (data is List) {
        setState(() {
          orders = data;
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

  String _fmtNum(dynamic v) {
    if (v == null) return '';
    final n = double.tryParse(v.toString());
    if (n == null) return v.toString();
    if (n < 1) return n.toStringAsFixed(6);
    if (n < 100) return n.toStringAsFixed(2);
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('미체결 주문 목록')),
      body: RefreshIndicator(
        onRefresh: _fetchMyOrders,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorText != null
            ? ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text(errorText!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _fetchMyOrders,
                child: const Text('다시 시도'),
              ),
            ),
          ],
        )
            : orders.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('표시할 주문이 없습니다.')),
          ],
        )
            : ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, idx) {
            final o = orders[idx] as Map<String, dynamic>;
            final side = o['side']?.toString() ?? '';
            final isAsk = side == 'ask';
            final market = o['market']?.toString() ?? '';
            final created = o['created_at']?.toString() ?? '';
            final price = _fmtNum(o['price']);
            final vol = o['volume']?.toString() ?? '';
            final ovalue = () {
              final p = double.tryParse(o['price']?.toString() ?? '');
              final v = double.tryParse(o['volume']?.toString() ?? '');
              if (p == null || v == null) return '';
              return (p * v).toStringAsFixed(0);
            }();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(market, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(created),
                    const SizedBox(height: 4),
                    Text('가격: $price / 수량: $vol / 금액: $ovalue'),
                  ],
                ),
                trailing: Text(
                  isAsk ? '매도' : '매수',
                  style: TextStyle(
                    color: isAsk ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchMyOrders,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
