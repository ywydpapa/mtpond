import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late String userNo;
  String? userName;
  bool loading = true;
  String? errorText;
  List<dynamic> setups = [];

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
      final resp = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (resp.statusCode != 200) {
        setState(() {
          loading = false;
          errorText = '서버 오류: ${resp.statusCode}';
        });
        return;
      }

      final decodedText = utf8.decode(resp.bodyBytes);
      final parsed = json.decode(decodedText);

      if (parsed is List) {
        setState(() {
          setups = parsed;
          loading = false;
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

  String _s(Map<String, dynamic> m, String k) => m[k]?.toString() ?? '';

  String _fmtNum(dynamic v, {int fraction = 2}) {
    if (v == null) return '';
    final n = double.tryParse(v.toString());
    if (n == null) return v.toString();
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(fraction);
  }

  Widget _kv(String k, String v) {
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('$k: $v'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (userName?.isNotEmpty ?? false)
        ? '트레이딩 설정 목록 - $userName'
        : '트레이딩 설정 목록';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _fetchSetups,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorText != null
            ? ListView(
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
        )
            : setups.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('등록된 설정이 없습니다.')),
          ],
        )
            : ListView.separated(
          itemCount: setups.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final s = setups[idx] as Map<String, dynamic>;

            final activeYN   = _s(s, 'activeYN');     // Y/N
            final initAmt    = _fmtNum(s['initAmt']);
            final addAmt     = _fmtNum(s['addAmt']);
            final limitAmt   = _fmtNum(s['limitAmt']);
            final minMargin  = _fmtNum(s['minMargin']);
            final maxMargin  = _fmtNum(s['maxMargin']);
            final tickRate   = _fmtNum(s['tickRate']);
            final tickYN     = _s(s, 'tickYN');       // Y/N
            final lcRate     = _fmtNum(s['lcRate']);
            final lcGap      = _fmtNum(s['lcGap']);
            final maxCoincnt = _fmtNum(s['maxCoincnt'], fraction: 0);
            final martinYN   = _s(s, 'martinYN');     // Y/N
            final stopYN     = _s(s, 'stopYN');       // Y/N
            final stopAutoYN = _s(s, 'stopAutoYN');   // Y/N

            return ListTile(
              title: Text(
                '설정 ${idx + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('활성화', activeYN),
                  _kv('초기투입금', initAmt),
                  _kv('추가투입금', addAmt),
                  _kv('최대투입한도', limitAmt),
                  _kv('최소마진', minMargin),
                  _kv('최대마진', maxMargin),
                  _kv('틱 비율', tickRate),
                  _kv('틱 사용', tickYN),
                  _kv('손절 비율', lcRate),
                  _kv('손절 갭', lcGap),
                  _kv('최대 보유코인 수', maxCoincnt),
                  _kv('마틴 사용', martinYN),
                  _kv('정지 사용', stopYN),
                  _kv('자동정지', stopAutoYN),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeYN.toUpperCase() == 'Y' ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activeYN.toUpperCase() == 'Y' ? '활성' : '비활성',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onTap: () {
                // 상세/수정 화면으로 이동이 필요하다면 여기서 arguments 전달
                // Navigator.pushNamed(context, '/settingDetail', arguments: {'userNo': userNo, 'index': idx, 'setting': s});
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSetups,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
