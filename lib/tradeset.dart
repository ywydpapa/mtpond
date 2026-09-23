import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'package:intl/intl.dart';

class TradeSetPage extends StatefulWidget {
  const TradeSetPage({Key? key}) : super(key: key);

  @override
  State<TradeSetPage> createState() => _TradeSetPageState();
}

class _TradeSetPageState extends State<TradeSetPage> {
  late String userNo;
  String? userName;
  bool loading = true;
  String? errorText;
  Map<String, dynamic>? setup; // 단일 설정

  final _numFmt0 = NumberFormat.decimalPattern(); // 1,234
  final _numFmt2 = NumberFormat("#,##0.##");      // 1,234.56

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    userNo = args?['userNo']?.toString() ?? '';
    userName = args?['userName']?.toString();
    if (userNo.isEmpty) {
      setState(() {
        loading = false;
        errorText = '유저 정보가 없습니다. 다시 로그인해 주세요.';
      });
      return;
    }
    _fetchSetups();
  }

  Future<void> _fetchSetups() async {
    setState(() {
      loading = true;
      errorText = null;
    });

    final url = Uri.parse('${ApiConf.baseUrl}/api/mtpondsetup/$userNo');

    try {
      final resp = await http.get(url, headers: {'Accept': 'application/json'});

      if (resp.statusCode != 200) {
        setState(() {
          loading = false;
          errorText = '서버 오류: ${resp.statusCode}';
        });
        return;
      }

      final decodedText = utf8.decode(resp.bodyBytes);
      final parsed = json.decode(decodedText);

      if (parsed is List && parsed.isNotEmpty) {
        setState(() {
          setup = Map<String, dynamic>.from(parsed.first as Map);
          loading = false;
        });
      } else if (parsed is List && parsed.isEmpty) {
        setState(() {
          loading = false;
          errorText = '등록된 설정이 없습니다.';
        });
      } else {
        setState(() {
          loading = false;
          errorText = '데이터 형식이 올바르지 않습니다. (리스트 아님)';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorText = '네트워크 오류: $e';
      });
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _fmtMoney(dynamic v) {
    final d = _toDouble(v);
    if (d == null) return '';
    if (d == d.roundToDouble()) return _numFmt0.format(d);
    return _numFmt2.format(d);
  }

  bool _ynToBool(dynamic v) => (v?.toString().toUpperCase() == 'Y');
  String _boolToYN(bool b) => b ? 'Y' : 'N';

  void _toggleYN(String key, bool value) async {
    if (setup == null) return;

    // 1. 낙관적 업데이트 (UI를 먼저 변경하여 반응성을 높임)
    setState(() {
      setup![key] = _boolToYN(value);
    });

    // 2. '트레이딩 활성화(activeYN)' 버튼인 경우 백엔드 API 호출
    if (key == 'activeYN') {
      final activeStr = _boolToYN(value); // 'Y' 또는 'N'
      final url = Uri.parse('${ApiConf.baseUrl}/api/mtpondsetonoff/$userNo/$activeStr');

      try {
        final resp = await http.post(
          url,
          headers: {'Accept': 'application/json'},
        );

        if (resp.statusCode != 200) {
          throw Exception('업데이트 실패: ${resp.statusCode}');
        }

        // 응답이 정상(200)이면 성공 처리 (추가 작업 불필요)
        // final decodedText = utf8.decode(resp.bodyBytes);
        // final parsed = json.decode(decodedText);

      } catch (e) {
        // 3. API 호출 실패 시 원래 상태로 롤백
        setState(() {
          setup![key] = _boolToYN(!value);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('트레이딩 활성화 변경 실패: $e')),
          );
        }
      }
    } else {
      // TODO: 다른 스위치(tickYN, martinYN 등)를 위한 백엔드 업데이트 로직 추가
      // 예: 다른 설정들은 일괄 저장 API를 사용하거나 각각의 API를 호출
    }
  }


  Widget _rowLabelValue({
    required String label,
    required Widget value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }

  Widget _valueTextRight(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (userName?.isNotEmpty ?? false)
        ? '트레이딩 설정'
        : '트레이딩 설정';

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (errorText != null) {
      body = ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(errorText!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _fetchSetups,
              child: const Text('다시 시도'),
            ),
          ),
        ],
      );
    } else if (setup == null) {
      body = ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('설정 정보를 불러오지 못했습니다.')),
        ],
      );
    } else {
      body = ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('사용자: ${userName ?? userNo}', style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // 스위치 항목들
                _rowLabelValue(
                  label: '트레이딩 활성화',
                  value: Switch(
                    value: _ynToBool(setup!['activeYN']),
                    onChanged: (v) => _toggleYN('activeYN', v),
                  ),
                ),
                _rowLabelValue(
                  label: '틱계산 사용',
                  value: Switch(
                    value: _ynToBool(setup!['tickYN']),
                    onChanged: (v) => _toggleYN('tickYN', v),
                  ),
                ),
                _rowLabelValue(
                  label: '마틴 기법 사용',
                  value: Switch(
                    value: _ynToBool(setup!['martinYN']),
                    onChanged: (v) => _toggleYN('martinYN', v),
                  ),
                ),
                _rowLabelValue(
                  label: '자동 손절 사용',
                  value: Switch(
                    value: _ynToBool(setup!['stopYN']),
                    onChanged: (v) => _toggleYN('stopYN', v),
                  ),
                ),
                _rowLabelValue(
                  label: '거래자동정지',
                  value: Switch(
                    value: _ynToBool(setup!['stopAutoYN']),
                    onChanged: (v) => _toggleYN('stopAutoYN', v),
                  ),
                ),

                const Divider(height: 1),

                // 금액/숫자 항목들
                _rowLabelValue(
                  label: '초기투입금',
                  value: _valueTextRight(_fmtMoney(setup!['initAmt'])),
                ),
                _rowLabelValue(
                  label: '추가투입금',
                  value: _valueTextRight(_fmtMoney(setup!['addAmt'])),
                ),
                _rowLabelValue(
                  label: '최대투입한도',
                  value: _valueTextRight(_fmtMoney(setup!['limitAmt'])),
                ),
                _rowLabelValue(
                  label: '최소마진',
                  value: _valueTextRight(_fmtMoney(setup!['minMargin'])),
                ),
                _rowLabelValue(
                  label: '최대마진',
                  value: _valueTextRight(_fmtMoney(setup!['maxMargin'])),
                ),
                _rowLabelValue(
                  label: '틱 비율',
                  value: _valueTextRight(_fmtMoney(setup!['tickRate'])),
                ),
                _rowLabelValue(
                  label: '손절 비율',
                  value: _valueTextRight(_fmtMoney(setup!['lcRate'])),
                ),
                _rowLabelValue(
                  label: '손절 갭',
                  value: _valueTextRight(_fmtMoney(setup!['lcGap'])),
                ),
                _rowLabelValue(
                  label: '최대 보유코인 수',
                  value: _valueTextRight(_fmtMoney(setup!['maxCoincnt'])),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(onRefresh: _fetchSetups, child: body),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSetups,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
