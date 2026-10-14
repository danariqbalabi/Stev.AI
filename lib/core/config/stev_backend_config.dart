import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class StevBackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool isValid({
    String url = supabaseUrl,
    String publishableKey = supabasePublishableKey,
  }) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.hasAuthority &&
        publishableKey.trim().isNotEmpty;
  }

  static Future<SupabaseClient?> initialize() async {
    if (!isValid()) return null;

    try {
      final supabase = await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      return supabase.client;
    } catch (_) {
      // A missing or temporarily unavailable backend must never prevent the
      // user from opening the offline-first demo catalog.
      return null;
    }
  }
}
