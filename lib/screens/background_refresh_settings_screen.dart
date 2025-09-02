import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/service_locator.dart';
import '../core/background_refresh_manager.dart';
import '../core/api_usage_tracker.dart';

class BackgroundRefreshSettingsScreen extends StatefulWidget {
  const BackgroundRefreshSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BackgroundRefreshSettingsScreen> createState() => _BackgroundRefreshSettingsScreenState();
}

class _BackgroundRefreshSettingsScreenState extends State<BackgroundRefreshSettingsScreen> {
  bool _isBackgroundRefreshEnabled = false;
  late BackgroundRefreshManager _backgroundRefreshManager;
  Map<String, dynamic> _apiUsageStats = {};

  @override
  void initState() {
    super.initState();
    _backgroundRefreshManager = getService<BackgroundRefreshManager>();
    _loadSettings();
    _loadApiUsageStats();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBackgroundRefreshEnabled = prefs.getBool('background_refresh_enabled') ?? false;
    });
  }

  Future<void> _loadApiUsageStats() async {
    final stats = await ApiUsageTracker.getUsageStats();
    setState(() {
      _apiUsageStats = stats;
    });
  }

  Future<void> _toggleBackgroundRefresh(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_refresh_enabled', value);
    
    setState(() {
      _isBackgroundRefreshEnabled = value;
    });

    if (value) {
      _backgroundRefreshManager.startBackgroundRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('백그라운드 새로고침이 활성화되었습니다')),
      );
    } else {
      _backgroundRefreshManager.stopBackgroundRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('백그라운드 새로고침이 비활성화되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백그라운드 새로고침 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API 사용량 카드
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API 사용량',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_apiUsageStats.isNotEmpty) ...[
                    LinearProgressIndicator(
                      value: (_apiUsageStats['current'] ?? 0) / (_apiUsageStats['limit'] ?? 1),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _apiUsageStats['percentage'] > 80 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_apiUsageStats['current']} / ${_apiUsageStats['limit']} units (${_apiUsageStats['percentage']}%)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '남은 사용량: ${_apiUsageStats['remaining']} units',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 백그라운드 새로고침 설정
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '백그라운드 새로고침',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('자동 새로고침 활성화'),
                    subtitle: const Text(
                      '30분마다 자동으로 영상을 새로고침합니다.\n⚠️ API 사용량이 증가합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isBackgroundRefreshEnabled,
                    onChanged: _toggleBackgroundRefresh,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 권장 설정 안내
          Card(
            elevation: 2,
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '권장 설정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 백그라운드 새로고침을 끄면 API 사용량을 크게 절약할 수 있습니다.\n'
                    '• 수동으로 당겨서 새로고침하는 것을 권장합니다.\n'
                    '• 하루 API 제한은 500 units로 설정되어 있습니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 캐시 정보
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '캐시 설정',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '현재 캐시 유지 기간:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 채널 검색: 30일\n'
                    '• 비디오 목록: 3일\n'
                    '• 채널 정보: 7일',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}