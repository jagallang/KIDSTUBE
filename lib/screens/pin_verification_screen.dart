import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class PinVerificationScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const PinVerificationScreen({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _pin = '';
  String? _errorMessage;
  int _attempts = 0;

  void _addDigit(String digit) {
    setState(() {
      if (_pin.length < 4) {
        _pin += digit;
        if (_pin.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _verifyPin() async {
    final isValid = await StorageService.verifyParentPin(_pin);
    
    if (isValid) {
      widget.onSuccess();
    } else {
      setState(() {
        _attempts++;
        _errorMessage = '잘못된 PIN입니다 (시도: $_attempts/3)';
        _pin = '';
      });
      
      if (_attempts >= 3) {
        setState(() {
          _errorMessage = '30초 후에 다시 시도해주세요';
        });
        
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _attempts = 0;
              _errorMessage = null;
            });
          }
        });
      }
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? Colors.red : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    final isLocked = _attempts >= 3;
    
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: [
        ...List.generate(9, (index) {
          final digit = (index + 1).toString();
          return _buildNumberButton(digit, !isLocked);
        }),
        const SizedBox(),
        _buildNumberButton('0', !isLocked),
        IconButton(
          onPressed: isLocked ? null : _removeDigit,
          icon: const Icon(Icons.backspace),
          iconSize: 30,
        ),
      ],
    );
  }

  Widget _buildNumberButton(String digit, bool enabled) {
    return InkWell(
      onTap: enabled ? () => _addDigit(digit) : null,
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부모 인증'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.lock,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'PIN을 입력해주세요',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 30),
            _buildPinDots(),
            const SizedBox(height: 50),
            Expanded(child: _buildNumberPad()),
          ],
        ),
      ),
    );
  }
}