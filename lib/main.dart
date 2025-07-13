import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mtpond/tradeset.dart';
import 'dart:convert';
import 'config/api_config.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // 추가
import 'hotcoins.dart';
import 'tradelogs.dart';
import 'hotcoins.dart';
import 'setting.dart';
import 'margins.dart';
import 'losscut.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides(); //테스트용 우회 설정

  // 시스템 바를 투명하게 만들고 아이콘 색상을 지정 (edge-to-edge 대응)
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mountain Pond for Upbit',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'NotoSansKR',),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/': (context) => HomeScreen(),
        '/setting': (context) => SettingPage(),     // 예시: 트레이딩 설정목록
        '/tradelogs': (context) => TradeLogsPage(),// 예시: 거래 내역
        '/hotcoins': (context) => HotCoinsPage(),      // 예시: 추천 종목
        '/tradeset': (context) => TradesetPage(),
        '/margins': (context) => MarginsPage(),      // 설정
        '/losscut': (context) => LosscutPage(),      // 설정// 설정
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userpassController = TextEditingController();
  String _errorMessage = '';
  String _userNo = '';
  String _userName = '';
  String _seccode = '';

  Future<void> _login() async {
    final phoneno = _usernameController.text;
    final userpass = _userpassController.text;

    if (phoneno.isEmpty) {
      setState(() {
        _errorMessage = '로그인 아이디를 입력하세요.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConf.baseUrl}/phapp/mlogin/$phoneno/$userpass'),
      );

      if (response.statusCode == 200) {
        // 1. response.bodyBytes를 사용해서 UTF-8로 직접 디코딩
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data.containsKey('userno')) {
          setState(() {
            _userNo = data['userno'].toString();
            _userName = data['username'].toString();
            _seccode = data['setupkey'].toString();
            _errorMessage = '';
          });

          Navigator.pushReplacementNamed(
            context,
            '/',
            arguments: {
              'userNo': _userNo,
              'userName': _userName,
              'seccode': _seccode,
            },
          );
        } else if (data.containsKey('error')) {
          setState(() {
            _errorMessage = data['error'];
          });
        } else {
          setState(() {
            _errorMessage = '자신의 아이디와 암호로 로그인해 주세요.';
          });
        }
      } else {
        setState(() {
          _errorMessage = '서버 오류 (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Mt. CoinPond for Upbit'),
      ),
      backgroundColor: Colors.blueAccent,
      body: SafeArea( // <-- SafeArea로 감싸기
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Image.asset(
                'assets/default.png',
                width: 300,
                height: 300,
              ),
              SizedBox(height: 28),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '등록된 아이디/전화번호',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _userpassController,
                decoration: InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // <-- 추가!
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 8),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _login, child: Text('로그인')),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? userNo = args?['userNo'];
    final String? userName = args?['userName'];
    final String? seccode = args?['seccode'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          (userNo != null && (userName?.isNotEmpty ?? false))
              ? '$userName 로그인 중'
              : '로그인 만료',
        ),
      ),
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/default.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo != null){
                                Navigator.pushNamed(
                                  context,
                                  '/tradeset',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('트레이딩 설정목록', maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo != null){
                                Navigator.pushNamed(
                                  context,
                                  '/tradelogs',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('거래 내역',maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo!= null){
                                Navigator.pushNamed(
                                  context,
                                  '/margins',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('수익 현황', maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/losscut',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('손절 현황',maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo!= null){
                                Navigator.pushNamed(
                                  context,
                                  '/hotcoins',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('추천 종목', maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/setting',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
                                );
                                Future.delayed(Duration(seconds: 2), () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                });
                              }
                            },
                            child: Text('설정',maxLines:1,overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
