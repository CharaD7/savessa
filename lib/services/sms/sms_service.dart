import 'package:url_launcher/url_launcher.dart';

class SmsService {
  Future<bool> sendReminderSms({required String phoneNumber, required String message}) async {
    final uri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: {'body': message});
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
