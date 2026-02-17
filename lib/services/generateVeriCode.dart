import 'dart:math';

class GenerateVerificationCode {
  String generateVerificationCode() {
    // Generates a 6-digit number between 100000 and 999999
    int code = 100000 + Random().nextInt(900000);
    return code.toString();
  }
}
