import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'channel_management_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final String apiKey;

  const PinSetupScreen({Key? key, required this.apiKey}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _addDigit(String digit) {
    setState(() {
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            _isConfirming = true;
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _checkPins();
          }
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _checkPins() async {
    if (_pin == _confirmPin) {
      await StorageService.setParentPin(_pin);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChannelManagementScreen(apiKey: widget.apiKey),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'PIN이 일치하지 않습니다';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Widget _buildPinDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length ? Colors.red : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: [
        ...List.generate(9, (index) {
          final digit = (index + 1).toString();
          return _buildNumberButton(digit);
        }),
        const SizedBox(),
        _buildNumberButton('0'),
        IconButton(
          onPressed: _removeDigit,
          icon: const Icon(Icons.backspace),
          iconSize: 30,
        ),
      ],
    );
  }

  Widget _buildNumberButton(String digit) {
    return InkWell(
      onTap: () => _addDigit(digit),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isConfirming ? 'PIN 확인' : '부모 PIN 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              _isConfirming ? Icons.lock_open : Icons.lock_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isConfirming ? 'PIN을 다시 입력해주세요' : '4자리 PIN을 설정해주세요',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 30),
            _buildPinDots(_isConfirming ? _confirmPin : _pin),
            const SizedBox(height: 50),
            Expanded(child: _buildNumberPad()),
          ],
        ),
      ),
    );
  }
}