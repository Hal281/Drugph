import 'package:flutter/material.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChange;

  const LoginScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  final String _correctPin = '1234'; // Dummy PIN for prototype
  bool _isError = false;
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  bool get isThai => widget.currentLocale.languageCode == 'th';

  void _verifyPin() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (_pin == _correctPin) {
          // Success: Navigate to Home Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                currentLocale: widget.currentLocale,
                onLocaleChange: widget.onLocaleChange,
              ),
            ),
          );
        } else {
          // Error: Show feedback and clear
          setState(() {
            _isError = true;
            _pin = '';
            _pinController.clear();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Logo & Titles)
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    isThai ? 'เข้าสู่ระบบ (สำหรับบุคลากร)' : 'Staff Login',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isThai
                        ? 'กรุณากรอกรหัส PIN 4 หลัก\n(รหัสทดสอบ: 1234)'
                        : 'Enter 4-digit PIN\n(Test PIN: 1234)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Standard PIN Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: TextField(
                      controller: _pinController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        errorText: _isError
                            ? (isThai ? 'รหัสไม่ถูกต้อง' : 'Invalid PIN')
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _pin = value;
                          _isError = false;
                        });
                        if (value.length == 4) {
                          _verifyPin();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
