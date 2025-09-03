import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../core/interfaces/i_backend_service.dart';
import '../models/user.dart';
import '../models/video.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final IBackendService _backendService = serviceLocator<IBackendService>();
  
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rails API 연동 테스트',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // API 테스트 버튼들
            ElevatedButton(
              onPressed: _isLoading ? null : _testVideosAPI,
              child: const Text('영상 목록 가져오기'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignup,
              child: const Text('회원가입 테스트'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignin,
              child: const Text('로그인 테스트'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearResults,
              child: const Text('결과 지우기'),
            ),
            const SizedBox(height: 20),
            
            // 로딩 인디케이터
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // 결과 표시
            const Text(
              '결과:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'API 테스트 결과가 여기에 표시됩니다.' : _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testVideosAPI() async {
    setState(() {
      _isLoading = true;
      _result = '영상 목록을 가져오는 중...\n';
    });

    try {
      final videos = await _backendService.getFeed(page: 1, perPage: 10);
      setState(() {
        _result += '✅ 성공! ${videos.length}개의 영상을 받았습니다:\n\n';
        for (final video in videos.take(3)) {
          _result += '🎬 ${video.title}\n';
          _result += '   채널: ${video.channelTitle}\n';
          _result += '   ID: ${video.id}\n\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ 오류: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignup() async {
    setState(() {
      _isLoading = true;
      _result = '회원가입 테스트 중...\n';
    });

    try {
      final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@flutter.com';
      
      final response = await _backendService.signUp(
        name: 'Flutter 테스트 사용자',
        email: testEmail,
        password: 'password123',
        familyName: 'Flutter 테스트 가족',
      );
      
      setState(() {
        _result += '✅ 회원가입 성공!\n';
        _result += '이름: ${response.user.name}\n';
        _result += '이메일: ${response.user.email}\n';
        _result += '역할: ${response.user.role.name}\n';
        _result += '토큰: ${response.tokens.accessToken.substring(0, 30)}...\n\n';
      });
    } catch (e) {
      setState(() {
        _result += '❌ 회원가입 오류: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignin() async {
    setState(() {
      _isLoading = true;
      _result = '로그인 테스트 중...\n';
    });

    try {
      final response = await _backendService.signIn(
        email: 'parent@test.com',
        password: 'password123',
      );
      
      setState(() {
        _result += '✅ 로그인 성공!\n';
        _result += '이름: ${response.user.name}\n';
        _result += '이메일: ${response.user.email}\n';
        _result += '역할: ${response.user.role.name}\n';
        _result += '토큰: ${response.tokens.accessToken.substring(0, 30)}...\n\n';
      });
    } catch (e) {
      setState(() {
        _result += '❌ 로그인 오류: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _result = '';
    });
  }
}