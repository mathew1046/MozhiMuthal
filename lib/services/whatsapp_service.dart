import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with a pre-filled message.
class WhatsAppService {
  WhatsAppService._();

  /// Opens WhatsApp with a pre-filled message.
  /// [text] is the message body (e.g., referral summary).
  /// [phone] is an optional phone number (will be normalized to digits).
  static Future<bool> share({required String text, String? phone}) async {
    final encoded = Uri.encodeComponent(text);
    final normalized = phone?.replaceAll(RegExp(r'\D'), '');
    final url = normalized != null && normalized.isNotEmpty
        ? 'https://wa.me/$normalized?text=$encoded'
        : 'https://api.whatsapp.com/send?text=$encoded';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
