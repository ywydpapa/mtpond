import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'tradeset.dart';
import 'dart:convert';
import 'config/api_config.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // 추가
import 'hotcoins.dart';
import 'tradelogs.dart';
import 'setting.dart';
import 'margins.dart';
import 'losscut.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('앱 시작!');

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    print('Firebase 초기화 성공');
  } catch (e, stack) {
    print('Firebase 초기화 실패: $e\n$stack');
  }

  // FCM 백그라운드 핸들러 등록
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('FCM 백그라운드 핸들러 등록 완료');
  } catch (e, stack) {
    print('FCM 핸들러 등록 실패: $e\n$stack');
  }

  // HttpOverrides 설정
  try {
    HttpOverrides.global = MyHttpOverrides();
    print('HttpOverrides 설정 완료');
  } catch (e, stack) {
    print('HttpOverrides 설정 실패: $e\n$stack');
  }

  // FCM 권한 요청
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    print('FCM 권한 요청 완료: ${settings.authorizationStatus}');
  } catch (e, stack) {
    print('FCM 권한 요청 실패: $e\n$stack');
  }

  // 시스템 UI 스타일 설정
  try {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    print('System UI 스타일 설정 완료');
  } catch (e, stack) {
    print('System UI 스타일 설정 실패: $e\n$stack');
  }

  // 로컬 알림 초기화
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);
    print('로컬 알림 초기화 완료');
  } catch (e, stack) {
    print('로컬 알림 초기화 실패: $e\n$stack');
  }

  print('runApp 호출');
  runApp(MyApp());
}

void subscribeToTopics(String regionNo, String clubNo) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final regionTopic = 'region_$regionNo';
  final clubTopic = 'club_$clubNo';
  // 이전 클럽 토픽 구독 해제
  String? prevClubNo = prefs.getString('prevClubNo');
  if (prevClubNo != null && prevClubNo != clubNo) {
    await messaging.unsubscribeFromTopic('club_$prevClubNo');
  }
  // 새 클럽 토픽 구독
  await messaging.subscribeToTopic(clubTopic);
  await messaging.subscribeToTopic(regionTopic);
  // 새 클럽 토픽 저장
  await prefs.setString('prevClubNo', clubNo);
}

void unsubscribeAllTopics() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? prevClubNo = prefs.getString('prevClubNo');
  String? prevRegionNo = prefs.getString('prevRegionNo');
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (prevClubNo != null) {
    await messaging.unsubscribeFromTopic('club_$prevClubNo');
  }
  if (prevRegionNo != null) {
    await messaging.unsubscribeFromTopic('region_$prevRegionNo');
  }
  // 저장값 초기화
  await prefs.remove('prevClubNo');
  await prefs.remove('prevRegionNo');
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mountain Pond for Upbit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansKR',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/': (context) => HomeScreen(),
        '/setting': (context) => SettingPage(), // 예시: 트레이딩 설정목록
        '/tradelogs': (context) => TradeLogsPage(), // 지갑내역
        '/hotcoins': (context) => HotCoinsPage(), // 예시: 추천 종목
        '/tradeset': (context) => TradeSetPage(),
        '/margins': (context) => MarginsPage(), // 설정
        '/losscut': (context) => LosscutPage(), // 설정
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

  // 1. initState 추가: 앱이 켜질 때 자동 로그인 체크
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // 2. 자동 로그인 확인 함수
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? false;

    if (autoLoginEnabled) {
      final savedId = prefs.getString('saved_username');
      final savedPw = prefs.getString('saved_password');

      if (savedId != null && savedPw != null && savedId.isNotEmpty && savedPw.isNotEmpty) {
        // 저장된 정보가 있으면 텍스트 필드에 채우고 바로 로그인 실행
        _usernameController.text = savedId;
        _userpassController.text = savedPw;
        _login();
      }
    }
  }

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
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data.containsKey('userno')) {
          setState(() {
            _userNo = data['userno'].toString();
            _userName = data['username'].toString();
            _seccode = data['setupkey'].toString();
            _errorMessage = '';
          });

          // 3. 로그인 성공 시, 자동 로그인 설정이 켜져있다면 아이디/비밀번호 저장
          final prefs = await SharedPreferences.getInstance();
          final autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? false;
          if (autoLoginEnabled) {
            await prefs.setString('saved_username', phoneno);
            await prefs.setString('saved_password', userpass);
          }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Image.asset(
                'assets/mtPond.png',
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
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _userpassController,
                decoration: InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.text,
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkForFlexibleUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print('인앱 업데이트 체크 오류: $e');
    }
  }

  Future<void> _checkForFlexibleUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      print('인앱 업데이트 체크 오류: $e');
    }
  }

  // 공통 로그인 만료 처리 함수
  void _handleSessionExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인세션이 만료되었습니다. 다시 로그인해야 합니다.')),
    );
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? userNo = args?['userNo'];
    final String? userName = args?['userName'];
    final String? seccode = args?['seccode']; // 홈 화면에서 seccode 받기

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
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
                      height: 400,
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
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/tradeset',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                    'setKey': seccode, // 추가
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '트레이딩 설정',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/tradelogs',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                    'setKey': seccode,
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '나의 지갑 내역',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/margins',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                    'setKey': seccode, // 추가
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '미체결 주문목록',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                                    'setKey': seccode, // 추가
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '수익 현황',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              if (userNo != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/hotcoins',
                                  arguments: {
                                    'userNo': userNo,
                                    'userName': userName,
                                    'setKey': seccode, // 추가
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '추천 종목',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                                    'setKey': seccode, // 추가
                                  },
                                );
                              } else {
                                _handleSessionExpired();
                              }
                            },
                            child: Text(
                              '앱 설정',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
