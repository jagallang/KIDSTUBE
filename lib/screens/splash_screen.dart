import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    print('🔑 API 키 확인 시작...');
    
    // 1. 저장된 API 키 우선 확인
    String? savedApiKey = await StorageService.getApiKey();
    String candidateApiKey;
    
    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      print('📁 저장된 API 키 발견: ${savedApiKey.substring(0, 8)}...');
      candidateApiKey = savedApiKey;
    } else {
      print('⚠️ 저장된 API 키가 없습니다. 기본 키로 시도합니다.');
      candidateApiKey = 'AIzaSyBZ6Hud9e-_fqIV2b4ufmn5qy2nqaRZiRs'; // 기본값 (유효하지 않음)
    }
    
    String finalApiKey = candidateApiKey;
    
    // 2. API 키 유효성 검증
    print('🔍 API 키 유효성 검사 중...');
    
    try {
      final youtubeService = YouTubeService(apiKey: candidateApiKey);
      final isValidApiKey = await youtubeService.validateApiKey();
      
      if (!isValidApiKey) {
        if (savedApiKey != null) {
          print('❌ 저장된 API 키가 유효하지 않습니다.');
        } else {
          print('❌ 기본 API 키가 유효하지 않습니다.');
        }
        print('💡 설정 > API 설정에서 유효한 API 키를 입력해주세요.');
        print('🔧 테스트 모드로 전환합니다.');
        finalApiKey = 'TEST_API_KEY';
      } else {
        print('✅ API 키 검증 성공!');
        finalApiKey = candidateApiKey;
      }
    } catch (e) {
      print('❌ API 키 검증 중 오류 발생: $e');
      print('💡 네트워크 오류로 인해 테스트 모드로 전환합니다.');
      finalApiKey = 'TEST_API_KEY';
    }
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(apiKey: finalApiKey)),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'KidsTube',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}