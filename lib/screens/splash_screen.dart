import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'api_key_setup_screen.dart';
import 'pin_setup_screen.dart';
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
        MaterialPageRoute(builder: (_) => MainScreen(apiKey: apiKey)),
      );
    } else {
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