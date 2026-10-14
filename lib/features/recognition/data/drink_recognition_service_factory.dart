import '../domain/drink_recognition.dart';
import 'demo_drink_recognition_service.dart';
import 'remote_drink_recognition_service.dart';

abstract final class DrinkRecognitionServiceFactory {
  static DrinkRecognitionService create({
    String endpoint = const String.fromEnvironment('STEV_RECOGNITION_ENDPOINT'),
    String token = const String.fromEnvironment('STEV_RECOGNITION_TOKEN'),
  }) {
    final uri = Uri.tryParse(endpoint.trim());
    final isRemoteEndpoint =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isRemoteEndpoint) return const DemoDrinkRecognitionService();

    return RemoteDrinkRecognitionService(
      endpoint: uri,
      bearerToken: token.trim().isEmpty ? null : token.trim(),
    );
  }
}
