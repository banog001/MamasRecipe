import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:flutter/foundation.dart';

class EmailOtpService {
  final String senderEmail;
  final String appPassword;

  String? _generatedOtp;
  DateTime? _otpSentTime;

  EmailOtpService({
    required this.senderEmail,
    required this.appPassword,
  });

  /// Generate and send OTP
  Future<void> sendOtpToEmail(String recipientEmail) async {
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    _otpSentTime = DateTime.now();

    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = Address(senderEmail, 'MamasRecipe App')
      ..recipients.add(recipientEmail)
      ..subject = 'Your OTP Code'
      ..text = 'Your OTP code is $_generatedOtp.\n\nIt expires in 5 minutes.';

    try {
      await send(message, smtpServer);
      debugPrint('✅ OTP sent successfully to $recipientEmail');
    } on MailerException catch (e) {
      debugPrint('❌ Failed to send OTP: $e');
      rethrow;
    }
  }

  /// Validate OTP entered by user
  bool verifyOtp(String enteredOtp) {
    if (_generatedOtp == null || _otpSentTime == null) return false;
    final now = DateTime.now();
    if (now.difference(_otpSentTime!).inMinutes >= 5) return false;
    return _generatedOtp == enteredOtp;
  }
}
