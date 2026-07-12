import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const _fallbackApiBaseUrl = 'https://korascope.adaptimate.org';
  static const _fallbackApiPrefix = '/api/v1';
  static const _fallbackN8nWebhookUrl =
      'https://n8n.adaptimate.org/webhook-test/6be44d79-5a66-4289-b39f-d0592e575326';
  static const _fallbackMaxActiveCompetitors = 5;

  static String get apiBaseUrl => _env('API_BASE_URL') ?? _fallbackApiBaseUrl;

  static String get apiPrefix => _env('API_PREFIX') ?? _fallbackApiPrefix;

  static String get n8nWebhookUrl =>
      _env('N8N_WEBHOOK_URL') ?? _fallbackN8nWebhookUrl;

  static int get maxActiveCompetitors {
    final value = int.tryParse(_env('MAX_ACTIVE_COMPETITORS') ?? '');
    if (value == null || value <= 0) return _fallbackMaxActiveCompetitors;
    return value;
  }

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.maybeGet(key);
  }
}
