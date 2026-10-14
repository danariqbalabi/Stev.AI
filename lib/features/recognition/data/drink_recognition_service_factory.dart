import '../domain/drink_recognition.dart';
import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';
import 'demo_drink_recognition_service.dart';
import 'remote_drink_recognition_service.dart';

abstract final class DrinkRecognitionServiceFactory {
  static DrinkRecognitionService create({
    String endpoint = const String.fromEnvironment('STEV_RECOGNITION_ENDPOINT'),
    String token = const String.fromEnvironment('STEV_RECOGNITION_TOKEN'),
    String supabasePublishableKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    Iterable<Drink> catalog = DrinkCatalog.all,
  }) {
    final uri = Uri.tryParse(endpoint.trim());
    final isRemoteEndpoint =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isRemoteEndpoint) return const DemoDrinkRecognitionService();

    final isSupabaseFunction =
        uri.host.endsWith('.supabase.co') &&
        uri.path.startsWith('/functions/v1/');

    return RemoteDrinkRecognitionService(
      endpoint: uri,
      bearerToken: token.trim().isEmpty ? null : token.trim(),
      apiKey: isSupabaseFunction && supabasePublishableKey.trim().isNotEmpty
          ? supabasePublishableKey.trim()
          : null,
      catalog: catalog,
    );
  }
}
