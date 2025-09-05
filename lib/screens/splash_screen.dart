import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import 'api_settings_screen.dart';

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
    String finalApiKey;
    
    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      print('📁 저장된 API 키 발견: ${savedApiKey.substring(0, 8)}...');
      finalApiKey = savedApiKey;
      
      // 2. API 키 유효성 검증 (로그만 출력, 실패해도 키는 그대로 사용)
      print('🔍 API 키 유효성 검사 중...');
      try {
        final youtubeService = YouTubeService(apiKey: savedApiKey);
        final isValidApiKey = await youtubeService.validateApiKey();
        
        if (isValidApiKey) {
          print('✅ API 키 검증 성공!');
        } else {
          print('⚠️ API 키 검증 실패 - API 할당량 초과나 네트워크 문제일 수 있습니다.');
          print('💡 저장된 API 키를 그대로 사용합니다.');
        }
      } catch (e) {
        print('⚠️ API 키 검증 중 오류: $e');
        print('💡 저장된 API 키를 그대로 사용합니다.');
      }
    } else {
      print('⚠️ 저장된 API 키가 없습니다.');
      print('💡 설정 > API 설정에서 유효한 API 키를 입력해주세요.');
      
      // API 키가 없으면 API 설정 화면으로 이동
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
      );
      return;
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