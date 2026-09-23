import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _key1Controller = TextEditingController();
  final TextEditingController _key2Controller = TextEditingController();

  bool _notificationEnabled = false;
  bool _autoLoginEnabled = false; // 자동 로그인 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _key1Controller.text = prefs.getString('upbit_access_key') ?? '';
      _key2Controller.text = prefs.getString('upbit_secret_key') ?? '';
      _notificationEnabled = prefs.getBool('notification_enabled') ?? false;
      _autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? false; // 자동 로그인 설정 불러오기
    });
  }

  Future<void> _saveUpbitKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('upbit_access_key', _key1Controller.text);
    await prefs.setString('upbit_secret_key', _key2Controller.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upbit API 키가 저장되었습니다.')),
      );
    }
  }

  Future<void> _saveNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
  }

  // 자동 로그인 설정 저장 함수
  Future<void> _saveAutoLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login_enabled', value);

    // 자동 로그인을 끄면 저장되어 있던 아이디와 비밀번호 정보도 삭제합니다.
    if (!value) {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('암호 변경'),
        content: const Text('암호 변경 기능을 구현하세요.'),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _key1Controller.dispose();
    _key2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('설정'),
        leading: const BackButton(),
      ),
      backgroundColor: Colors.blueAccent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Upbit API Key 입력 영역
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upbit API Key', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _key1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Access Key',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _key2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Secret Key',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveUpbitKeys,
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 자동 로그인 설정 영역 (추가됨)
            Card(
              child: SwitchListTile(
                title: const Text('자동 로그인'),
                subtitle: const Text('앱 실행 시 자동으로 로그인합니다.'),
                value: _autoLoginEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoLoginEnabled = value;
                  });
                  _saveAutoLogin(value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // 암호 변경 영역
            Card(
              child: ListTile(
                title: const Text('암호 변경'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _changePassword,
              ),
            ),
            const SizedBox(height: 16),

            // 알림 설정 영역
            Card(
              child: SwitchListTile(
                title: const Text('알림 설정'),
                value: _notificationEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationEnabled = value;
                  });
                  _saveNotification(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
