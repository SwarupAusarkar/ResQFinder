import 'package:flutter/material.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String? userType;
  final bool isLogin;
  final String formattedPhone;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.isLogin,
    required this.formattedPhone,
    this.userType,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController _otpController =
  TextEditingController();

  bool isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme:
        const IconThemeData(color: Color(0xFF00897B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
              MediaQuery.of(context).size.height - 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                /// Icon + Loader
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isVerifying)
                      const SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Color(0xFF00897B),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 40,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Title
                Text(
                  widget.isLogin
                      ? 'Login OTP'
                      : 'Verify Phone',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// Subtitle
                Text(
                  'Enter the 6-digit code sent to ${widget.formattedPhone}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                /// OTP Field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !isVerifying,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00897B),
                        width: 2,
                      ),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                    isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF00897B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isVerifying
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'VERIFY CODE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Cancel
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isVerifying
                          ? Colors.grey
                          : const Color(0xFF00897B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      if (widget.isLogin) {
        await _finalizePhoneLogin(
          widget.verificationId,
          _otpController.text.trim(),
        );
      } else {
        await _finalizeRegistration(
          widget.verificationId,
          _otpController.text.trim(),
          widget.userType!,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isVerifying = false);
      }
    }
  }

  Future<void> _finalizePhoneLogin(
      String verificationId, String otp) async {

  }

  Future<void> _finalizeRegistration(
      String verificationId,
      String otp,
      String userType) async {

  }
}