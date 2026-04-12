import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final bool isLogin;
  final String formattedPhone;
  
  // Registration data
  final String? userType;
  final String? email;
  final String? password;
  final String? fullName;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.isLogin,
    required this.formattedPhone,
    this.userType,
    this.email,
    this.password,
    this.fullName,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isVerifying = false;

  int _secondsLeft = 28;
  Timer? _timer;

  final List<TextEditingController> _digitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF0D4F4A);
  static const _bgColor = Color(0xFFF0F9F8);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    for (final c in _digitControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _composedOtp => _digitControllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _otpController.text = _composedOtp;
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.formattedPhone;
    final masked = phone.length > 6
        ? '${phone.substring(0, phone.length - 4)}••••${phone.substring(phone.length - 2)}'
        : phone;

    return Scaffold(
      backgroundColor: _bgColor,
      // FIX: Ensure scaffold resizes slightly but relies on the scroll view for overflow
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        // FIX: Replaced Padding/Column with CustomScrollView/SliverFillRemaining
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false, // This is the magic property that fixes the overflow!
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _tealDark),
                        onPressed: isVerifying ? null : () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const Spacer(flex: 2),

                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: _tealDark, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.medical_services_rounded, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 28),

                    const Text('Verify Your Number', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _tealDark)),
                    const SizedBox(height: 10),
                    Text(
                      "We've sent a 6-digit OTP to $masked",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                    ),

                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _digitControllers[i],
                        focusNode: _focusNodes[i],
                        index: i,
                        onChanged: (v) => _onDigitChanged(v, i),
                        filled: _digitControllers[i].text.isNotEmpty,
                      )),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Didn't receive OTP? ", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        _secondsLeft > 0
                            ? Text('Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.w600))
                            : GestureDetector(
                          onTap: () { setState(() => _secondsLeft = 28); _startTimer(); },
                          child: const Text('Resend', style: TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    _VerifyButton(isVerifying: isVerifying, onTap: _verifyOtp),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: isVerifying ? null : () => Navigator.pop(context),
                      child: const Text('Change Number', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ),

                    const Spacer(flex: 1),

                    _SecurityNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _composedOtp;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 6-digit code'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isVerifying = true);
    try {
      if (widget.isLogin) {
        await _finalizePhoneLogin(widget.verificationId, otp);
      } else {
        await _finalizeRegistration(widget.verificationId, otp);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  Future<void> _finalizePhoneLogin(String verificationId, String otp) async {
    await _authService.signInWithPhone(verificationId: verificationId, smsCode: otp);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _finalizeRegistration(String verificationId, String otp) async {
    await _authService.registerWithVerifiedPhone(
      email: widget.email!,
      password: widget.password!,
      verificationId: verificationId,
      smsCode: otp,
      fullName: widget.fullName!,
      userType: widget.userType!,
      phone: widget.formattedPhone,
    );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final void Function(String) onChanged;
  final bool filled;

  const _OtpBox({required this.controller, required this.focusNode, required this.index, required this.onChanged, required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44, height: 52,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFEFF6F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: filled ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0), width: filled ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: TextField(
        controller: controller, focusNode: focusNode, keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 1, onChanged: onChanged,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0D4F4A)),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool isVerifying;
  final VoidCallback onTap;
  const _VerifyButton({required this.isVerifying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isVerifying ? null : onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(color: const Color(0xFF0D4F4A), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))]),
        child: Center(
          child: isVerifying
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(mainAxisSize: MainAxisSize.min, children: [Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)), SizedBox(width: 8), Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18)]),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          const Expanded(child: Text('Your security is our priority. We use two-factor authentication to keep your medical data safe.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5))),
        ],
      ),
    );
  }
}