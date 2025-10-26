import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class rejectPayment {
  // SMTP settings for mobile/desktop
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _senderEmail = 'mamas.recipe0@gmail.com';
  static const String _senderPassword = 'gbsk ioml dham zgme';
  static const String _senderName = "Mama's Recipe Admin";

  // EmailJS settings for web
  static const String _emailJsServiceId = 'YOUR_SERVICE_ID';
  static const String _emailJsTemplateId = 'YOUR_TEMPLATE_ID';
  static const String _emailJsUserId = 'YOUR_USER_ID';

  static Future<void> sendPaymentRejectionEmail({
    required String dietitianEmail,
    required String dietitianName,
    required double amount,
    required String rejectionReason,
    required String adminName,
  }) async {
    try {
      if (kIsWeb) {
        // Use EmailJS for web
        await _sendViaEmailJS(
          dietitianEmail: dietitianEmail,
          dietitianName: dietitianName,
          amount: amount,
          rejectionReason: rejectionReason,
          adminName: adminName,
        );
      } else {
        // Use SMTP for mobile/desktop
        await _sendViaSMTP(
          dietitianEmail: dietitianEmail,
          dietitianName: dietitianName,
          amount: amount,
          rejectionReason: rejectionReason,
          adminName: adminName,
        );
      }
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  static Future<void> _sendViaSMTP({
    required String dietitianEmail,
    required String dietitianName,
    required double amount,
    required String rejectionReason,
    required String adminName,
  }) async {
    final smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      username: _senderEmail,
      password: _senderPassword,
      ignoreBadCertificate: false,
      ssl: false,
      allowInsecure: true,
    );

    final message = Message()
      ..from = Address(_senderEmail, _senderName)
      ..recipients.add(dietitianEmail)
      ..subject = 'Payment Rejected - Commission Payment'
      ..html = _buildEmailHtml(
        dietitianName: dietitianName,
        amount: amount,
        rejectionReason: rejectionReason,
        adminName: adminName,
      );

    final sendReport = await send(message, smtpServer);
    print('Email sent via SMTP: ${sendReport.toString()}');
  }

  static Future<void> _sendViaEmailJS({
    required String dietitianEmail,
    required String dietitianName,
    required double amount,
    required String rejectionReason,
    required String adminName,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: json.encode({
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsUserId,
        'template_params': {
          'to_email': dietitianEmail,
          'to_name': dietitianName,
          'from_name': _senderName,
          'admin_name': adminName,
          'amount': amount.toStringAsFixed(2),
          'rejection_reason': rejectionReason,
          'email_body': _buildEmailHtml(
            dietitianName: dietitianName,
            amount: amount,
            rejectionReason: rejectionReason,
            adminName: adminName,
          ),
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent via EmailJS successfully');
    } else {
      throw Exception('Failed to send email via EmailJS: ${response.body}');
    }
  }

  static String _buildEmailHtml({
    required String dietitianName,
    required double amount,
    required String rejectionReason,
    required String adminName,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Rejected</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <tr>
                        <td style="background-color: #dc3545; padding: 30px; text-align: center;">
                            <h1 style="margin: 0; color: #ffffff; font-size: 24px;">Payment Rejected</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="margin: 0 0 20px 0; color: #333333; font-size: 16px; line-height: 1.6;">
                                Dear <strong>$dietitianName</strong>,
                            </p>
                            <p style="margin: 0 0 20px 0; color: #333333; font-size: 16px; line-height: 1.6;">
                                We regret to inform you that your commission payment submission has been rejected.
                            </p>
                            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8f9fa; border-radius: 8px; margin: 20px 0;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p style="margin: 0 0 10px 0; color: #666666; font-size: 14px;">
                                            <strong>Payment Amount:</strong>
                                        </p>
                                        <p style="margin: 0 0 20px 0; color: #dc3545; font-size: 24px; font-weight: bold;">
                                            ₱${amount.toStringAsFixed(2)}
                                        </p>
                                        <p style="margin: 0 0 10px 0; color: #666666; font-size: 14px;">
                                            <strong>Reason for Rejection:</strong>
                                        </p>
                                        <p style="margin: 0; color: #333333; font-size: 14px; line-height: 1.6; padding: 15px; background-color: #ffffff; border-left: 4px solid #dc3545; border-radius: 4px;">
                                            $rejectionReason
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            <p style="margin: 20px 0; color: #333333; font-size: 16px; line-height: 1.6;">
                                <strong>Next Steps:</strong>
                            </p>
                            <ul style="margin: 0 0 20px 0; padding-left: 20px; color: #333333; font-size: 14px; line-height: 1.8;">
                                <li>Review the rejection reason carefully</li>
                                <li>Ensure your payment receipt meets all requirements</li>
                                <li>Submit a new payment with the corrected information</li>
                                <li>Contact support if you have any questions</li>
                            </ul>
                            <p style="margin: 20px 0 0 0; color: #666666; font-size: 14px; line-height: 1.6;">
                                If you believe this rejection was made in error or have any questions, please contact our support team.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #e9ecef;">
                            <p style="margin: 0 0 10px 0; color: #666666; font-size: 12px; line-height: 1.5;">
                                Reviewed by: <strong>$adminName</strong>
                            </p>
                            <p style="margin: 0; color: #999999; font-size: 12px; line-height: 1.5;">
                                This is an automated email from Mama's Recipe. Please do not reply to this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ''';
  }
}