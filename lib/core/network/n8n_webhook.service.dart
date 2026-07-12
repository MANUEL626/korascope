import '../config/app_config.dart';
import 'api_client.dart';

class N8nWebhookService {
  final ApiClient apiClient;

  const N8nWebhookService({required this.apiClient});

  Future<dynamic> send({
    required String action,
    Map<String, dynamic> payload = const {},
  }) {
    return apiClient.postExternal(
      AppConfig.n8nWebhookUrl,
      body: {...payload, 'action': action},
    );
  }
}
