import 'package:url_launcher/url_launcher.dart';

/// Shares referral PDF via WhatsApp deep link.
class WhatsAppService {
  WhatsAppService._();

  /// Opens WhatsApp with a pre-filled message.
  /// [text] is the message body (e.g., referral summary).
  static Future<bool> share({required String text, String? phone}) async {
    final encoded = Uri.encodeComponent(text);
    final url = phone != null
        ? 'https://wa.me/$phone?text=$encoded'
        : 'whatsapp://send?text=$encoded';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
