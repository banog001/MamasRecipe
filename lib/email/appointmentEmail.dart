import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';

class Appointmentemail {
  // ⚠️ IMPORTANT: Store these securely (use environment variables or Firebase Remote Config)
  static const String smtpEmail = 'mamas.recipe0@gmail.com';
  static const String smtpPassword = 'gbsk ioml dham zgme'; // Use App Password for Gmail
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;

  /// ✅ Send appointment confirmation email
  Future<void> sendAppointmentEmail({
    required String clientName,
    required String clientEmail,
    required String dietitianName,
    required DateTime appointmentDate,
    required String notes,
  }) async {
    try {
      final smtpServerConfig = gmail(smtpEmail, smtpPassword);

      final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(appointmentDate);
      final formattedTime = DateFormat('h:mm a').format(appointmentDate);

      final message = Message()
        ..from = Address(smtpEmail, "Mama's Recipe")
        ..recipients.add(clientEmail)
        ..subject = 'Appointment Scheduled'
        ..text = '''
Hi $clientName,

$dietitianName has scheduled an appointment with you.

Date: $formattedDate
Time: $formattedTime

${notes.isNotEmpty ? 'Notes: $notes' : ''}

Thank you!
        ''';

      final sendReport = await send(message, smtpServerConfig);
      print('✅ Email sent successfully');
    } catch (e) {
      print('❌ Error sending email: $e');
      rethrow;
    }
  }
}