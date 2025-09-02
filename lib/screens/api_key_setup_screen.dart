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

  Future<void> _validateAndSave() async {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'API 키를 입력해주세요';
      });
      return;
    }
    
    // API 키 형식 기본 검증
    if (!apiKey.startsWith('AIza') || apiKey.length < 30) {
      setState(() {
        _errorMessage = 'YouTube API 키 형식이 올바르지 않습니다 (AIza로 시작해야 함)';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final service = YouTubeService(apiKey: apiKey);
      final isValid = await service.validateApiKey();

      if (!mounted) return;

      if (isValid) {
        await StorageService.saveApiKey(apiKey);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PinSetupScreen(apiKey: apiKey)),
        );
      } else {
        setState(() {
          _isValidating = false;
          _errorMessage = 'API 키가 유효하지 않거나 YouTube Data API v3가 활성화되지 않았습니다';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = 'API 키 검증 중 오류가 발생했습니다: ${e.toString()}';
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'API 키 발급 방법',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Google Cloud Console에 로그인\n'
                    '2. 프로젝트 선택 또는 생성\n'
                    '3. API 및 서비스 > YouTube Data API v3 활성화\n'
                    '4. 사용자 인증 정보 > API 키 생성',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}