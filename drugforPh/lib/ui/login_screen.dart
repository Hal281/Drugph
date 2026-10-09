
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const Color primaryColor = Color(0xFF08A88A);
  static const Color darkGreen = Color(0xFF087F70);
  static const Color backgroundColor = Color(0xFFF5FAF9);
  static const Color textColor = Color(0xFF253C3A);

  final String _correctPin = '1234';
  final TextEditingController _pinController =
      TextEditingController();

  String _pin = '';
  bool _isError = false;
  bool _isChecking = false;
  bool _obscurePin = true;

  bool get isThai =>
      widget.currentLocale.languageCode == 'th';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_isChecking || _pin.length != 4) return;

    setState(() {
      _isChecking = true;
      _isError = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (_pin == _correctPin) {
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
        setState(() {
          _isChecking = false;
          _isError = true;
          _pin = '';
          _pinController.clear();
        });
      }
    });
  }

  void _changeLanguage() {
    widget.onLocaleChange(
      isThai ? const Locale('en') : const Locale('th'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Language selector
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _changeLanguage,
                            icon: const Icon(
                              Icons.language_rounded,
                              size: 19,
                            ),
                            label: Text(
                              isThai ? 'English' : 'ภาษาไทย',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: darkGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Medical logo
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(
                                      alpha: 0.09,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(
                                  Icons.local_hospital_rounded,
                                  color: primaryColor,
                                  size: 53,
                                ),
                                Positioned(
                                  right: 14,
                                  bottom: 17,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.medication_rounded,
                                      color: darkGreen,
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App title
                        Text(
                          isThai
                              ? 'ระบบบริการเภสัชกรรม'
                              : 'Pharmacy Service',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          isThai
                              ? 'ระบบสำหรับบุคลากรโรงพยาบาล'
                              : 'Hospital Staff Portal',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF718582),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Login card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE5F0ED),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF164E45)
                                    .withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 43,
                                    height: 43,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7F7F2),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.badge_outlined,
                                      color: darkGreen,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isThai
                                              ? 'เข้าสู่ระบบ'
                                              : 'Staff Login',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isThai
                                              ? 'สำหรับเจ้าหน้าที่'
                                              : 'Authorized personnel',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF82918F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 27),

                              Text(
                                isThai
                                    ? 'รหัส PIN 4 หลัก'
                                    : '4-digit PIN',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextField(
                                controller: _pinController,
                                autofocus: true,
                                enabled: !_isChecking,
                                keyboardType: TextInputType.number,
                                obscureText: _obscurePin,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                  color: darkGreen,
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFCBD8D5),
                                    letterSpacing: 12,
                                  ),
                                  counterText: '',
                                  filled: true,
                                  fillColor: backgroundColor,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePin
                                        ? (isThai
                                            ? 'แสดงรหัส'
                                            : 'Show PIN')
                                        : (isThai
                                            ? 'ซ่อนรหัส'
                                            : 'Hide PIN'),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePin = !_obscurePin;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePin
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF82918F),
                                      size: 21,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFDCEAE6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFDCEAE6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: primaryColor,
                                      width: 1.8,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  errorText: _isError
                                      ? (isThai
                                          ? 'รหัส PIN ไม่ถูกต้อง กรุณาลองอีกครั้ง'
                                          : 'Invalid PIN. Please try again.')
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
                                onSubmitted: (_) => _verifyPin(),
                              ),

                              const SizedBox(height: 20),

                              // Login button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _pin.length == 4 &&
                                              !_isChecking
                                          ? _verifyPin
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFFB8DDD3),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isChecking
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.lock_open_rounded,
                                              size: 19,
                                            ),
                                            const SizedBox(width: 9),
                                            Text(
                                              isThai
                                                  ? 'เข้าสู่ระบบ'
                                                  : 'Sign In',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: primaryColor,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      isThai
                                          ? 'สำหรับบุคลากรที่ได้รับอนุญาตเท่านั้น'
                                          : 'Authorized hospital staff only',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF82918F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_pharmacy_outlined,
                              size: 17,
                              color: darkGreen,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              isThai
                                  ? 'ระบบงานโรงพยาบาล'
                                  : 'Hospital Management System',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF718582),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
