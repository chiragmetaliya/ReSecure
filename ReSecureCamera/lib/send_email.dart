import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String _username =
      'Elastic Email API User Name here'; // Replace with your Elastic Email API key
  static const String _password =
      'YOUR KEY'; // Replace with your Elastic Email API key

  Future<void> sendEmail(String toEmail, String subject, String body) async {
    final smtpServer = SmtpServer(
      'smtp.elasticemail.com',
      port: 2525,
      username: _username,
      password: _password,
    );

    final message = Message()
      ..from = const Address(_username, 'ReSecure')
      ..recipients.add(toEmail)
      ..subject = subject
      ..html = body;

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }
}
