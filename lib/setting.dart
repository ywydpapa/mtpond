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
    });
  }

  Future<void> _saveUpbitKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('upbit_access_key', _key1Controller.text);
    await prefs.setString('upbit_secret_key', _key2Controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upbit API 키가 저장되었습니다.')),
    );
  }

  Future<void> _saveNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('암호 변경'),
        content: Text('암호 변경 기능을 구현하세요.'),
        actions: [
          TextButton(
            child: Text('닫기'),
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
        leading: BackButton(),
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
                    Text('Upbit API Key', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _key1Controller,
                      decoration: InputDecoration(
                        labelText: 'Access Key',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _key2Controller,
                      decoration: InputDecoration(
                        labelText: 'Secret Key',
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveUpbitKeys,
                        child: Text('저장'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // 암호 변경 영역
            Card(
              child: ListTile(
                title: Text('암호 변경'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _changePassword,
              ),
            ),
            SizedBox(height: 16),
            // 알림 설정 영역
            Card(
              child: SwitchListTile(
                title: Text('알림 설정'),
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
