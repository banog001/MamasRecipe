import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class declinedEmail {
  // SMTP Configuration - Replace with your actual credentials
  static const String _smtpUsername = 'mamas.recipe0@gmail.com';
  static const String _smtpPassword = 'gbsk ioml dham zgme';
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  /// Sends a decline notification email to the client
  static Future<bool> sendDeclineNotification({
    required String recipientEmail,
    required String clientName,
    required String dietitianName,
    required String planType,
    required String planPrice,
  }) async {
    try {
      // Configure SMTP server
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ignoreBadCertificate: false,
        ssl: false,
        allowInsecure: true,
      );

      // Create email message
      final message = Message()
        ..from = Address(_smtpUsername, "Mama's Recipe")
        ..recipients.add(recipientEmail)
        ..subject = "Subscription Request Update - Mama's Recipe"
        ..html = _buildDeclineEmailHtml(
          clientName: clientName,
          dietitianName: dietitianName,
          planType: planType,
          planPrice: planPrice,
        );

      // Send email
      final sendReport = await send(message, smtpServer);
      debugPrint('Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('Error sending decline email: $e');
      return false;
    }
  }

  /// Builds the HTML content for the decline notification email
  static String _buildDeclineEmailHtml({
    required String clientName,
    required String dietitianName,
    required String planType,
    required String planPrice,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Subscription Request Update</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #f44336 0%, #e53935 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .content {
            padding: 40px 30px;
            color: #333333;
            line-height: 1.6;
        }
        .greeting {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 20px;
            color: #212121;
        }
        .message {
            font-size: 15px;
            margin-bottom: 20px;
            color: #555555;
        }
        .info-box {
            background-color: #fff3f3;
            border-left: 4px solid #f44336;
            padding: 20px;
            margin: 25px 0;
            border-radius: 4px;
        }
        .info-box h3 {
            margin: 0 0 12px 0;
            font-size: 16px;
            color: #d32f2f;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #ffcdd2;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: 600;
            color: #666666;
        }
        .info-value {
            color: #212121;
        }
        .support-section {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 8px;
            margin-top: 25px;
        }
        .support-section h3 {
            margin: 0 0 10px 0;
            font-size: 16px;
            color: #212121;
        }
        .support-section p {
            margin: 0;
            color: #666666;
            font-size: 14px;
        }
        .footer {
            background-color: #f5f5f5;
            padding: 30px;
            text-align: center;
            color: #888888;
            font-size: 13px;
        }
        .footer p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Subscription Request Update</h1>
        </div>
        
        <div class="content">
            <div class="greeting">Dear $clientName,</div>
            
            <p class="message">
                Thank you for your interest in subscribing to <strong>$dietitianName</strong>'s nutrition services.
            </p>
            
            <p class="message">
                After careful review, we regret to inform you that your subscription request has been <strong>declined</strong> at this time.
            </p>
            
            <div class="info-box">
                <h3>Request Details</h3>
                <div class="info-row">
                    <span class="info-label">Dietitian:</span>
                    <span class="info-value">$dietitianName</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Plan Type:</span>
                    <span class="info-value">$planType</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Plan Price:</span>
                    <span class="info-value">$planPrice</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Status:</span>
                    <span class="info-value" style="color: #d32f2f; font-weight: 600;">Declined</span>
                </div>
            </div>
            
            <p class="message">
This decision may be due to various reasons such as current client capacity, service availability, specific program requirements, or concerns about documentation—for example, if a receipt appears altered, incomplete, or otherwise suspicious. We understand this may be disappointing and appreciate your understanding.            </p>
            
            <div class="support-section">
                <h3>Next Steps</h3>
                <p>
                    You may contact the dietitian directly for more information or explore other available nutrition professionals on our platform who may better suit your needs.
                </p>
            </div>
            
            <p class="message" style="margin-top: 25px;">
                If you have any questions or need assistance finding alternative services, please don't hesitate to reach out to our support team.
            </p>
            
            <p class="message">
                Thank you for choosing Mama's Recipe.
            </p>
            
            <p style="margin-top: 30px; color: #666666;">
                Best regards,<br>
                <strong>The Mama's Recipe Team</strong>
            </p>
        </div>
        
        <div class="footer">
            <p><strong>Mama's Recipe Nutrition Services</strong></p>
            <p>This is an automated message. Please do not reply directly to this email.</p>
            <p>&copy; 2025 Mama's Recipe. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Alternative method: Send plain text email (fallback)
  static Future<bool> sendDeclineNotificationPlainText({
    required String recipientEmail,
    required String clientName,
    required String dietitianName,
    required String planType,
    required String planPrice,
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ignoreBadCertificate: false,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, 'NutriPlan Subscription')
        ..recipients.add(recipientEmail)
        ..subject = 'Subscription Request Update - NutriPlan'
        ..text = '''
Dear $clientName,

Thank you for your interest in subscribing to $dietitianName's nutrition services.

After careful review, we regret to inform you that your subscription request has been DECLINED at this time.

REQUEST DETAILS:
- Dietitian: $dietitianName
- Plan Type: $planType
- Plan Price: $planPrice
- Status: Declined

This decision may be due to various reasons such as current client capacity, service availability, or specific program requirements. We understand this may be disappointing, and we appreciate your understanding.

NEXT STEPS:
You may contact the dietitian directly for more information or explore other available nutrition professionals on our platform who may better suit your needs.

If you have any questions or need assistance finding alternative services, please don't hesitate to reach out to our support team.

Thank you for choosing NutriPlan.

Best regards,
The NutriPlan Team

---
This is an automated message. Please do not reply directly to this email.
© 2025 NutriPlan. All rights reserved.
        ''';

      final sendReport = await send(message, smtpServer);
      debugPrint('Plain text email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('Error sending plain text decline email: $e');
      return false;
    }
  }
}