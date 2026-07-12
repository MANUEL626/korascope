import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class InterestDomain {
  final String id;
  final String name;
  final String description;

  const InterestDomain({
    required this.id,
    required this.name,
    required this.description,
  });

  factory InterestDomain.fromJson(Map<String, dynamic> json) => InterestDomain(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description']?.toString() ?? '',
  );
}

class UserProfile {
  final String id;
  final String? fullName;
  final String email;
  final String? profileUrl;
  final String accountType;
  final List<InterestDomain> interestDomains;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileUrl,
    required this.accountType,
    required this.interestDomains,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String?,
    email: json['email'] as String,
    profileUrl: json['profileUrl'] as String?,
    accountType: json['accountType']?.toString() ?? 'STANDARD',
    interestDomains: (json['interestDomains'] as List<dynamic>? ?? [])
        .map((item) => InterestDomain.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class AccountService extends ChangeNotifier {
  final ApiClient apiClient;

  UserProfile? profile;
  List<InterestDomain> availableDomains = const [];
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  AccountService({required this.apiClient});

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        apiClient.get('/utilisateurs/me'),
        apiClient.get('/interest-domains'),
      ]);
      profile = UserProfile.fromJson(responses[0] as Map<String, dynamic>);
      availableDomains = (responses[1] as List<dynamic>)
          .map((item) => InterestDomain.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (exception) {
      error = _message(exception);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    if (profile == null || fullName.trim().isEmpty) return false;
    return _save(() async {
      String? profileUrl;
      if (imageBytes != null && imageFilename != null) {
        profileUrl = await apiClient.uploadImage(
          bytes: imageBytes,
          filename: imageFilename,
        );
      }
      await apiClient.put(
        '/utilisateurs/${profile!.id}',
        body: {'fullName': fullName.trim(), 'profileUrl': profileUrl},
      );
      await _reloadProfile();
    });
  }

  Future<bool> toggleDomain(InterestDomain domain) async {
    if (profile == null) return false;
    final selected = profile!.interestDomains.any(
      (item) => item.id == domain.id,
    );
    return _save(() async {
      if (selected) {
        await apiClient.delete(
          '/utilisateurs/${profile!.id}/interest-domains/${domain.id}',
        );
        await _reloadProfile();
      } else {
        final data =
            await apiClient.post(
                  '/utilisateurs/${profile!.id}/interest-domains/${domain.id}',
                )
                as Map<String, dynamic>;
        profile = UserProfile.fromJson(data);
      }
    });
  }

  Future<void> _reloadProfile() async {
    final data =
        await apiClient.get('/utilisateurs/me') as Map<String, dynamic>;
    profile = UserProfile.fromJson(data);
  }

  Future<bool> _save(Future<void> Function() action) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (exception) {
      error = _message(exception);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Impossible de communiquer avec le serveur.';
}
