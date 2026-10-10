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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF75B7AD);
  static const Color primaryDark = Color(0xFF397F78);
  static const Color background = Color(0xFFF3F8F5);
  static const Color textColor = Color(0xFF253B39);
  static const Color muted = Color(0xFF82938F);
  static const Color borderColor = Color(0xFFE2ECE7);

  // PIN สำหรับทดสอบเท่านั้น
  static const String _correctPin = '1234';

  final TextEditingController _pinController =
      TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  String _pin = '';
  bool _isError = false;
  bool _isChecking = false;
  bool _obscurePin = true;

  bool get isThai =>
      widget.currentLocale.languageCode == 'th';

  String t(String th, String en) => isThai ? th : en;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_isChecking || _pin.length != 4) return;

    setState(() {
      _isChecking = true;
      _isError = false;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    if (_pin == _correctPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
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

      _pinFocus.requestFocus();
    }
  }

  void _changeLanguage() {
    widget.onLocaleChange(
      isThai ? const Locale('en') : const Locale('th'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal:
                    constraints.maxWidth < 380 ? 16 : 24,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1080 : 460,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 24),
                          if (isDesktop)
                            _buildDesktopLayout()
                          else
                            _buildMobileLayout(),
                        ],
                      ),
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

  // Top navigation
  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withValues(alpha: 0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: primaryDark,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'PHARMACY CARE',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _changeLanguage,
          icon: const Icon(
            Icons.language_rounded,
            size: 19,
          ),
          label: Text(t('English', 'ภาษาไทย')),
          style: TextButton.styleFrom(
            foregroundColor: primaryDark,
          ),
        ),
      ],
    );
  }

  // Desktop: two-column layout
  Widget _buildDesktopLayout() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F0E9),
                      Color(0xFFF5F8F4),
                    ],
                  ),
                ),
                child: _buildWelcome(),
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: _buildLoginCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile: centered layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildWelcome(compact: true),
        const SizedBox(height: 28),
        _buildLoginCard(),
      ],
    );
  }

  // Positive welcome section
  Widget _buildWelcome({bool compact = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 112 : 132,
          height: compact ? 112 : 132,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withValues(alpha: 0.13),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: compact ? 82 : 100,
                height: compact ? 82 : 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F4EE),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.health_and_safety_rounded,
                size: compact ? 65 : 76,
                color: primaryDark,
              ),
              Positioned(
                right: 13,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: primaryDark,
                    size: 23,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t(
            'ดูแลทุกวัน\nให้เป็นวันที่ดี',
            'Care Better,\nFeel Better.',
          ),
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: compact ? 29 : 38,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t(
            'เริ่มต้นวันดี ๆ ด้วยการดูแลที่ใส่ใจ\nใช้งานง่าย สบายตา และพร้อมช่วยคุณ',
            'A fresh start to your day.\nSimple tools for thoughtful care.',
          ),
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 14,
            height: 1.8,
            color: muted,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F2EB),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFD5E9DE),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                size: 18,
                color: primaryDark,
              ),
              const SizedBox(width: 8),
              Text(
                t(
                  'ทุกวันคือโอกาสในการดูแล',
                  'Every day is a fresh start',
                ),
                style: const TextStyle(
                  color: primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 30),
          _buildFeature(
            Icons.verified_user_outlined,
            t('เข้าใช้งานได้อย่างมั่นใจ', 'Secure staff access'),
          ),
          const SizedBox(height: 14),
          _buildFeature(
            Icons.medication_outlined,
            t('จัดการงานได้สะดวก', 'A simpler pharmacy workflow'),
          ),
          const SizedBox(height: 14),
          _buildFeature(
            Icons.devices_outlined,
            t('รองรับทุกขนาดหน้าจอ', 'Designed for every screen'),
          ),
        ],
      ],
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDCEFE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF49645F),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Login card
  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.045),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: primaryDark,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('ยินดีต้อนรับ', 'Welcome back'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('เข้าสู่ระบบเพื่อเริ่มต้น', 'Sign in to continue'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            t('รหัส PIN 4 หลัก', 'Your 4-digit PIN'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pinController,
            focusNode: _pinFocus,
            enabled: !_isChecking,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            obscureText: _obscurePin,
            maxLength: 4,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: primaryDark,
            ),
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: const TextStyle(
                color: Color(0xFFCBD9D5),
                letterSpacing: 12,
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F9F6),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePin
                    ? t('แสดงรหัส', 'Show PIN')
                    : t('ซ่อนรหัส', 'Hide PIN'),
                onPressed: () {
                  setState(() {
                    _obscurePin = !_obscurePin;
                  });
                },
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: muted,
                ),
              ),
              errorText: _isError
                  ? t(
                      'PIN ไม่ถูกต้อง กรุณาลองอีกครั้ง',
                      'Incorrect PIN. Please try again.',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: primary,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD86C6C),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD86C6C),
                  width: 1.5,
                ),
              ),
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
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _pin.length == 4 && !_isChecking
                  ? _verifyPin
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB9D8D0),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isChecking
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        key: const ValueKey('signin'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            t('เข้าสู่ระบบ', 'Sign In'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: primaryDark,
                size: 15,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  t(
                    'เริ่มต้นด้วยความใส่ใจ',
                    'A little care goes a long way',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}