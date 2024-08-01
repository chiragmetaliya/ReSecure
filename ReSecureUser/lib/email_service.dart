import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  final String _apiKey = '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'; // Replace with your SendGrid API key

  Future<void> sendEmail(String toEmail, String subject, String body) async {
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [
              {'email': toEmail}
            ],
            'subject': subject,
          }
        ],
        'from': {
          'email': 'chiragmetaliya@gmail.com', // Replace with your SendGrid verified sender email
          'name': 'Your App Name',
        },
        'content': [
          {
            'type': 'text/plain',
            'value': body,
          }
        ],
      }),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}
