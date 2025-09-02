import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/storage_service.dart';
import 'api_key_setup_screen.dart';
import 'pin_setup_screen.dart';
import 'pin_verification_screen.dart';
import 'channel_management_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
    
    final apiKey = await StorageService.getApiKey();
    final hasPin = await StorageService.hasPin();
    final isComplete = await StorageService.isSetupComplete();
    
    if (!mounted) return;
    
    if (apiKey == null || apiKey.isEmpty) {
      // API 키가 없으면 설정 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ApiKeySetupScreen()),
      );
    } else if (!hasPin) {
      // PIN이 설정되지 않았으면 PIN 설정 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PinSetupScreen(apiKey: apiKey)),
      );
    } else if (!isComplete) {
      // 채널 설정이 완료되지 않았으면 PIN 확인 후 채널 관리 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PinVerificationScreen(
          onSuccess: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ChannelManagementScreen(apiKey: apiKey)),
            );
          },
        )),
      );
    } else {
      // 모든 설정이 완료되었으면 메인 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen(apiKey: apiKey)),
      );
    }
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