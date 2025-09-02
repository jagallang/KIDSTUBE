import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';
import 'background_refresh_settings_screen.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _apiKeyController = TextEditingController();
  String? _savedApiKey;
  bool _isLoading = true;
  bool _isValidating = false;
  bool? _isValidKey;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedApiKey() async {
    final apiKey = await StorageService.getApiKey();
    if (mounted) {
      setState(() {
        _savedApiKey = apiKey;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSnackBar('API 키를 입력해주세요', isError: true);
      return;
    }

    setState(() {
      _isValidating = true;
      _isValidKey = null;
    });

    // API 키 유효성 검증
    final youtubeService = YouTubeService(apiKey: apiKey);
    final isValid = await youtubeService.validateApiKey();

    if (mounted) {
      setState(() {
        _isValidating = false;
        _isValidKey = isValid;
      });

      if (isValid) {
        await StorageService.saveApiKey(apiKey);
        await _loadSavedApiKey();
        _apiKeyController.clear();
        _showSnackBar('API 키가 저장되었습니다', isError: false);
      } else {
        _showSnackBar(
          'API 키 검증 실패:\n'
          '• API 할당량 초과 가능성 (일일 10,000 단위)\n'
          '• YouTube Data API v3 활성화 확인\n'
          '• API 키 권한 설정 확인\n'
          '• 내일 다시 시도하거나 "TEST_API_KEY" 사용',
          isError: true
        );
      }
    }
  }

  Future<void> _copyApiKey() async {
    if (_savedApiKey != null) {
      await Clipboard.setData(ClipboardData(text: _savedApiKey!));
      _showSnackBar('API 키가 클립보드에 복사되었습니다', isError: false);
    }
  }

  Future<void> _copyToInput() async {
    if (_savedApiKey != null) {
      _apiKeyController.text = _savedApiKey!;
      _showSnackBar('저장된 API 키를 입력창에 불러왔습니다', isError: false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3), // 오류 메시지는 더 오래 표시
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'YouTube Data API 키 입력',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API 키',
                hintText: 'AIza... 형식의 API 키를 입력하세요',
                border: const OutlineInputBorder(),
                suffixIcon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _isValidKey != null
                        ? Icon(
                            _isValidKey! ? Icons.check_circle : Icons.error,
                            color: _isValidKey! ? Colors.green : Colors.red,
                          )
                        : null,
                prefixIcon: const Icon(Icons.key),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isValidating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('검증 중...'),
                            ],
                          )
                        : const Text('API 키 저장'),
                  ),
                ),
                if (_savedApiKey != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _copyToInput,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('불러오기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedApiKey() {
    if (_savedApiKey == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.key_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                '저장된 API 키가 없습니다',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // API 키를 마스킹 처리 (앞 8자리, 뒤 4자리만 보이고 나머지는 * 처리)
    String maskedKey = _savedApiKey!;
    if (maskedKey.length > 12) {
      final start = maskedKey.substring(0, 8);
      final end = maskedKey.substring(maskedKey.length - 4);
      final middle = '*' * (maskedKey.length - 12);
      maskedKey = '$start$middle$end';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '저장된 API 키',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                maskedKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyApiKey,
                    icon: const Icon(Icons.copy),
                    label: const Text('복사'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyToInput,
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('API 설정'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('API 설정'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도움말 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'YouTube Data API 키 설정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '실제 YouTube 영상을 불러오려면 YouTube Data API 키가 필요합니다.\n'
                    'Google Cloud Console에서 API 키를 발급받아 입력해주세요.\n\n'
                    '⚠️ API 할당량: 일일 10,000 단위 (무료)\n'
                    '• 검색 API: 100 단위/호출\n'
                    '• 채널 API: 1 단위/호출\n\n'
                    '💡 할당량 초과시 "TEST_API_KEY" 사용 또는 내일 재시도',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // API 키 입력 섹션
            _buildApiKeyInput(),

            const SizedBox(height: 24),

            // 저장된 API 키 섹션
            _buildSavedApiKey(),
            
            const SizedBox(height: 24),
            
            // 백그라운드 새로고침 설정 버튼
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text('백그라운드 새로고침 설정'),
                subtitle: const Text('API 사용량 관리 및 자동 새로고침 설정'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackgroundRefreshSettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}