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
    
    // 테스트 모드일 때 자동으로 더미 채널 추가
    if (apiKey == 'TEST_API_KEY' && !isComplete) {
      await _addDummyChannels();
    }
    
    if (!mounted) return;
    
    if (apiKey == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ApiKeySetupScreen()),
      );
    } else if (!hasPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PinSetupScreen(apiKey: apiKey)),
      );
    } else if (!isComplete) {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen(apiKey: apiKey)),
      );
    }
  }
  
  Future<void> _addDummyChannels() async {
    final dummyChannels = [
      Channel(
        id: 'dummy_pororo',
        title: '뽀로로(Pororo)',
        thumbnail: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=P',
        subscriberCount: '1230000',
        uploadsPlaylistId: 'UUdummy_pororo',
      ),
      Channel(
        id: 'dummy_pinkfong',
        title: '핑크퐁(Pinkfong)',
        thumbnail: 'https://via.placeholder.com/150/FF69B4/FFFFFF?text=F',
        subscriberCount: '5670000',
        uploadsPlaylistId: 'UUdummy_pinkfong',
      ),
      Channel(
        id: 'dummy_tayo',
        title: '타요(Tayo)',
        thumbnail: 'https://via.placeholder.com/150/0066CC/FFFFFF?text=T',
        subscriberCount: '890000',
        uploadsPlaylistId: 'UUdummy_tayo',
      ),
      Channel(
        id: 'dummy_cocomong',
        title: '코코몽(Cocomong)',
        thumbnail: 'https://via.placeholder.com/150/00AA00/FFFFFF?text=C',
        subscriberCount: '450000',
        uploadsPlaylistId: 'UUdummy_cocomong',
      ),
      Channel(
        id: 'dummy_babybus',
        title: '베이비버스(BabyBus)',
        thumbnail: 'https://via.placeholder.com/150/FFD700/FFFFFF?text=B',
        subscriberCount: '2340000',
        uploadsPlaylistId: 'UUdummy_babybus',
      ),
    ];
    
    await StorageService.saveChannelsStatic(dummyChannels);
    await StorageService.setSetupComplete(true);
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