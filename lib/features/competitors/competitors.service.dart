import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/n8n_webhook.service.dart';
import '../../core/notifications/local_notification.service.dart';

class Competitor {
  final String id;
  final String name;
  final String website;
  final String sector;
  final String? description;
  final bool active;
  final int? priority;
  final String? github;
  final int score;
  final double growth;

  const Competitor({
    required this.id,
    required this.name,
    required this.website,
    required this.sector,
    this.description,
    this.active = true,
    this.priority,
    this.github,
    required this.score,
    required this.growth,
  });

  factory Competitor.fromJson(Map<String, dynamic> json) {
    final priority = (json['priority'] as num?)?.toInt();
    return Competitor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      sector: (json['category'] ?? json['sector'] ?? 'À analyser').toString(),
      description: _optionalText(json['description']),
      active: json['active'] as bool? ?? true,
      priority: priority,
      github: json['github']?.toString(),
      score: priority == null ? 70 : (100 - priority * 5).clamp(45, 98),
      growth: (json['growth'] as num?)?.toDouble() ?? 0,
    );
  }

  factory Competitor.fromWebhook(Map<String, dynamic> json) => Competitor(
    id: json['id']?.toString() ?? '',
    name: (json['name'] ?? json['companyName'] ?? json['nom'] ?? '').toString(),
    website: (json['website'] ?? json['site'] ?? json['url'] ?? '').toString(),
    sector: (json['sector'] ?? json['secteur'] ?? 'À analyser').toString(),
    description: _optionalText(json['description']),
    active: json['active'] as bool? ?? true,
    priority: (json['priority'] as num?)?.toInt(),
    github: json['github']?.toString(),
    score: (json['score'] as num?)?.toInt() ?? 0,
    growth: (json['growth'] as num?)?.toDouble() ?? 0,
  );

  Competitor copyWith({bool? active}) => Competitor(
    id: id,
    name: name,
    website: website,
    sector: sector,
    description: description,
    active: active ?? this.active,
    priority: priority,
    github: github,
    score: score,
    growth: growth,
  );

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class CompetitorsService extends ChangeNotifier {
  final ApiClient apiClient;
  final N8nWebhookService webhook;

  CompetitorsService({required this.apiClient})
    : webhook = N8nWebhookService(apiClient: apiClient);

  List<Competitor> _competitors = const [];
  bool isLoading = false;
  bool hasLoaded = false;
  String? error;

  List<Competitor> get competitors => List.unmodifiable(_competitors);

  int get activeCount => _competitors.where((item) => item.active).length;

  List<Competitor> search(String query) => _competitors
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList(growable: false);

  Future<void> loadForUser(String userId, {bool activeOnly = false}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data =
          await apiClient.get(
                '/competitor-companies/utilisateurs/$userId?activeOnly=$activeOnly',
              )
              as List<dynamic>;
      _competitors = data
          .map((item) => Competitor.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList(growable: false);
      hasLoaded = true;
    } catch (exception) {
      error = exception is ApiException
          ? exception.message
          : 'Impossible de récupérer les concurrents.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActive(Competitor competitor, bool active) async {
    final isCurrentlyActive = _competitors.any(
      (item) => item.id == competitor.id && item.active,
    );
    if (active && !isCurrentlyActive) {
      final limit = AppConfig.maxActiveCompetitors;
      if (activeCount >= limit) {
        error = 'Limite atteinte : maximum $limit concurrent(s) actif(s).';
        notifyListeners();
        return;
      }
    }
    final previous = _competitors;
    _competitors = [
      for (final item in _competitors)
        if (item.id == competitor.id) item.copyWith(active: active) else item,
    ];
    notifyListeners();
    try {
      final data =
          await apiClient.put(
                '/competitor-companies/${competitor.id}',
                body: {'active': active},
              )
              as Map<String, dynamic>;
      final updated = Competitor.fromJson(data);
      _competitors = [
        for (final item in _competitors)
          if (item.id == competitor.id) updated else item,
      ];
      error = null;
    } catch (exception) {
      _competitors = previous;
      error = exception is ApiException
          ? exception.message
          : 'Impossible de modifier le statut du concurrent.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> requestDiscovery({
    required String userId,
    required String email,
    required List<String> interests,
  }) async {
    final secretKey = webhook.apiClient.secretKey;
    if (secretKey == null || secretKey.isEmpty) {
      throw const ApiException(
        401,
        'Votre session est invalide. Veuillez vous reconnecter.',
      );
    }
    await webhook.send(
      action: 'search_new_competitor',
      payload: {
        'userId': userId,
        'email': email,
        'interests': interests,
        'secretKey': secretKey,
      },
    );
    await LocalNotificationService.instance
        .scheduleCompetitorSearchResultReminder();
  }
}
