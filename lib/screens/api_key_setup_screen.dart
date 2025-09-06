import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import 'pin_setup_screen.dart';

class ApiKeySetupScreen extends StatefulWidget {
  const ApiKeySetupScreen({Key? key}) : super(key: key);

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final _controller = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  bool _isValidApiKeyFormat(String apiKey) {
    // YouTube API 키는 보통 'AIza'로 시작하고 39자리
    return apiKey.startsWith('AIza') && apiKey.length == 39;
  }

  Future<void> _validateAndSave() async {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'API 키를 입력해주세요';
      });
      return;
    }

    // API 키 형식 검증
    if (!_isValidApiKeyFormat(apiKey)) {
      setState(() {
        _errorMessage = '올바르지 않은 API 키 형식입니다\n(AIza로 시작하는 39자리여야 합니다)';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final service = YouTubeService(apiKey: apiKey);
      final validationResult = await service.validateApiKey();

      if (!mounted) return;

      if (validationResult['isValid']) {
        await StorageService.saveApiKey(apiKey);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PinSetupScreen(apiKey: apiKey)),
        );
      } else {
        setState(() {
          _isValidating = false;
          _errorMessage = validationResult['message'] ?? '유효하지 않은 API 키입니다';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = '네트워크 오류가 발생했습니다.\n인터넷 연결을 확인해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KidsTube API 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.key,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 30),
            const Text(
              'KidsTube API 키 입력',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Google Cloud Console에서 발급받은\nYouTube Data API v3 키를 입력해주세요',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              enabled: !_isValidating,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                const url = 'https://console.cloud.google.com';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Google Cloud Console에서 API 키 발급받기'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isValidating ? null : _validateAndSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isValidating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('다음', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                // 테스트용 더미 API 키 저장
                await StorageService.saveApiKey('TEST_API_KEY');
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PinSetupScreen(apiKey: 'TEST_API_KEY')),
                );
              },
              child: const Text('테스트 모드로 시작 (API 키 없이)', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}