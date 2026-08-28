import 'package:supabase_flutter/supabase_flutter.dart';

class AppRemoteSettings {
  const AppRemoteSettings({
    required this.whatsappPhone,
    required this.callPhone,
    required this.email,
    required this.scheduleText,
    required this.termsUrl,
  });

  static const fallback = AppRemoteSettings(
    whatsappPhone: '89147371',
    callPhone: '89147371',
    email: 'info@autolab.lat',
    scheduleText: 'Lunes a viernes\n7:00 a. m. - 5:00 p. m.',
    termsUrl: 'https://www.autolab.lat/terminos-y-condiciones/',
  );

  final String whatsappPhone;
  final String callPhone;
  final String email;
  final String scheduleText;
  final String termsUrl;

  Uri get termsUri {
    final parsedUri = Uri.tryParse(termsUrl.trim());
    if (parsedUri == null || !parsedUri.hasScheme) {
      return Uri.parse(fallback.termsUrl);
    }

    return parsedUri;
  }

  static Future<AppRemoteSettings> load({SupabaseClient? client}) async {
    try {
      final supabaseClient = client ?? Supabase.instance.client;
      final response = await supabaseClient
          .from('support_contact_settings')
          .select('whatsapp_phone, call_phone, email, schedule_text, terms_url')
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return fallback;
      }

      return AppRemoteSettings.fromMap(Map<String, dynamic>.from(response));
    } catch (_) {
      return fallback;
    }
  }

  factory AppRemoteSettings.fromMap(Map<String, dynamic> map) {
    String valueOrFallback(String key, String fallbackValue) {
      final value = map[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallbackValue : value;
    }

    return AppRemoteSettings(
      whatsappPhone: valueOrFallback('whatsapp_phone', fallback.whatsappPhone),
      callPhone: valueOrFallback('call_phone', fallback.callPhone),
      email: valueOrFallback('email', fallback.email),
      scheduleText: valueOrFallback('schedule_text', fallback.scheduleText),
      termsUrl: valueOrFallback('terms_url', fallback.termsUrl),
    );
  }
}
