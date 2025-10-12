import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:flutter/foundation.dart';

class EmailSender {
  // 🔹 Configure your Gmail sender info here
  static const String senderEmail = 'mamas.recipe0@gmail.com';
  static const String appPassword = 'gbsk ioml dham zgme';

  // 🔹 Send a payment notification to the dietitian
  static Future<void> sendPaymentNotification({
    required String toEmail,
    required String clientName,
    required String planType,
    required String planPrice,
    required String receiptUrl,
  }) async {
    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = Address(senderEmail, "Mama's Recipe")
      ..recipients.add(toEmail)
      ..subject = 'New Payment Received – $planType Plan'
      ..html = '''
        <h3>Hello Dietitian,</h3>
        <p><strong>$clientName</strong> has submitted a payment for the <strong>$planType</strong> plan.</p>
        <p>Plan Price: <strong>$planPrice</strong></p>
        <p>You can view their uploaded receipt here:</p>
        <p><a href="$receiptUrl">View Receipt Image</a></p>
        <p>Please verify the payment within <strong>24–48 hours</strong> in your Dashboard.</p>
        <br>
        <p>Best regards,<br>Mama's Recipe Team</p>
      ''';

    try {
      await send(message, smtpServer);
      debugPrint("✅ Email sent successfully to $toEmail");
    } catch (e) {
      debugPrint("❌ Failed to send email: $e");
    }
  }
}
